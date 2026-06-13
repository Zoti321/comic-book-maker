use std::path::PathBuf;

use image::{ImageBuffer, Rgba};
use uuid::Uuid;

use crate::cover_thumbnail::COVER_THUMBNAIL_FILE;
use crate::paths::{project_assets_dir, project_cache_dir, project_storage_dir};
use crate::project_format::{ExportFormat, InferredImportKind};
use crate::project_workflow::ComicArchiveContainer;
use crate::db::records::ProjectSettingsPatch;

use super::metadata::MetadataRecord;
use super::library::Library;
use super::schema;

fn temp_dir(name: &str) -> PathBuf {
    let dir = std::env::temp_dir().join(format!("cbm-test-{name}-{}", Uuid::new_v4()));
    std::fs::create_dir_all(&dir).expect("create temp dir");
    dir
}

fn write_test_png(dir: &PathBuf, name: &str) -> PathBuf {
    let path = dir.join(name);
    let img = ImageBuffer::from_fn(32, 48, |_, _| Rgba([80u8, 140, 220, 255]));
    img.save(&path).expect("save test png");
    path
}

#[test]
fn create_and_list_projects() {
    let app_data = temp_dir("library");
    let mut library = Library::open(app_data.clone()).expect("open library");

    let created = library.create_project_inner(None).expect("create project");
    assert_eq!(created.title, schema::DEFAULT_PROJECT_TITLE);

    let storage = project_storage_dir(&app_data, &created.id);
    assert!(project_assets_dir(&storage).is_dir());
    assert!(project_cache_dir(&storage).is_dir());

    let projects = library.list_projects_inner().expect("list projects");
    assert_eq!(projects.len(), 1);
    assert_eq!(projects[0].id, created.id);
}

#[test]
fn project_settings_defaults_and_export_format_update() {
    let app_data = temp_dir("settings");
    let mut library = Library::open(app_data).expect("open library");

    let project = library.create_project_inner(None).expect("create");
    let settings = library
        .get_project_settings_inner(&project.id)
        .expect("load settings");
    assert_eq!(settings.export_format, ExportFormat::ComicArchive);
    assert_eq!(settings.inferred_import_kind, InferredImportKind::Images);
    assert!(!settings.delete_project_after_export);
    assert!(settings.use_default_export_directory);
    assert_eq!(settings.export_directory, None);
    assert_eq!(settings.comic_archive_container, ComicArchiveContainer::Zip);
    assert!(settings.use_comic_archive_extension);

    let updated = library
        .update_project_export_format_inner(&project.id, ExportFormat::Epub)
        .expect("update export format");
    assert_eq!(updated.export_format, ExportFormat::Epub);
    assert_eq!(updated.inferred_import_kind, InferredImportKind::Images);

    let reloaded = library
        .get_project_settings_inner(&project.id)
        .expect("reload settings");
    assert_eq!(reloaded.export_format, ExportFormat::Epub);
}

#[test]
fn project_workflow_settings_round_trip() {
    let app_data = temp_dir("workflow-settings");
    let mut library = Library::open(app_data).expect("open library");
    let project = library.create_project_inner(None).expect("create");

    let updated = library
        .update_project_settings_inner(
            &project.id,
            ProjectSettingsPatch {
                export_format: ExportFormat::ComicArchive,
                delete_project_after_export: true,
                use_default_export_directory: false,
                export_directory: Some("D:\\exports\\comics".to_string()),
                comic_archive_container: ComicArchiveContainer::Rar,
                use_comic_archive_extension: false,
            },
        )
        .expect("update settings");

    assert!(updated.delete_project_after_export);
    assert!(!updated.use_default_export_directory);
    assert_eq!(
        updated.export_directory.as_deref(),
        Some("D:\\exports\\comics")
    );
    assert_eq!(updated.comic_archive_container, ComicArchiveContainer::Rar);
    assert!(!updated.use_comic_archive_extension);

    let reloaded = library
        .get_project_settings_inner(&project.id)
        .expect("reload");
    assert_eq!(reloaded, updated);
}

#[test]
fn import_project_sets_inferred_kind_and_export_format() {
    let app_data = temp_dir("import-settings");
    let mut library = Library::open(app_data).expect("open library");

    let project = library
        .create_project_for_import(
            "Imported".to_string(),
            InferredImportKind::Epub,
            ExportFormat::Epub,
        )
        .expect("create for import");

    let settings = library
        .get_project_settings_inner(&project.id)
        .expect("settings");
    assert_eq!(settings.inferred_import_kind, InferredImportKind::Epub);
    assert_eq!(settings.export_format, ExportFormat::Epub);
}

#[test]
fn change_inferred_import_kind_clears_pages_and_resets_metadata() {
    let app_data = temp_dir("import-kind-reset");
    let fixtures = temp_dir("import-kind-fixtures");
    let mut library = Library::open(app_data).expect("open library");

    let png = write_test_png(&fixtures, "page.png");
    let project = library
        .create_project_inner(Some("保留标题".to_string()))
        .expect("create");
    library
        .add_page_images_inner(&project.id, vec![png.to_string_lossy().to_string()])
        .expect("add page");

    library
        .update_project_metadata_inner(
            &project.id,
            MetadataRecord {
                title: "保留标题".to_string(),
                series: Some("系列名".to_string()),
                cover_page_index: 0,
                page_count: 1,
                ..MetadataRecord::default()
            },
        )
        .expect("metadata");

    assert_eq!(library.page_count(&project.id).expect("count"), 1);

    let updated = library
        .change_inferred_import_kind_inner(&project.id, InferredImportKind::Epub)
        .expect("change kind");

    assert_eq!(updated.inferred_import_kind, InferredImportKind::Epub);
    assert_eq!(library.page_count(&project.id).expect("count after"), 0);
    assert!(library.list_pages_inner(&project.id).expect("list").is_empty());

    let metadata = library
        .get_project_metadata_inner(&project.id)
        .expect("metadata");
    assert_eq!(metadata.title, "保留标题");
    assert_eq!(metadata.series, None);
    assert_eq!(metadata.page_count, 0);
}

#[test]
fn install_is_idempotent_for_same_app_data_dir() {
    let app_data = temp_dir("install-twice");
    Library::install(app_data.clone()).expect("first install");
    Library::install(app_data).expect("second install should no-op");
}

#[test]
fn list_projects_returns_sort_fields_in_created_at_order() {
    let app_data = temp_dir("recent");
    let mut library = Library::open(app_data).expect("open library");

    let first = library
        .create_project_inner(Some("First".to_string()))
        .expect("create first");
    std::thread::sleep(std::time::Duration::from_millis(5));
    let second = library
        .create_project_inner(Some("Second".to_string()))
        .expect("create second");

    let listed = library.list_projects_inner().expect("list");
    assert_eq!(listed.len(), 2);
    assert_eq!(listed[0].id, first.id);
    assert_eq!(listed[1].id, second.id);
    assert!(listed[0].created_at_ms <= listed[1].created_at_ms);
    assert_eq!(listed[0].last_opened_at_ms, None);

    library
        .touch_project_inner(&first.id)
        .expect("touch first");

    let after_touch = library.list_projects_inner().expect("list after touch");
    assert_eq!(after_touch[0].id, first.id);
    assert!(after_touch[0].last_opened_at_ms.is_some());
}

#[test]
fn add_and_list_page_images() {
    let app_data = temp_dir("pages");
    let mut library = Library::open(app_data.clone()).expect("open library");

    let project = library.create_project_inner(None).expect("create project");
    let fixtures = temp_dir("fixtures");
    let first = write_test_png(&fixtures, "one.png");
    let second = write_test_png(&fixtures, "two.png");

    let added = library
        .add_page_images_inner(
            &project.id,
            vec![
                first.to_string_lossy().into_owned(),
                second.to_string_lossy().into_owned(),
            ],
        )
        .expect("add pages");

    assert_eq!(added.len(), 2);
    assert_eq!(added[0].sort_index, 0);
    assert_eq!(added[1].sort_index, 1);
    assert!(PathBuf::from(&added[0].absolute_path).is_file());

    let pages = library.list_pages_inner(&project.id).expect("list pages");
    assert_eq!(pages.len(), 2);
    assert_eq!(pages[0].asset_path, added[0].asset_path);
}

#[test]
fn rejects_unsupported_page_image_format() {
    let app_data = temp_dir("reject");
    let mut library = Library::open(app_data).expect("open library");
    let project = library.create_project_inner(None).expect("create project");
    let fixtures = temp_dir("reject-fixtures");
    let invalid = fixtures.join("bad.tiff");
    std::fs::write(&invalid, b"fake-image").expect("write invalid");

    let error = library
        .add_page_images_inner(&project.id, vec![invalid.to_string_lossy().into_owned()])
        .expect_err("unsupported format");

    assert!(error.contains("unsupported image format"));
}

#[test]
fn delete_replace_and_reorder_pages() {
    let app_data = temp_dir("page-ops");
    let mut library = Library::open(app_data.clone()).expect("open library");
    let project = library.create_project_inner(None).expect("create project");
    let fixtures = temp_dir("page-ops-fixtures");
    let first = write_test_png(&fixtures, "one.png");
    let second = write_test_png(&fixtures, "two.png");
    let third = write_test_png(&fixtures, "three.png");

    let added = library
        .add_page_images_inner(
            &project.id,
            vec![
                first.to_string_lossy().into_owned(),
                second.to_string_lossy().into_owned(),
                third.to_string_lossy().into_owned(),
            ],
        )
        .expect("add pages");

    library
        .delete_page_inner(&project.id, &added[1].id)
        .expect("delete page");
    let after_delete = library
        .list_pages_inner(&project.id)
        .expect("list after delete");
    assert_eq!(after_delete.len(), 2);
    assert_eq!(after_delete[0].sort_index, 0);
    assert_eq!(after_delete[1].sort_index, 1);
    assert!(!PathBuf::from(&added[1].absolute_path).exists());

    let replacement = write_test_png(&fixtures, "replacement.png");
    let replaced = library
        .replace_page_image_inner(
            &project.id,
            &after_delete[0].id,
            replacement.to_string_lossy().into_owned(),
        )
        .expect("replace page");
    assert!(PathBuf::from(&replaced.absolute_path).is_file());

    let remaining = library
        .list_pages_inner(&project.id)
        .expect("list before reorder");
    let reordered = library
        .reorder_pages_inner(
            &project.id,
            vec![remaining[1].id.clone(), remaining[0].id.clone()],
        )
        .expect("reorder pages");
    assert_eq!(reordered[0].id, remaining[1].id);
    assert_eq!(reordered[0].sort_index, 0);
    assert_eq!(reordered[1].sort_index, 1);

    let reloaded = library.list_pages_inner(&project.id).expect("reload pages");
    assert_eq!(reloaded[0].id, remaining[1].id);
}

#[test]
fn get_and_update_project_metadata() {
    let app_data = temp_dir("metadata");
    let mut library = Library::open(app_data).expect("open library");
    let project = library.create_project_inner(None).expect("create project");

    let loaded = library
        .get_project_metadata_inner(&project.id)
        .expect("get metadata");
    assert_eq!(loaded.title, schema::DEFAULT_PROJECT_TITLE);
    assert_eq!(loaded.cover_page_index, 0);
    assert_eq!(loaded.page_count, 0);

    let updated = MetadataRecord {
        title: "My Comic".to_string(),
        series: Some("Adventures".to_string()),
        number: Some("1".to_string()),
        author: Some("Alice".to_string()),
        language_iso: Some("zh-CN".to_string()),
        published_date: Some("2025".to_string()),
        ..Default::default()
    };

    let saved = library
        .update_project_metadata_inner(&project.id, updated)
        .expect("update metadata");
    assert_eq!(saved.title, "My Comic");
    assert_eq!(saved.series.as_deref(), Some("Adventures"));

    let reloaded = library
        .get_project_metadata_inner(&project.id)
        .expect("reload metadata");
    assert_eq!(reloaded.title, "My Comic");
    assert_eq!(reloaded.author.as_deref(), Some("Alice"));
}

#[test]
fn cover_thumbnail_generated_and_updates_with_cover_page() {
    let app_data = temp_dir("cover-thumb");
    let mut library = Library::open(app_data.clone()).expect("open library");
    let project = library.create_project_inner(None).expect("create project");
    let fixtures = temp_dir("cover-fixtures");
    let first = write_test_png(&fixtures, "one.png");
    let second = write_test_png(&fixtures, "two.png");

    library
        .add_page_images_inner(
            &project.id,
            vec![
                first.to_string_lossy().into_owned(),
                second.to_string_lossy().into_owned(),
            ],
        )
        .expect("add pages");

    let storage = project_storage_dir(&app_data, &project.id);
    let thumb_path = project_cache_dir(&storage).join(COVER_THUMBNAIL_FILE);
    assert!(thumb_path.is_file(), "cover thumbnail should exist");

    let projects = library.list_projects_inner().expect("list projects");
    assert_eq!(
        projects[0].cover_thumbnail_path.as_deref(),
        Some(thumb_path.to_str().expect("utf8 path"))
    );

    let mut metadata = library
        .get_project_metadata_inner(&project.id)
        .expect("get metadata");
    metadata.cover_page_index = 1;
    library
        .update_project_metadata_inner(&project.id, metadata)
        .expect("set cover to page 2");

    assert!(thumb_path.is_file());
    let after_meta = image::open(&thumb_path).expect("open thumb after cover change");
    assert!(after_meta.width() > 0);

    library
        .delete_page_inner(
            &project.id,
            &library.list_pages_inner(&project.id).expect("pages")[1].id,
        )
        .expect("delete cover page");
    library
        .delete_page_inner(
            &project.id,
            &library.list_pages_inner(&project.id).expect("pages")[0].id,
        )
        .expect("delete last page");

    assert!(!thumb_path.exists(), "thumbnail removed when no pages");

    let projects = library.list_projects_inner().expect("list after delete");
    assert!(projects[0].cover_thumbnail_path.is_none());
}

#[test]
fn delete_project_removes_database_row_and_storage() {
    let app_data = temp_dir("delete-project");
    let mut library = Library::open(app_data.clone()).expect("open library");
    let fixtures = temp_dir("delete-fixtures");
    let png = write_test_png(&fixtures, "page.png");

    let project = library.create_project_inner(None).expect("create project");
    library
        .add_page_images_inner(
            &project.id,
            vec![png.to_string_lossy().into_owned()],
        )
        .expect("add page");

    let storage = project_storage_dir(&app_data, &project.id);
    assert!(storage.is_dir());

    library
        .delete_project_inner(&project.id)
        .expect("delete project");

    assert!(!storage.exists());
    assert!(!library.project_exists(&project.id).expect("exists check"));

    let projects = library.list_projects_inner().expect("list");
    assert!(projects.is_empty());
}

#[test]
fn export_cbz_deletes_project_when_requested() {
    let app_data = temp_dir("export-delete");
    let mut library = Library::open(app_data.clone()).expect("open library");

    let project = library
        .create_project_inner(None)
        .expect("create project");
    let fixtures = temp_dir("export-delete-fixtures");
    let png = write_test_png(&fixtures, "page.png");
    library
        .add_page_images_inner(&project.id, vec![png.to_string_lossy().into_owned()])
        .expect("add page");

    let storage = project_storage_dir(&app_data, &project.id);
    let export_path = temp_dir("export-delete-out").join("out.cbz");

    crate::export_cbz::export_cbz(&library, &project.id, &export_path.to_string_lossy())
        .expect("export");
    library
        .delete_project_inner(&project.id)
        .expect("delete after export");

    assert!(export_path.is_file());
    assert!(!storage.exists());
    assert!(library.list_projects_inner().expect("list").is_empty());
}

#[test]
fn export_pdf_deletes_project_when_requested() {
    let app_data = temp_dir("export-pdf-delete");
    let mut library = Library::open(app_data.clone()).expect("open library");

    let project = library
        .create_project_inner(None)
        .expect("create project");
    let fixtures = temp_dir("export-pdf-delete-fixtures");
    let png = write_test_png(&fixtures, "page.png");
    library
        .add_page_images_inner(&project.id, vec![png.to_string_lossy().into_owned()])
        .expect("add page");

    let storage = project_storage_dir(&app_data, &project.id);
    let export_path = temp_dir("export-pdf-delete-out").join("out.pdf");

    crate::export_pdf::export_pdf(&library, &project.id, &export_path.to_string_lossy())
        .expect("export");
    library
        .delete_project_inner(&project.id)
        .expect("delete after export");

    assert!(export_path.is_file());
    assert!(!storage.exists());
    assert!(library.list_projects_inner().expect("list").is_empty());
}

#[test]
fn abandon_import_project_removes_partial_disk_and_db_row() {
    let app_data = temp_dir("abandon-import");
    let mut library = Library::open(app_data.clone()).expect("open library");
    let fixtures = temp_dir("abandon-fixtures");
    let png = write_test_png(&fixtures, "page.png");

    let project = library
        .create_project_for_import(
            "Abandon Me".to_string(),
            InferredImportKind::Images,
            ExportFormat::ComicArchive,
        )
        .expect("create import project");
    let storage = project_storage_dir(&app_data, &project.id);

    crate::import_shared::stage_pages_from_files(
        &app_data,
        &project.id,
        &[png],
        0,
    )
    .expect("stage pages");

    assert!(
        library
            .list_pages_inner(&project.id)
            .expect("list pages")
            .is_empty(),
        "pages not committed yet"
    );
    assert!(project_assets_dir(&storage).read_dir().unwrap().count() > 0);

    library
        .abandon_import_project(&project.id)
        .expect("abandon import");

    assert!(!storage.exists());
    assert!(!library.project_exists(&project.id).expect("exists"));
}

#[test]
fn delete_project_errors_when_missing() {
    let app_data = temp_dir("delete-missing");
    let mut library = Library::open(app_data).expect("open library");

    let error = library
        .delete_project_inner("missing-id")
        .expect_err("missing project");
    assert!(error.contains("project not found"));
}
