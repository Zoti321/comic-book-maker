use std::path::PathBuf;
use std::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

use once_cell::sync::OnceCell;
use rusqlite::Connection;

use crate::paths::{library_db_path, projects_root};

use super::migrate;
use super::schema;

static LIBRARY: OnceCell<Mutex<Library>> = OnceCell::new();

pub struct Library {
    pub(crate) app_data_dir: PathBuf,
    pub(crate) connection: Connection,
}

impl Library {
    pub fn open(app_data_dir: PathBuf) -> Result<Self, String> {
        std::fs::create_dir_all(&app_data_dir)
            .map_err(|error| format!("create app data dir: {error}"))?;
        std::fs::create_dir_all(projects_root(&app_data_dir))
            .map_err(|error| format!("create projects dir: {error}"))?;

        let db_path = library_db_path(&app_data_dir);
        let connection =
            Connection::open(&db_path).map_err(|error| format!("open library db: {error}"))?;
        connection
            .execute_batch(schema::SCHEMA)
            .map_err(|error| format!("migrate library db: {error}"))?;
        migrate::migrate(&connection).map_err(|error| format!("migrate schema: {error}"))?;

        Ok(Self {
            app_data_dir,
            connection,
        })
    }

    pub fn install(app_data_dir: PathBuf) -> Result<(), String> {
        if let Some(mutex) = LIBRARY.get() {
            let library = mutex
                .lock()
                .map_err(|_| "library lock poisoned".to_string())?;
            if library.app_data_dir == app_data_dir {
                return Ok(());
            }
            return Err(format!(
                "library already initialized at {}",
                library.app_data_dir.display()
            ));
        }

        let library = Self::open(app_data_dir)?;
        LIBRARY
            .set(Mutex::new(library))
            .map_err(|_| "library already initialized".to_string())
    }

    pub(crate) fn with_library<T>(
        operation: impl FnOnce(&mut Library) -> Result<T, String>,
    ) -> Result<T, String> {
        let mutex = LIBRARY.get().ok_or("library not initialized".to_string())?;
        let mut library = mutex
            .lock()
            .map_err(|_| "library lock poisoned".to_string())?;
        operation(&mut library)
    }

    pub(crate) fn with_library_export(
        operation: impl FnOnce(&mut Library) -> Result<(), crate::export_error::ExportError>,
    ) -> Result<(), crate::export_error::ExportError> {
        use crate::export_error::{ExportError, ExportErrorKind};

        let mutex = LIBRARY.get().ok_or(ExportError::new(
            ExportErrorKind::ArchiveWriteFailed,
            "library not initialized",
        ))?;
        let mut library = mutex
            .lock()
            .map_err(|_| ExportError::new(
                ExportErrorKind::ArchiveWriteFailed,
                "library lock poisoned",
            ))?;
        operation(&mut library)
    }

    pub(crate) fn app_data_dir(&self) -> &PathBuf {
        &self.app_data_dir
    }
}

pub(crate) fn now_ms() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as i64)
        .unwrap_or(0)
}
