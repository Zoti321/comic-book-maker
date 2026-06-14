//! [Page](CONTEXT.md) 序列与 [Cover](CONTEXT.md) 索引的聚合快照。

use super::library::Library;
use super::records::PageRecord;

#[derive(Debug, Clone)]
pub(crate) struct PageStructureSnapshot {
    pub pages: Vec<PageRecord>,
    pub cover_page_index: i32,
}

impl Library {
    pub(crate) fn page_structure_inner(&self, project_id: &str) -> Result<PageStructureSnapshot, String> {
        Ok(PageStructureSnapshot {
            pages: self.list_pages_inner(project_id)?,
            cover_page_index: self.load_cover_page_index(project_id)?,
        })
    }
}
