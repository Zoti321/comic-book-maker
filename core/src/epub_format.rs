//! EPUB container / OPF helpers shared by import and export.

use std::collections::HashMap;
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

use quick_xml::events::Event;
use quick_xml::Reader;
#[cfg(test)]
use uuid::Uuid;
use zip::read::ZipArchive;
use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipWriter};

use crate::import::archive_path::{is_comicinfo_entry, normalize_archive_path};
use crate::export_atomic::atomic_write_destination;
use crate::export_error::{ExportError, ExportErrorKind};
use crate::metadata_schema::normalize_comma_separated_tags;
use crate::page_image::normalize_extension;
use crate::published_date::{merge_year_month_day, parse_published_date};

pub const EPUB_MIMETYPE: &str = "application/epub+zip";

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParsedOpfMetadata {
    pub title: Option<String>,
    pub creators: Vec<String>,
    pub publisher: Option<String>,
    pub series: Option<String>,
    pub number: Option<String>,
    pub series_count: Option<String>,
    pub published_date: Option<String>,
    pub description: Option<String>,
    pub language: Option<String>,
    pub subjects: Vec<String>,
    pub characters: Option<String>,
    pub tags: Option<String>,
    pub age_rating: Option<String>,
    pub cover_manifest_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct ManifestItem {
    href: String,
    media_type: String,
    properties: Option<String>,
}

/// Extract the raw `<metadata>...</metadata>` element from an OPF package document.
pub fn extract_opf_metadata_section(opf_xml: &str) -> Option<String> {
    let lower = opf_xml.to_lowercase();
    let start = lower.find("<metadata")?;
    let relative_end = lower[start..].find("</metadata>")?;
    let end = start + relative_end + "</metadata>".len();
    Some(opf_xml[start..end].to_string())
}

/// Spine-ordered zip entry paths to page images inside the EPUB.
pub fn scan_epub_page_paths(
    path: &Path,
) -> Result<
    (
        Vec<String>,
        ParsedOpfMetadata,
        Option<String>,
        Option<String>,
        i32,
    ),
    String,
> {
    let file = File::open(path).map_err(|error| format!("open EPUB: {error}"))?;
    let mut archive =
        ZipArchive::new(file).map_err(|error| format!("read EPUB archive: {error}"))?;

    let opf_path = locate_opf_path(&mut archive)?;
    let opf_xml = read_zip_entry_to_string(&mut archive, &opf_path)?;
    let opf_dir = opf_parent_dir(&opf_path);

    let (metadata, manifest, spine_ids) = parse_opf(&opf_xml)?;
    let comicinfo_xml = find_comicinfo_in_archive(&mut archive)?;

    let mut page_paths = Vec::new();
    for idref in spine_ids {
        let Some(item) = manifest.get(&idref) else {
            continue;
        };
        if let Some(image_path) = resolve_spine_image(&mut archive, &opf_dir, item)? {
            page_paths.push(image_path);
        }
    }

    if page_paths.is_empty() {
        page_paths = collect_manifest_images(&manifest, &opf_dir)?;
    }

    let opf_metadata_xml = extract_opf_metadata_section(&opf_xml);
    let cover_page_index =
        resolve_opf_cover_page_index(&metadata, &manifest, &opf_dir, &page_paths);

    Ok((
        page_paths,
        metadata,
        comicinfo_xml,
        opf_metadata_xml,
        cover_page_index,
    ))
}

fn locate_opf_path(archive: &mut ZipArchive<File>) -> Result<String, String> {
    let container = read_zip_entry_to_string(archive, "META-INF/container.xml")?;
    let mut reader = Reader::from_str(&container);
    reader.config_mut().trim_text(true);

    let mut buf = Vec::new();
    let mut opf_path = None;
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(event)) | Ok(Event::Start(event)) => {
                if event.local_name().as_ref() == b"rootfile" {
                    for attr in event.attributes().flatten() {
                        if attr.key.as_ref() == b"full-path" {
                            opf_path =
                                Some(String::from_utf8_lossy(&attr.value).trim().to_string());
                        }
                    }
                }
            }
            Ok(Event::Eof) => break,
            Err(error) => return Err(format!("parse container.xml: {error}")),
            _ => {}
        }
        buf.clear();
    }

    opf_path.ok_or_else(|| "EPUB container.xml missing rootfile full-path".to_string())
}

fn manifest_attrs(event: &quick_xml::events::BytesStart<'_>) -> Option<(String, String, String, Option<String>)> {
    let mut id = None;
    let mut href = None;
    let mut media_type = None;
    let mut properties = None;
    for attr in event.attributes().flatten() {
        match attr.key.as_ref() {
            b"id" => id = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            b"href" => href = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            b"media-type" => media_type = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            b"properties" => properties = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            _ => {}
        }
    }
    match (id, href, media_type) {
        (Some(id), Some(href), Some(media_type)) => Some((id, href, media_type, properties)),
        _ => None,
    }
}

fn meta_name_content_attrs(
    event: &quick_xml::events::BytesStart<'_>,
) -> Option<(String, String)> {
    let mut name = None;
    let mut content = None;
    for attr in event.attributes().flatten() {
        let key = String::from_utf8_lossy(attr.key.as_ref());
        let value = String::from_utf8_lossy(&attr.value).into_owned();
        match key.as_ref() {
            "name" => name = Some(value),
            "content" => content = Some(value),
            _ => {}
        }
    }
    match (name, content) {
        (Some(name), Some(content)) if !content.trim().is_empty() => Some((name, content)),
        _ => None,
    }
}

fn itemref_id(event: &quick_xml::events::BytesStart<'_>) -> Option<String> {
    for attr in event.attributes().flatten() {
        if attr.key.as_ref() == b"idref" {
            return Some(String::from_utf8_lossy(&attr.value).into_owned());
        }
    }
    None
}

fn parse_opf(
    xml: &str,
) -> Result<
    (
        ParsedOpfMetadata,
        HashMap<String, ManifestItem>,
        Vec<String>,
    ),
    String,
> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut metadata = ParsedOpfMetadata::default();
    let mut manifest = HashMap::new();
    let mut spine_ids = Vec::new();

    let mut buf = Vec::new();
    let mut in_metadata = false;
    let mut in_manifest = false;
    let mut in_spine = false;
    let mut current_dc_tag: Option<String> = None;
    let mut text_buf = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(event)) | Ok(Event::Empty(event)) => {
                let name = String::from_utf8_lossy(event.local_name().as_ref()).to_string();
                match name.as_str() {
                    "metadata" => in_metadata = true,
                    "manifest" => in_manifest = true,
                    "spine" => in_spine = true,
                    "item" if in_manifest => {
                        if let Some((id, href, media_type, properties)) = manifest_attrs(&event) {
                            manifest.insert(
                                id,
                                ManifestItem {
                                    href,
                                    media_type,
                                    properties,
                                },
                            );
                        }
                    }
                    "itemref" if in_spine => {
                        if let Some(idref) = itemref_id(&event) {
                            spine_ids.push(idref);
                        }
                    }
                    "meta" if in_metadata => {
                        if let Some((name, content)) = meta_name_content_attrs(&event) {
                            match name.as_str() {
                                "characters" => metadata.characters = Some(content),
                                "tags" => metadata.tags = Some(content),
                                "series-count" => metadata.series_count = Some(content),
                                "rating" => metadata.age_rating = Some(content),
                                "cover" => metadata.cover_manifest_id = Some(content),
                                "series" if metadata.series.is_none() => {
                                    metadata.series = Some(content)
                                }
                                "number" if metadata.number.is_none() => {
                                    metadata.number = Some(content)
                                }
                                _ => {}
                            }
                        }
                    }
                    tag if in_metadata => {
                        let dc_tag = tag.strip_prefix("dc:").unwrap_or(&tag);
                        if matches!(
                            dc_tag,
                            "title"
                                | "creator"
                                | "publisher"
                                | "description"
                                | "language"
                                | "series"
                                | "number"
                                | "date"
                                | "subject"
                        ) {
                            current_dc_tag = Some(dc_tag.to_string());
                            text_buf.clear();
                        }
                    }
                    _ => {}
                }
            }
            Ok(Event::Text(event)) => {
                if current_dc_tag.is_some() {
                    text_buf.push_str(&event.unescape().map_err(|e| e.to_string())?);
                }
            }
            Ok(Event::End(event)) => {
                let name = String::from_utf8_lossy(event.local_name().as_ref()).to_string();
                if let Some(tag) = current_dc_tag.take() {
                    let value = text_buf.trim();
                    if !value.is_empty() {
                        match tag.as_str() {
                            "title" => metadata.title = Some(value.to_string()),
                            "creator" => metadata.creators.push(value.to_string()),
                            "publisher" => metadata.publisher = Some(value.to_string()),
                            "description" => metadata.description = Some(value.to_string()),
                            "language" => metadata.language = Some(value.to_string()),
                            "series" => metadata.series = Some(value.to_string()),
                            "number" => metadata.number = Some(value.to_string()),
                            "date" => {
                                metadata.published_date =
                                    normalize_opf_published_date(value);
                            }
                            "subject" => metadata.subjects.push(value.to_string()),
                            _ => {}
                        }
                    }
                    text_buf.clear();
                }
                match name.as_str() {
                    "metadata" => in_metadata = false,
                    "manifest" => in_manifest = false,
                    "spine" => in_spine = false,
                    _ => {}
                }
            }
            Ok(Event::Eof) => break,
            Err(error) => return Err(format!("parse OPF: {error}")),
            _ => {}
        }
        buf.clear();
    }

    Ok((metadata, manifest, spine_ids))
}

fn resolve_spine_image(
    archive: &mut ZipArchive<File>,
    opf_dir: &str,
    item: &ManifestItem,
) -> Result<Option<String>, String> {
    if item.media_type.starts_with("image/") {
        let path = join_opf_href(opf_dir, &item.href)?;
        return Ok(normalize_extension(Path::new(&path)).ok().map(|_| path));
    }

    if item.media_type.contains("html") {
        let xhtml_path = join_opf_href(opf_dir, &item.href)?;
        let Ok(xhtml) = read_zip_entry_to_string(archive, &xhtml_path) else {
            return Ok(None);
        };
        if let Some(src) = image_src_from_xhtml(&xhtml) {
            let image_path = join_opf_href(&opf_parent_dir(&xhtml_path), &src)?;
            if normalize_extension(Path::new(&image_path)).is_ok() {
                return Ok(Some(image_path));
            }
        }
    }

    Ok(None)
}

fn collect_manifest_images(
    manifest: &HashMap<String, ManifestItem>,
    opf_dir: &str,
) -> Result<Vec<String>, String> {
    let mut paths = Vec::new();
    for item in manifest.values() {
        if !item.media_type.starts_with("image/") {
            continue;
        }
        let path = join_opf_href(opf_dir, &item.href)?;
        if normalize_extension(Path::new(&path)).is_ok() {
            paths.push(path);
        }
    }
    crate::natural_sort::sort_paths(&mut paths);
    Ok(paths)
}

fn find_comicinfo_in_archive(archive: &mut ZipArchive<File>) -> Result<Option<String>, String> {
    let mut comicinfo_path = None;
    for index in 0..archive.len() {
        let entry = archive
            .by_index(index)
            .map_err(|error| format!("read EPUB entry {index}: {error}"))?;
        if entry.is_dir() {
            continue;
        }
        let path = normalize_archive_path(entry.name())?;
        if is_comicinfo_entry(&path) {
            comicinfo_path = Some(path);
            break;
        }
    }
    if let Some(path) = comicinfo_path {
        return Ok(Some(read_zip_entry_to_string(archive, &path)?));
    }
    Ok(None)
}

fn image_src_from_xhtml(xml: &str) -> Option<String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);
    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Empty(event)) | Ok(Event::Start(event)) => {
                let tag = event.local_name();
                if tag.as_ref() == b"img" || tag.as_ref() == b"image" {
                    for attr in event.attributes().flatten() {
                        let key = String::from_utf8_lossy(attr.key.as_ref());
                        if key == "src" || key == "href" || key.ends_with(":href") {
                            return Some(String::from_utf8_lossy(&attr.value).into_owned());
                        }
                    }
                }
            }
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    None
}

fn read_zip_entry_to_string(archive: &mut ZipArchive<File>, path: &str) -> Result<String, String> {
    let mut entry = find_zip_entry(archive, path)?;
    let mut content = String::new();
    entry
        .read_to_string(&mut content)
        .map_err(|error| format!("read EPUB entry {path}: {error}"))?;
    Ok(content)
}

pub fn find_zip_entry<'a>(
    archive: &'a mut ZipArchive<File>,
    target_path: &str,
) -> Result<zip::read::ZipFile<'a>, String> {
    for index in 0..archive.len() {
        let name = {
            let entry = archive
                .by_index(index)
                .map_err(|error| format!("read EPUB entry {index}: {error}"))?;
            normalize_archive_path(entry.name())?
        };
        if name == target_path {
            return archive
                .by_index(index)
                .map_err(|error| format!("reopen EPUB entry {index}: {error}"));
        }
    }
    Err(format!("EPUB entry not found: {target_path}"))
}

fn opf_parent_dir(opf_path: &str) -> String {
    Path::new(opf_path)
        .parent()
        .map(|parent| {
            let normalized = parent.to_string_lossy().replace('\\', "/");
            if normalized.is_empty() {
                String::new()
            } else {
                format!("{normalized}/")
            }
        })
        .unwrap_or_default()
}

fn join_opf_href(opf_dir: &str, href: &str) -> Result<String, String> {
    resolve_archive_href(opf_dir, href)
}

fn resolve_archive_href(base_dir: &str, href: &str) -> Result<String, String> {
    let mut segments = Vec::<String>::new();

    for part in base_dir.replace('\\', "/").split('/') {
        if part.is_empty() || part == "." {
            continue;
        }
        segments.push(part.to_string());
    }

    for part in href.replace('\\', "/").split('/') {
        if part.is_empty() || part == "." {
            continue;
        }
        if part == ".." {
            if segments.pop().is_none() {
                return Err(format!("unsafe archive path traversal: {href}"));
            }
            continue;
        }
        segments.push(part.to_string());
    }

    if segments.is_empty() {
        return Err(format!("invalid archive href: {href}"));
    }

    Ok(segments.join("/"))
}

fn normalize_opf_published_date(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }

    let date_part = trimmed
        .split(['T', ' ', 't'].as_ref())
        .next()
        .unwrap_or(trimmed)
        .trim();
    if parse_published_date(date_part).is_some() {
        return Some(date_part.to_string());
    }

    if let Some(parts) = parse_published_date(trimmed) {
        return merge_year_month_day(Some(parts.year), parts.month, parts.day);
    }

    None
}

fn join_opf_text_values(values: &[String]) -> Option<String> {
    let parts: Vec<&str> = values
        .iter()
        .map(String::as_str)
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .collect();
    if parts.is_empty() {
        None
    } else {
        Some(parts.join(", "))
    }
}

fn cover_image_path_from_opf(
    metadata: &ParsedOpfMetadata,
    manifest: &HashMap<String, ManifestItem>,
    opf_dir: &str,
) -> Option<String> {
    if let Some(id) = metadata.cover_manifest_id.as_deref() {
        if let Some(item) = manifest.get(id) {
            if item.media_type.starts_with("image/") {
                return join_opf_href(opf_dir, &item.href).ok();
            }
        }
    }

    for item in manifest.values() {
        if item
            .properties
            .as_deref()
            .is_some_and(|properties| properties.split_whitespace().any(|part| part == "cover-image"))
            && item.media_type.starts_with("image/")
        {
            return join_opf_href(opf_dir, &item.href).ok();
        }
    }

    None
}

fn resolve_opf_cover_page_index(
    metadata: &ParsedOpfMetadata,
    manifest: &HashMap<String, ManifestItem>,
    opf_dir: &str,
    page_paths: &[String],
) -> i32 {
    let Some(cover_path) = cover_image_path_from_opf(metadata, manifest, opf_dir) else {
        return 0;
    };
    page_paths
        .iter()
        .position(|path| path == &cover_path)
        .unwrap_or(0) as i32
}

pub fn metadata_from_opf(
    opf: &ParsedOpfMetadata,
    fallback_title: &str,
    page_count: i32,
    cover_page_index: i32,
) -> crate::db::MetadataRecord {
    let title = opf
        .title
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(fallback_title)
        .trim()
        .to_string();

    let tags = opf
        .tags
        .as_deref()
        .and_then(normalize_comma_separated_tags)
        .or_else(|| join_opf_text_values(&opf.subjects));

    crate::db::MetadataRecord {
        title,
        series: optional_trimmed_copy(&opf.series),
        number: optional_trimmed_copy(&opf.number),
        series_count: optional_trimmed_copy(&opf.series_count),
        published_date: opf.published_date.clone(),
        language_iso: optional_trimmed_copy(&opf.language),
        author: join_opf_text_values(&opf.creators),
        tags,
        characters: opf
            .characters
            .as_deref()
            .and_then(normalize_comma_separated_tags),
        age_rating: optional_trimmed_copy(&opf.age_rating),
        description: optional_trimmed_copy(&opf.description),
        cover_page_index,
        page_count,
    }
}

fn optional_trimmed_copy(value: &Option<String>) -> Option<String> {
    value
        .as_ref()
        .map(|text| text.trim().to_string())
        .filter(|text| !text.is_empty())
}

pub(crate) fn write_epub(
    destination: &Path,
    metadata: &crate::db::MetadataRecord,
    pages: &[crate::db::PageRecord],
) -> Result<(), ExportError> {
    if pages.is_empty() {
        return Err(ExportError::no_pages());
    }

    atomic_write_destination(destination, |temp_path| {
        write_epub_to_path(temp_path, metadata, pages)
    })
}

fn write_epub_to_path(
    temp_path: &Path,
    metadata: &crate::db::MetadataRecord,
    pages: &[crate::db::PageRecord],
) -> Result<(), ExportError> {
    let file = File::create(temp_path)
        .map_err(|error| ExportError::map_create_destination(error, temp_path))?;
    let mut zip = ZipWriter::new(file);

    let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
    let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

    zip.start_file("mimetype", stored)
        .map_err(|error| ExportError::map_archive_write("write mimetype", error))?;
    zip.write_all(EPUB_MIMETYPE.as_bytes())
        .map_err(|error| ExportError::map_archive_write("write mimetype content", error))?;

    let container_xml = r#"<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"#;
    write_zip_string(&mut zip, "META-INF/container.xml", container_xml, deflated)?;

    let mut page_manifest_items = String::new();
    let mut image_manifest_items = String::new();
    let mut extra_manifest_items = String::new();
    let mut spine_items = String::new();
    let mut nav_points = String::new();
    let mut ncx_points = String::new();

    let page_count = pages.len();
    let cover_page_index = metadata
        .cover_page_index
        .clamp(0, page_count.saturating_sub(1) as i32);
    let mut cover_image_href = String::new();

    extra_manifest_items.push_str(
        r#"    <item id="ncx" href="xml/vol.nav" media-type="application/x-dtbncx+xml"/>
    <item id="css" href="css/style.css" media-type="text/css"/>
"#,
    );

    for page in pages {
        let extension = normalize_extension(Path::new(&page.asset_path))
            .map_err(ExportError::from_library)?;
        let width = 5_usize.max(page_count.to_string().len());
        let stem = format!("{:0width$}", page.sort_index + 1, width = width);
        let image_name = format!("{stem}.{extension}");
        let html_name = format!("page-{stem}.html");
        let image_href = format!("image/{image_name}");
        let html_href = format!("html/{html_name}");
        let image_id = format!("img_{}", page.sort_index + 1);
        let page_id = format!("Page_{}", page.sort_index + 1);

        image_manifest_items.push_str(&format!(
            r#"    <item id="{image_id}" href="{image_href}" media-type="{}"/> 
"#,
            mime_for_extension(&extension)
        ));
        let html = page_html(&format!("../{image_href}"), page.sort_index + 1);
        write_zip_string(&mut zip, &html_href, &html, deflated)?;

        zip.start_file(&image_href, deflated).map_err(|error| {
            ExportError::map_archive_write(&format!("write image {image_href}"), error)
        })?;
        let mut source = File::open(&page.absolute_path).map_err(|error| {
            ExportError::map_open_page_asset(error, &page.absolute_path)
        })?;
        std::io::copy(&mut source, &mut zip).map_err(|error| {
            ExportError::map_archive_write("copy page into EPUB", error)
        })?;
        if page.sort_index == cover_page_index {
            cover_image_href = image_href.clone();
            page_manifest_items.push_str(&format!(
                r#"    <item id="Page_cover" href="{html_href}" media-type="application/xhtml+xml" /> 
"#
            ));
            continue;
        }
        page_manifest_items.push_str(&format!(
            r#"    <item id="{page_id}" href="{html_href}" media-type="application/xhtml+xml" /> 
"#
        ));

        spine_items.push_str(&format!(
            r#"    <itemref idref="{page_id}" /> 
"#
        ));
        nav_points.push_str(&format!(
            r#"      <li><a href="{html_href}">Page {}</a></li>
"#,
            page.sort_index + 1
        ));
        ncx_points.push_str(&format!(
            r#"    <navPoint id="{page_id}" playOrder="{}">
      <navLabel><text>Page {}</text></navLabel>
      <content src="{html_href}"/>
    </navPoint>
"#,
            page.sort_index + 1,
            page.sort_index + 1
        ));
    }

    image_manifest_items.push_str(&format!(
        r#"    <item id="cover_img" href="{}" media-type="{}" properties="cover-image" />
"#,
        cover_image_href,
        mime_for_extension(
            Path::new(&cover_image_href)
                .extension()
                .and_then(|ext| ext.to_str())
                .unwrap_or("jpg"),
        )
    ));

    let css = "html,body{margin:0;padding:0;} img{display:block;width:100%;height:auto;}";
    write_zip_string(&mut zip, "css/style.css", css, deflated)?;

    let nav_xhtml = format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
<head><title>Navigation</title></head>
<body>
  <nav epub:type="toc" id="toc">
    <h1>Table of Contents</h1>
    <ol>
{nav_points}    </ol>
  </nav>
</body>
</html>
"#
    );
    write_zip_string(&mut zip, "html/nav.html", &nav_xhtml, deflated)?;

    let cover_page = pages
        .iter()
        .find(|page| page.sort_index == cover_page_index)
        .ok_or_else(|| ExportError::new(
            ExportErrorKind::ArchiveWriteFailed,
            "Export 需要封面页",
        ))?;
    let original_resolution = page_image_resolution(&cover_page.absolute_path)
        .map_err(|detail| ExportError::new(ExportErrorKind::PageAssetUnreadable, detail))?;

    let ncx = format!(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="{}"/>
  </head>
  <docTitle><text>{}</text></docTitle>
  <navMap>
{ncx_points}  </navMap>
</ncx>
"#,
        escape_xml(opf_identifier_value(metadata)),
        escape_xml(&metadata.title)
    );
    write_zip_string(&mut zip, "xml/vol.nav", &ncx, deflated)?;

    let opf = build_content_opf(
        metadata,
        &page_manifest_items,
        &image_manifest_items,
        &extra_manifest_items,
        &spine_items,
        &cover_image_href,
        &original_resolution,
    );
    write_zip_string(&mut zip, "content.opf", &opf, deflated)?;

    zip.finish()
        .map_err(|error| ExportError::map_archive_write("finalize EPUB", error))?;
    Ok(())
}

fn build_content_opf(
    metadata: &crate::db::MetadataRecord,
    page_manifest_items: &str,
    image_manifest_items: &str,
    extra_manifest_items: &str,
    spine_items: &str,
    cover_image_href: &str,
    original_resolution: &str,
) -> String {
    let identifier_id = opf_identifier_id(metadata);
    let identifier_value = opf_identifier_value(metadata);
    let identifier_scheme = opf_identifier_scheme(metadata);
    let language = metadata
        .language_iso
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or("und");

    let mut opf = format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<package version="3.0" unique-identifier="{}" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
"#,
        escape_xml(&identifier_id),
    );

    append_comic_rendition_metadata(&mut opf, original_resolution);

    opf.push_str(&format!(
        "    <dc:identifier id=\"{}\"{}>{}</dc:identifier>\n    <dc:title>{}</dc:title>\n    <dc:language>{}</dc:language>\n",
        escape_xml(&identifier_id),
        identifier_scheme
            .as_deref()
            .map(|s| format!(" opf:scheme=\"{}\"", escape_xml(s)))
            .unwrap_or_default(),
        escape_xml(&identifier_value),
        escape_xml(&metadata.title),
        escape_xml(language),
    ));

    append_dc_creators(&mut opf, metadata.author.as_deref());
    append_dc_element(&mut opf, "description", metadata.description.as_deref());
    append_dc_element(&mut opf, "series", metadata.series.as_deref());
    append_dc_element(&mut opf, "number", metadata.number.as_deref());
    if let Some(published_date) = metadata.published_date.as_deref() {
        append_dc_element(&mut opf, "date", Some(published_date));
    }
    append_meta_name_content(
        &mut opf,
        "series-count",
        metadata.series_count.as_deref(),
    );
    append_meta_name_content(
        &mut opf,
        "characters",
        metadata
            .characters
            .as_deref()
            .and_then(normalize_comma_separated_tags)
            .as_deref(),
    );
    append_meta_name_content(
        &mut opf,
        "tags",
        metadata
            .tags
            .as_deref()
            .and_then(normalize_comma_separated_tags)
            .as_deref(),
    );
    append_meta_name_content(&mut opf, "rating", metadata.age_rating.as_deref());
    opf.push_str(r#"    <meta name="cover" content="cover_img"/>"#);
    opf.push('\n');

    opf.push_str(
        r#"  </metadata>
  <manifest>
"#,
    );
    opf.push_str(extra_manifest_items);
    opf.push('\n');
    opf.push_str(page_manifest_items);
    opf.push('\n');
    opf.push_str(image_manifest_items);
    opf.push_str(
        r#"  </manifest>
  <spine toc="ncx">
"#,
    );
    opf.push_str(
        r#"    <itemref idref="Page_cover" />
"#,
    );
    opf.push_str(spine_items);
    opf.push_str("</spine>\n");
    opf.push_str("  <guide>\n");
    opf.push_str(&format!(
        "    <reference type=\"cover\" href=\"{}\" title=\"封面\" />\n",
        escape_xml(cover_image_href)
    ));
    opf.push_str("  </guide>\n</package>\n");
    opf
}

fn opf_identifier_id(_metadata: &crate::db::MetadataRecord) -> String {
    "book-id".to_string()
}

fn opf_identifier_scheme(_metadata: &crate::db::MetadataRecord) -> Option<String> {
    None
}

fn opf_identifier_value(metadata: &crate::db::MetadataRecord) -> &str {
    metadata.title.as_str()
}

fn append_dc_element(opf: &mut String, tag: &str, value: Option<&str>) {
    let Some(value) = value.map(str::trim).filter(|v| !v.is_empty()) else {
        return;
    };
    opf.push_str(&format!("    <dc:{tag}>{}</dc:{tag}>\n", escape_xml(value)));
}

fn append_dc_creators(opf: &mut String, author: Option<&str>) {
    let Some(author) = author.map(str::trim).filter(|value| !value.is_empty()) else {
        return;
    };
    for part in author
        .split(',')
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        append_dc_element(opf, "creator", Some(part));
    }
}

fn append_meta_name_content(opf: &mut String, name: &str, value: Option<&str>) {
    let Some(value) = value.map(str::trim).filter(|v| !v.is_empty()) else {
        return;
    };
    opf.push_str(&format!(
        "    <meta name=\"{}\" content=\"{}\"/>\n",
        escape_xml(name),
        escape_xml(value)
    ));
}

fn append_meta_property_body(opf: &mut String, property: &str, body: &str) {
    opf.push_str(&format!(
        "    <meta property=\"{}\">{}</meta>\n",
        escape_xml(property),
        escape_xml(body)
    ));
}

fn append_comic_rendition_metadata(opf: &mut String, original_resolution: &str) {
    append_meta_property_body(opf, "rendition:layout", "pre-paginated");
    append_meta_property_body(opf, "rendition:spread", "landscape");
    opf.push_str(
        r#"    <meta name="book-type" content="comic"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="zero-gutter" content="true"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="zero-margin" content="true"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="RegionMagnification" content="true"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="fixed-layout" content="true"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="orientation-lock" content="portrait"/>
"#,
    );
    opf.push_str(
        r#"    <meta name="primary-writing-mode" content="horizontal-rl"/>
"#,
    );
    opf.push_str(&format!(
        "    <meta name=\"original-resolution\" content=\"{}\"/>\n",
        escape_xml(original_resolution)
    ));
}

fn page_image_resolution(path: &str) -> Result<String, String> {
    let (width, height) = image::image_dimensions(path)
        .map_err(|error| format!("read image dimensions {path}: {error}"))?;
    Ok(format!("{width}x{height}"))
}

fn page_html(image_href: &str, page_number: i32) -> String {
    format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Page {page_number}</title></head>
<body style="margin:0;padding:0;text-align:center;">
  <img src="{image_href}" alt=""/>
</body>
</html>
"#
    )
}

fn mime_for_extension(extension: &str) -> &'static str {
    match extension {
        "jpg" | "jpeg" => "image/jpeg",
        "png" => "image/png",
        "webp" => "image/webp",
        "gif" => "image/gif",
        "avif" => "image/avif",
        "bmp" => "image/bmp",
        _ => "application/octet-stream",
    }
}

fn write_zip_string(
    zip: &mut ZipWriter<File>,
    path: &str,
    content: &str,
    options: SimpleFileOptions,
) -> Result<(), ExportError> {
    zip.start_file(path, options)
        .map_err(|error| ExportError::map_archive_write(&format!("write {path}"), error))?;
    zip.write_all(content.as_bytes())
        .map_err(|error| ExportError::map_archive_write(&format!("write {path} content"), error))?;
    Ok(())
}

fn escape_xml(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

#[cfg(test)]
pub(crate) fn write_minimal_epub(
    path: &Path,
    title: &str,
    pages: &[(&str, &str, Vec<u8>)],
    comicinfo: Option<&str>,
) {
    use std::io::Write;
    use zip::ZipWriter;

    let file = File::create(path).expect("create epub");
    let mut zip = ZipWriter::new(file);
    let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
    let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

    zip.start_file("mimetype", stored).expect("mimetype");
    zip.write_all(EPUB_MIMETYPE.as_bytes())
        .expect("mimetype body");

    let container = r#"<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"#;
    zip.start_file("META-INF/container.xml", deflated)
        .expect("container");
    zip.write_all(container.as_bytes()).expect("container body");

    let mut manifest = String::from(
        r#"    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
"#,
    );
    let mut spine = String::from(
        r#"    <itemref idref="nav" linear="no"/>
"#,
    );

    for (index, (xhtml_name, image_href, image_bytes)) in pages.iter().enumerate() {
        let xhtml_id = format!("page{}", index + 1);
        let image_id = format!("img{}", index + 1);
        manifest.push_str(&format!(
            r#"    <item id="{image_id}" href="{image_href}" media-type="image/png"/>
    <item id="{xhtml_id}" href="{xhtml_name}" media-type="application/xhtml+xml"/>
"#
        ));
        spine.push_str(&format!(
            r#"    <itemref idref="{xhtml_id}"/>
"#
        ));

        let xhtml = format!(
            r#"<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><img src="{image_href}"/></body></html>
"#
        );
        zip.start_file(format!("OEBPS/{xhtml_name}"), deflated)
            .expect("xhtml");
        zip.write_all(xhtml.as_bytes()).expect("xhtml body");

        zip.start_file(format!("OEBPS/{image_href}"), deflated)
            .expect("image");
        zip.write_all(image_bytes).expect("image body");
    }

    if let Some(xml) = comicinfo {
        manifest.push_str(
            r#"    <item id="comicinfo" href="ComicInfo.xml" media-type="text/xml"/>
"#,
        );
        zip.start_file("OEBPS/ComicInfo.xml", deflated)
            .expect("comicinfo");
        zip.write_all(xml.as_bytes()).expect("comicinfo body");
    }

    let opf = format!(
        r#"<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">urn:uuid:test</dc:identifier>
    <dc:title>{title}</dc:title>
    <dc:language>zh</dc:language>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
{manifest}  </manifest>
  <spine>
{spine}  </spine>
</package>
"#
    );
    zip.start_file("OEBPS/content.opf", deflated).expect("opf");
    zip.write_all(opf.as_bytes()).expect("opf body");

    zip.finish().expect("finish epub");
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{ImageBuffer, Rgba};

    #[test]
    fn extract_opf_metadata_section_returns_element() {
        let opf = r#"<?xml version="1.0"?>
<package>
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test</dc:title>
  </metadata>
</package>"#;
        let section = extract_opf_metadata_section(opf).expect("section");
        assert!(section.contains("<metadata"));
        assert!(section.contains("<dc:title>Test</dc:title>"));
    }

    #[test]
    fn parse_opf_reads_characters_and_tags_meta() {
        let opf = r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test</dc:title>
    <meta name="characters" content="角色A,角色B"/>
    <meta name="tags" content="标签A,标签B"/>
  </metadata>
  <manifest></manifest>
  <spine></spine>
</package>"#;

        let (metadata, _, _) = parse_opf(opf).expect("parse");
        assert_eq!(metadata.title.as_deref(), Some("Test"));
        assert_eq!(metadata.characters.as_deref(), Some("角色A,角色B"));
        assert_eq!(metadata.tags.as_deref(), Some("标签A,标签B"));
    }

    use std::io::Cursor;
    use std::path::PathBuf;
    use zip::write::SimpleFileOptions;
    use zip::{CompressionMethod, ZipWriter};

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-epub-{name}-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn png_bytes() -> Vec<u8> {
        let img = ImageBuffer::from_fn(8, 12, |_, _| Rgba([30u8, 90, 180, 255]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, image::ImageFormat::Png)
            .expect("encode png");
        buffer.into_inner()
    }

    #[test]
    fn scan_epub_orders_pages_by_spine() {
        let dir = temp_dir("scan");
        let epub = dir.join("test.epub");
        let png = png_bytes();
        write_minimal_epub(
            &epub,
            "Spine Order",
            &[
                ("page1.xhtml", "images/1.png", png.clone()),
                ("page2.xhtml", "images/2.png", png),
            ],
            None,
        );

        let (paths, metadata, _, _, _) = scan_epub_page_paths(&epub).expect("scan");
        assert_eq!(paths, vec!["OEBPS/images/1.png", "OEBPS/images/2.png"]);
        assert_eq!(metadata.title.as_deref(), Some("Spine Order"));
        assert_eq!(metadata.creators, vec!["Test Author".to_string()]);
    }

    #[test]
    fn scan_epub_supports_parent_relative_image_href() {
        use std::io::Write;

        let dir = temp_dir("relative");
        let epub = dir.join("relative.epub");
        let png = png_bytes();

        let file = File::create(&epub).expect("create epub");
        let mut zip = ZipWriter::new(file);
        let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
        let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

        zip.start_file("mimetype", stored).expect("mimetype");
        zip.write_all(EPUB_MIMETYPE.as_bytes())
            .expect("mimetype body");

        let container = r#"<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"#;
        zip.start_file("META-INF/container.xml", deflated)
            .expect("container");
        zip.write_all(container.as_bytes()).expect("container body");

        let page_xhtml = r#"<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><img src="../image/page1.png"/></body></html>
"#;
        zip.start_file("OEBPS/html/page1.xhtml", deflated)
            .expect("xhtml");
        zip.write_all(page_xhtml.as_bytes()).expect("xhtml body");

        zip.start_file("OEBPS/image/page1.png", deflated)
            .expect("image");
        zip.write_all(&png).expect("image body");

        let opf = r#"<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">urn:uuid:test</dc:identifier>
    <dc:title>Relative</dc:title>
    <dc:language>zh</dc:language>
  </metadata>
  <manifest>
    <item id="page1" href="html/page1.xhtml" media-type="application/xhtml+xml"/>
    <item id="img1" href="image/page1.png" media-type="image/png"/>
  </manifest>
  <spine>
    <itemref idref="page1"/>
  </spine>
</package>
"#;
        zip.start_file("OEBPS/content.opf", deflated).expect("opf");
        zip.write_all(opf.as_bytes()).expect("opf body");
        zip.finish().expect("finish");

        let (paths, metadata, _, opf_section, _) = scan_epub_page_paths(&epub).expect("scan");
        assert_eq!(paths, vec!["OEBPS/image/page1.png"]);
        assert_eq!(metadata.title.as_deref(), Some("Relative"));
        assert!(opf_section.is_some());
    }

    #[test]
    fn parse_opf_reads_canonical_metadata_fields() {
        let opf = r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>OPF Title</dc:title>
    <dc:creator>Alice</dc:creator>
    <dc:creator>Bob</dc:creator>
    <dc:series>Sample Series</dc:series>
    <dc:number>7</dc:number>
    <dc:date>2024-05-31T00:00:00Z</dc:date>
    <dc:language>zh-CN</dc:language>
    <dc:description>Summary text</dc:description>
    <dc:subject>标签A</dc:subject>
    <meta name="series-count" content="12"/>
    <meta name="characters" content="角色A,角色B"/>
    <meta name="tags" content="标签A,标签B"/>
    <meta name="rating" content="Teen"/>
    <meta name="cover" content="cover_img"/>
  </metadata>
  <manifest>
    <item id="cover_img" href="images/cover.png" media-type="image/png" properties="cover-image"/>
    <item id="page1" href="images/1.png" media-type="image/png"/>
  </manifest>
  <spine></spine>
</package>"#;

        let (metadata, manifest, _) = parse_opf(opf).expect("parse");
        assert_eq!(metadata.title.as_deref(), Some("OPF Title"));
        assert_eq!(metadata.creators, vec!["Alice".to_string(), "Bob".to_string()]);
        assert_eq!(metadata.series.as_deref(), Some("Sample Series"));
        assert_eq!(metadata.number.as_deref(), Some("7"));
        assert_eq!(metadata.series_count.as_deref(), Some("12"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024-05-31"));
        assert_eq!(metadata.language.as_deref(), Some("zh-CN"));
        assert_eq!(metadata.description.as_deref(), Some("Summary text"));
        assert_eq!(metadata.tags.as_deref(), Some("标签A,标签B"));
        assert_eq!(metadata.characters.as_deref(), Some("角色A,角色B"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Teen"));
        assert_eq!(metadata.cover_manifest_id.as_deref(), Some("cover_img"));
        assert!(manifest.contains_key("cover_img"));
    }

    #[test]
    fn metadata_from_opf_maps_to_canonical_record() {
        let opf = ParsedOpfMetadata {
            title: Some("Title".to_string()),
            creators: vec!["Alice".to_string(), "Bob".to_string()],
            series: Some("Series".to_string()),
            number: Some("3".to_string()),
            series_count: Some("10".to_string()),
            published_date: Some("2024".to_string()),
            language: Some("en".to_string()),
            description: Some("Desc".to_string()),
            characters: Some("Char".to_string()),
            tags: Some("Tag".to_string()),
            age_rating: Some("Mature".to_string()),
            ..Default::default()
        };

        let metadata = metadata_from_opf(&opf, "Fallback", 5, 2);
        assert_eq!(metadata.title, "Title");
        assert_eq!(metadata.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(metadata.series.as_deref(), Some("Series"));
        assert_eq!(metadata.number.as_deref(), Some("3"));
        assert_eq!(metadata.series_count.as_deref(), Some("10"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024"));
        assert_eq!(metadata.language_iso.as_deref(), Some("en"));
        assert_eq!(metadata.description.as_deref(), Some("Desc"));
        assert_eq!(metadata.characters.as_deref(), Some("Char"));
        assert_eq!(metadata.tags.as_deref(), Some("Tag"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Mature"));
        assert_eq!(metadata.page_count, 5);
        assert_eq!(metadata.cover_page_index, 2);
    }

    #[test]
    fn metadata_from_opf_uses_dc_subject_when_tags_meta_missing() {
        let opf = ParsedOpfMetadata {
            subjects: vec!["标签A".to_string(), "标签B".to_string()],
            ..Default::default()
        };
        let metadata = metadata_from_opf(&opf, "Fallback", 1, 0);
        assert_eq!(metadata.tags.as_deref(), Some("标签A, 标签B"));
    }

    #[test]
    fn resolve_opf_cover_page_index_matches_manifest_cover_item() {
        let opf = ParsedOpfMetadata {
            cover_manifest_id: Some("cover_img".to_string()),
            ..Default::default()
        };
        let mut manifest = HashMap::new();
        manifest.insert(
            "cover_img".to_string(),
            ManifestItem {
                href: "images/2.png".to_string(),
                media_type: "image/png".to_string(),
                properties: Some("cover-image".to_string()),
            },
        );
        manifest.insert(
            "img1".to_string(),
            ManifestItem {
                href: "images/1.png".to_string(),
                media_type: "image/png".to_string(),
                properties: None,
            },
        );

        let page_paths = vec![
            "OEBPS/images/1.png".to_string(),
            "OEBPS/images/2.png".to_string(),
        ];
        let index = resolve_opf_cover_page_index(&opf, &manifest, "OEBPS/", &page_paths);
        assert_eq!(index, 1);
    }

    #[test]
    fn export_opf_splits_author_into_multiple_creators() {
        use crate::db::MetadataRecord;

        let metadata = MetadataRecord {
            title: "Title".to_string(),
            author: Some("Alice, Bob".to_string()),
            age_rating: Some("Teen".to_string()),
            ..Default::default()
        };

        let opf = build_content_opf(
            &metadata,
            "",
            "",
            "",
            "",
            "image/cover.png",
            "800x1200",
        );
        assert!(opf.contains("<dc:creator>Alice</dc:creator>"));
        assert!(opf.contains("<dc:creator>Bob</dc:creator>"));
        assert!(opf.contains(r#"<meta name="rating" content="Teen"/>"#));
        assert!(opf.contains(r#"<meta property="rendition:layout">pre-paginated</meta>"#));
        assert!(opf.contains(r#"<meta name="fixed-layout" content="true"/>"#));
    }

    #[test]
    fn epub_import_export_reimport_preserves_opf_metadata() {
        use crate::db::Library;
        use crate::export_epub::export_epub;
        use crate::import::import_epub;

        let app_data = temp_dir("roundtrip-app");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("roundtrip-epub");
        let epub = dir.join("source.epub");
        let png = png_bytes();

        let opf = format!(
            r#"<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="book-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="book-id">urn:uuid:test</dc:identifier>
    <dc:title>Roundtrip Title</dc:title>
    <dc:language>ja</dc:language>
    <dc:creator>Alice</dc:creator>
    <dc:creator>Bob</dc:creator>
    <dc:series>Series X</dc:series>
    <dc:number>5</dc:number>
    <dc:date>2023-07-04</dc:date>
    <dc:description>About this comic</dc:description>
    <meta name="series-count" content="20"/>
    <meta name="characters" content="Hero"/>
    <meta name="tags" content="Action"/>
    <meta name="rating" content="Everyone"/>
    <meta name="cover" content="img2"/>
  </metadata>
  <manifest>
    <item id="page1" href="page1.xhtml" media-type="application/xhtml+xml"/>
    <item id="img1" href="images/1.png" media-type="image/png"/>
    <item id="page2" href="page2.xhtml" media-type="application/xhtml+xml"/>
    <item id="img2" href="images/2.png" media-type="image/png" properties="cover-image"/>
  </manifest>
  <spine>
    <itemref idref="page1"/>
    <itemref idref="page2"/>
  </spine>
</package>
"#
        );

        write_epub_with_opf(&epub, &opf, &[
            ("page1.xhtml", "images/1.png", png.clone()),
            ("page2.xhtml", "images/2.png", png),
        ]);

        let imported = import_epub(&mut library, &epub.to_string_lossy()).expect("import");
        let metadata = library
            .get_project_metadata_inner(&imported.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "Roundtrip Title");
        assert_eq!(metadata.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(metadata.series.as_deref(), Some("Series X"));
        assert_eq!(metadata.number.as_deref(), Some("5"));
        assert_eq!(metadata.series_count.as_deref(), Some("20"));
        assert_eq!(metadata.published_date.as_deref(), Some("2023-07-04"));
        assert_eq!(metadata.language_iso.as_deref(), Some("ja"));
        assert_eq!(metadata.description.as_deref(), Some("About this comic"));
        assert_eq!(metadata.characters.as_deref(), Some("Hero"));
        assert_eq!(metadata.tags.as_deref(), Some("Action"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Everyone"));
        assert_eq!(metadata.cover_page_index, 1);

        let export_path = dir.join("exported.epub");
        export_epub(
            &library,
            &imported.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let exported_opf = read_zip_entry(&export_path, "content.opf");
        assert!(exported_opf.contains("<dc:creator>Alice</dc:creator>"));
        assert!(exported_opf.contains("<dc:creator>Bob</dc:creator>"));
        assert!(exported_opf.contains(r#"<meta name="rating" content="Everyone"/>"#));
        assert!(exported_opf.contains(r#"<meta property="rendition:layout">pre-paginated</meta>"#));

        let reimported = import_epub(&mut library, &export_path.to_string_lossy()).expect("reimport");
        let roundtrip = library
            .get_project_metadata_inner(&reimported.project_id)
            .expect("roundtrip metadata");
        assert_eq!(roundtrip.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(roundtrip.series.as_deref(), Some("Series X"));
        assert_eq!(roundtrip.published_date.as_deref(), Some("2023-07-04"));
        assert_eq!(roundtrip.age_rating.as_deref(), Some("Everyone"));
    }

    fn write_epub_with_opf(
        path: &Path,
        opf: &str,
        pages: &[(&str, &str, Vec<u8>)],
    ) {
        use std::io::Write;

        let file = File::create(path).expect("create epub");
        let mut zip = ZipWriter::new(file);
        let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
        let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

        zip.start_file("mimetype", stored).expect("mimetype");
        zip.write_all(EPUB_MIMETYPE.as_bytes())
            .expect("mimetype body");

        let container = r#"<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"#;
        zip.start_file("META-INF/container.xml", deflated)
            .expect("container");
        zip.write_all(container.as_bytes()).expect("container body");

        for (xhtml_name, image_href, image_bytes) in pages {
            let xhtml = format!(
                r#"<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml"><body><img src="{image_href}"/></body></html>
"#
            );
            zip.start_file(format!("OEBPS/{xhtml_name}"), deflated)
                .expect("xhtml");
            zip.write_all(xhtml.as_bytes()).expect("xhtml body");

            zip.start_file(format!("OEBPS/{image_href}"), deflated)
                .expect("image");
            zip.write_all(image_bytes).expect("image body");
        }

        zip.start_file("OEBPS/content.opf", deflated).expect("opf");
        zip.write_all(opf.as_bytes()).expect("opf body");
        zip.finish().expect("finish epub");
    }

    fn read_zip_entry(path: &Path, entry_path: &str) -> String {
        use std::io::Read;
        let file = File::open(path).expect("open epub");
        let mut archive = ZipArchive::new(file).expect("open archive");
        let mut entry = archive.by_name(entry_path).expect("entry");
        let mut text = String::new();
        entry.read_to_string(&mut text).expect("read entry");
        text
    }
}
