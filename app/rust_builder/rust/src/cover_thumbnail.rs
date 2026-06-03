//! Cover Thumbnail generation — cached preview of the cover page in `.cache/`.

use std::path::{Path, PathBuf};

pub const COVER_THUMBNAIL_FILE: &str = "cover.webp";
const MAX_EDGE_PX: u32 = 400;

pub fn cover_thumbnail_path(cache_dir: &Path) -> PathBuf {
    cache_dir.join(COVER_THUMBNAIL_FILE)
}

pub fn generate_cover_thumbnail(source: &Path, destination: &Path) -> Result<(), String> {
    if !source.is_file() {
        return Err(format!("cover source not found: {}", source.display()));
    }

    let image = image::open(source).map_err(|error| format!("open cover image: {error}"))?;
    let thumbnail = image.thumbnail(MAX_EDGE_PX, MAX_EDGE_PX);

    if let Some(parent) = destination.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|error| format!("create cache dir: {error}"))?;
    }

    thumbnail
        .save(destination)
        .map_err(|error| format!("write cover thumbnail: {error}"))?;

    Ok(())
}

pub fn remove_cover_thumbnail(cache_dir: &Path) -> Result<(), String> {
    let path = cover_thumbnail_path(cache_dir);
    if path.is_file() {
        std::fs::remove_file(&path)
            .map_err(|error| format!("remove cover thumbnail: {error}"))?;
    }
    Ok(())
}

pub fn cover_thumbnail_absolute_path(storage_dir: &Path) -> Option<String> {
    let path = cover_thumbnail_path(&crate::paths::project_cache_dir(storage_dir));
    if path.is_file() {
        Some(path.to_string_lossy().into_owned())
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, Rgba};
    use uuid::Uuid;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-cover-{name}-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn write_test_png(path: &Path, width: u32, height: u32) {
        let img = ImageBuffer::from_fn(width, height, |_, _| Rgba([40u8, 120, 200, 255]));
        img.save(path).expect("save test png");
    }

    #[test]
    fn generates_resized_webp_thumbnail() {
        let dir = temp_dir("gen");
        let source = dir.join("page.png");
        let dest = dir.join("cover.webp");
        write_test_png(&source, 800, 1200);

        generate_cover_thumbnail(&source, &dest).expect("generate thumbnail");

        assert!(dest.is_file());
        let thumb = image::open(&dest).expect("open thumbnail");
        assert!(thumb.width() <= MAX_EDGE_PX);
        assert!(thumb.height() <= MAX_EDGE_PX);
    }
}
