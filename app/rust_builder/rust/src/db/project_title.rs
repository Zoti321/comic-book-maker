//! Project display title helpers (`projects.title`).

use super::schema;

pub const LETTER_PROJECT_TITLE_PREFIX: &str = "项目";

/// Next available `项目A`…`项目Z` not present in `existing_titles`.
pub fn next_letter_project_title(existing_titles: &[String]) -> String {
    let occupied = occupied_letter_suffixes(existing_titles);
    for letter in b'A'..=b'Z' {
        if !occupied.contains(&(letter as char)) {
            return format!("{LETTER_PROJECT_TITLE_PREFIX}{}", letter as char);
        }
    }
    schema::DEFAULT_PROJECT_TITLE.to_string()
}

fn occupied_letter_suffixes(existing_titles: &[String]) -> Vec<char> {
    existing_titles
        .iter()
        .filter_map(|title| parse_letter_project_suffix(title))
        .collect()
}

fn parse_letter_project_suffix(title: &str) -> Option<char> {
    let rest = title.strip_prefix(LETTER_PROJECT_TITLE_PREFIX)?;
    if rest.len() != 1 {
        return None;
    }
    let letter = rest.chars().next()?;
    if letter.is_ascii_uppercase() {
        Some(letter)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn picks_first_available_letter_suffix() {
        assert_eq!(
            next_letter_project_title(&[]),
            "项目A",
        );
        assert_eq!(
            next_letter_project_title(&["项目A".to_string()]),
            "项目B",
        );
        assert_eq!(
            next_letter_project_title(&["项目A".to_string(), "项目C".to_string()]),
            "项目B",
        );
    }

    #[test]
    fn ignores_non_matching_titles() {
        assert_eq!(
            next_letter_project_title(&["我的漫画".to_string(), "项目AA".to_string()]),
            "项目A",
        );
    }

    #[test]
    fn falls_back_when_a_through_z_taken() {
        let taken: Vec<String> = (b'A'..=b'Z')
            .map(|letter| format!("{LETTER_PROJECT_TITLE_PREFIX}{}", letter as char))
            .collect();
        assert_eq!(
            next_letter_project_title(&taken),
            schema::DEFAULT_PROJECT_TITLE,
        );
    }
}
