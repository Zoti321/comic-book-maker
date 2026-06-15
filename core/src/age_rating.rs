//! 年龄分级预设与归一化/校验（ComicInfo / OPF 导入别名映射）。

pub const PRESETS: &[&str] = &[
    "Adults Only 18+",
    "Everyone",
    "R18+",
    "Unknown",
];

fn canonical_preset(value: &str) -> Option<&'static str> {
    let normalized = value.trim();
    PRESETS
        .iter()
        .find(|preset| preset.eq_ignore_ascii_case(normalized))
        .copied()
}

fn map_alias(value: &str) -> Option<&'static str> {
    match value.trim().to_ascii_lowercase().as_str() {
        "teen" | "pg" | "pg-13" | "everyone 10+" | "all ages" => Some("Everyone"),
        "mature" | "adult" | "adults" | "18+" => Some("Adults Only 18+"),
        "r18" | "r-18" => Some("R18+"),
        _ => None,
    }
}

/// 导入/加载时将外来值映射到预设；空白 → `None`；未识别 → `Unknown`。
pub fn normalize(raw: Option<&str>) -> Option<String> {
    match raw {
        None => None,
        Some(value) => {
            let trimmed = value.trim();
            if trimmed.is_empty() {
                return None;
            }
            if let Some(preset) = canonical_preset(trimmed) {
                return Some(preset.to_string());
            }
            if let Some(preset) = map_alias(trimmed) {
                return Some(preset.to_string());
            }
            Some("Unknown".to_string())
        }
    }
}

pub fn is_preset(value: &str) -> bool {
    canonical_preset(value).is_some()
}

/// 保存时校验：仅允许空白或预设列表内的值。
pub fn validate_for_save(raw: Option<&str>) -> Result<Option<String>, String> {
    let trimmed = raw.map(str::trim).filter(|value| !value.is_empty());
    match trimmed {
        None => Ok(None),
        Some(value) => canonical_preset(value)
            .map(|preset| Some(preset.to_string()))
            .ok_or_else(|| format!("invalid age_rating: {value}")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn normalize_maps_aliases() {
        assert_eq!(normalize(Some("Teen")).as_deref(), Some("Everyone"));
        assert_eq!(normalize(Some("Mature")).as_deref(), Some("Adults Only 18+"));
        assert_eq!(normalize(Some("r18")).as_deref(), Some("R18+"));
        assert_eq!(normalize(Some("everyone")).as_deref(), Some("Everyone"));
        assert_eq!(normalize(Some("bogus")).as_deref(), Some("Unknown"));
        assert_eq!(normalize(Some("  ")), None);
    }

    #[test]
    fn validate_rejects_non_preset() {
        assert!(validate_for_save(Some("Teen")).is_err());
        assert_eq!(
            validate_for_save(Some("Everyone")).expect("preset"),
            Some("Everyone".to_string())
        );
        assert_eq!(validate_for_save(None).expect("empty"), None);
    }
}
