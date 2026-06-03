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
use crate::page_image::normalize_extension;

pub const EPUB_MIMETYPE: &str = "application/epub+zip";

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParsedOpfMetadata {
    pub title: Option<String>,
    pub creator: Option<String>,
    pub publisher: Option<String>,
    pub description: Option<String>,
    pub language: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct ManifestItem {
    href: String,
    media_type: String,
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

    Ok((page_paths, metadata, comicinfo_xml, opf_metadata_xml))
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

fn manifest_attrs(event: &quick_xml::events::BytesStart<'_>) -> Option<(String, String, String)> {
    let mut id = None;
    let mut href = None;
    let mut media_type = None;
    for attr in event.attributes().flatten() {
        match attr.key.as_ref() {
            b"id" => id = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            b"href" => href = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            b"media-type" => media_type = Some(String::from_utf8_lossy(&attr.value).into_owned()),
            _ => {}
        }
    }
    match (id, href, media_type) {
        (Some(id), Some(href), Some(media_type)) => Some((id, href, media_type)),
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
                        if let Some((id, href, media_type)) = manifest_attrs(&event) {
                            manifest.insert(id, ManifestItem { href, media_type });
                        }
                    }
                    "itemref" if in_spine => {
                        if let Some(idref) = itemref_id(&event) {
                            spine_ids.push(idref);
                        }
                    }
                    tag if in_metadata => {
                        let dc_tag = tag.strip_prefix("dc:").unwrap_or(&tag);
                        if matches!(
                            dc_tag,
                            "title" | "creator" | "publisher" | "description" | "language"
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
                            "creator" => metadata.creator = Some(value.to_string()),
                            "publisher" => metadata.publisher = Some(value.to_string()),
                            "description" => metadata.description = Some(value.to_string()),
                            "language" => metadata.language = Some(value.to_string()),
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

pub fn metadata_from_opf(
    opf: &ParsedOpfMetadata,
    fallback_title: &str,
    page_count: i32,
) -> crate::db::MetadataRecord {
    let title = opf
        .title
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(fallback_title)
        .trim()
        .to_string();

    crate::db::MetadataRecord {
        title,
        writer: opf.creator.clone(),
        publisher: opf.publisher.clone(),
        summary: opf.description.clone(),
        language_iso: opf.language.clone(),
        page_count,
        ..Default::default()
    }
}

pub(crate) fn write_epub(
    destination: &Path,
    metadata: &crate::db::MetadataRecord,
    pages: &[crate::db::PageRecord],
) -> Result<(), String> {
    if pages.is_empty() {
        return Err("Export 需要至少一页".to_string());
    }

    if let Some(parent) = destination.parent() {
        if !parent.as_os_str().is_empty() {
            std::fs::create_dir_all(parent)
                .map_err(|error| format!("create export directory: {error}"))?;
        }
    }

    let file = File::create(destination)
        .map_err(|error| format!("create EPUB file {}: {error}", destination.display()))?;
    let mut zip = ZipWriter::new(file);

    let stored = SimpleFileOptions::default().compression_method(CompressionMethod::Stored);
    let deflated = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

    zip.start_file("mimetype", stored)
        .map_err(|error| format!("write mimetype: {error}"))?;
    zip.write_all(EPUB_MIMETYPE.as_bytes())
        .map_err(|error| format!("write mimetype content: {error}"))?;

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
        let extension = normalize_extension(Path::new(&page.asset_path))?;
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

        zip.start_file(&image_href, deflated)
            .map_err(|error| format!("write image {image_href}: {error}"))?;
        let mut source = File::open(&page.absolute_path)
            .map_err(|error| format!("open page asset {}: {error}", page.absolute_path))?;
        std::io::copy(&mut source, &mut zip)
            .map_err(|error| format!("copy page into EPUB: {error}"))?;
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
        .ok_or_else(|| "Export 需要封面页".to_string())?;
    let original_resolution = page_image_resolution(&cover_page.absolute_path)?;

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
        .map_err(|error| format!("finalize EPUB: {error}"))?;
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
    <dc:identifier id="{}"{}>{}</dc:identifier>
    <dc:title>{}</dc:title>
    <dc:language>{}</dc:language>
"#,
        escape_xml(&identifier_id),
        escape_xml(&identifier_id),
        identifier_scheme
            .as_deref()
            .map(|s| format!(" opf:scheme=\"{}\"", escape_xml(s)))
            .unwrap_or_default(),
        escape_xml(&identifier_value),
        escape_xml(&metadata.title),
        escape_xml(language),
    );

    append_dc_element(&mut opf, "creator", metadata.writer.as_deref());
    append_dc_element(&mut opf, "publisher", metadata.publisher.as_deref());
    append_dc_element(&mut opf, "description", metadata.summary.as_deref());
    append_dc_element(&mut opf, "series", metadata.series.as_deref());
    append_dc_element(&mut opf, "number", metadata.issue_number.as_deref());
    append_dc_element(&mut opf, "source", metadata.web.as_deref());
    append_meta_name_content(&mut opf, "comic:volume", metadata.volume.as_deref());
    opf.push_str(r#"    <meta name="cover" content="cover_img"/>"#);
    opf.push('\n');
    append_comic_rendition_metadata(&mut opf, original_resolution);

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

fn opf_identifier_id(metadata: &crate::db::MetadataRecord) -> String {
    if metadata
        .gtin
        .as_deref()
        .is_some_and(|v| !v.trim().is_empty())
    {
        "KSBN".to_string()
    } else {
        "book-id".to_string()
    }
}

fn opf_identifier_scheme(metadata: &crate::db::MetadataRecord) -> Option<String> {
    if metadata
        .gtin
        .as_deref()
        .is_some_and(|v| !v.trim().is_empty())
    {
        Some("KSBN".to_string())
    } else {
        None
    }
}

fn opf_identifier_value(metadata: &crate::db::MetadataRecord) -> &str {
    metadata
        .gtin
        .as_deref()
        .filter(|v| !v.trim().is_empty())
        .unwrap_or(metadata.title.as_str())
}

fn append_dc_element(opf: &mut String, tag: &str, value: Option<&str>) {
    let Some(value) = value.map(str::trim).filter(|v| !v.is_empty()) else {
        return;
    };
    opf.push_str(&format!("    <dc:{tag}>{}</dc:{tag}>\n", escape_xml(value)));
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
) -> Result<(), String> {
    zip.start_file(path, options)
        .map_err(|error| format!("write {path}: {error}"))?;
    zip.write_all(content.as_bytes())
        .map_err(|error| format!("write {path} content: {error}"))?;
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

        let (paths, metadata, _, _) = scan_epub_page_paths(&epub).expect("scan");
        assert_eq!(paths, vec!["OEBPS/images/1.png", "OEBPS/images/2.png"]);
        assert_eq!(metadata.title.as_deref(), Some("Spine Order"));
        assert_eq!(metadata.creator.as_deref(), Some("Test Author"));
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

        let (paths, metadata, _, opf_section) = scan_epub_page_paths(&epub).expect("scan");
        assert_eq!(paths, vec!["OEBPS/image/page1.png"]);
        assert_eq!(metadata.title.as_deref(), Some("Relative"));
        assert!(opf_section.is_some());
    }
}
