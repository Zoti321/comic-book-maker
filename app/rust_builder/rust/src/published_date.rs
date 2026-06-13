//! Graded ISO publish dates stored in canonical metadata (`YYYY` / `YYYY-MM` / `YYYY-MM-DD`).

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PublishedDateParts {
    pub year: i32,
    pub month: Option<i32>,
    pub day: Option<i32>,
}

pub fn validate_published_date(value: &str) -> Result<(), String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return Err("published_date must not be empty".to_string());
    }

    parse_published_date(trimmed)
        .ok_or_else(|| format!("invalid published_date: {trimmed}"))
        .map(|_| ())
}

pub fn parse_published_date(value: &str) -> Option<PublishedDateParts> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return None;
    }

    if let Ok(year) = trimmed.parse::<i32>() {
        return validate_year(year).ok().map(|year| PublishedDateParts {
            year,
            month: None,
            day: None,
        });
    }

    let segments: Vec<&str> = trimmed.split('-').collect();
    match segments.as_slice() {
        [year, month] => {
            let year = year.parse().ok()?;
            let month = month.parse().ok()?;
            validate_year(year).ok()?;
            validate_month(month).ok()?;
            Some(PublishedDateParts {
                year,
                month: Some(month),
                day: None,
            })
        }
        [year, month, day] => {
            let year = year.parse().ok()?;
            let month = month.parse().ok()?;
            let day = day.parse().ok()?;
            validate_year(year).ok()?;
            validate_month(month).ok()?;
            validate_day(day).ok()?;
            Some(PublishedDateParts {
                year,
                month: Some(month),
                day: Some(day),
            })
        }
        _ => None,
    }
}

pub fn merge_year_month_day(
    year: Option<i32>,
    month: Option<i32>,
    day: Option<i32>,
) -> Option<String> {
    let year = year?;
    validate_year(year).ok()?;

    match (month, day) {
        (None, _) => Some(year.to_string()),
        (Some(month), None) => {
            validate_month(month).ok()?;
            Some(format!("{year:04}-{month:02}"))
        }
        (Some(month), Some(day)) => {
            validate_month(month).ok()?;
            validate_day(day).ok()?;
            Some(format!("{year:04}-{month:02}-{day:02}"))
        }
    }
}

pub fn published_date_year(value: &str) -> Option<i32> {
    parse_published_date(value).map(|parts| parts.year)
}

pub fn published_date_month(value: &str) -> Option<i32> {
    parse_published_date(value).and_then(|parts| parts.month)
}

pub fn published_date_day(value: &str) -> Option<i32> {
    parse_published_date(value).and_then(|parts| parts.day)
}

pub fn published_date_year_display(value: &str) -> String {
    published_date_year(value)
        .map(|year| year.to_string())
        .unwrap_or_default()
}

pub fn published_date_month_display(value: &str) -> String {
    published_date_month(value)
        .map(|month| month.to_string())
        .unwrap_or_default()
}

pub fn published_date_day_display(value: &str) -> String {
    published_date_day(value)
        .map(|day| day.to_string())
        .unwrap_or_default()
}

pub fn merge_published_date_form_fields(
    year: &str,
    month: &str,
    day: &str,
) -> Result<Option<String>, String> {
    let year_text = year.trim();
    let month_text = month.trim();
    let day_text = day.trim();

    if year_text.is_empty() && month_text.is_empty() && day_text.is_empty() {
        return Ok(None);
    }

    if year_text.is_empty() {
        return Err("published_date year is required when month or day is set".to_string());
    }
    if !month_text.is_empty() && day_text.is_empty() {
        // year-month only
    } else if month_text.is_empty() && !day_text.is_empty() {
        return Err("published_date month is required when day is set".to_string());
    }

    let year = year_text
        .parse::<i32>()
        .map_err(|_| "published_date year must be an integer".to_string())?;
    validate_year(year).map_err(|_| "published_date year must be between 1000 and 9999".to_string())?;

    let month = if month_text.is_empty() {
        None
    } else {
        let month = month_text
            .parse::<i32>()
            .map_err(|_| "published_date month must be an integer".to_string())?;
        validate_month(month)
            .map_err(|_| "published_date month must be between 1 and 12".to_string())?;
        Some(month)
    };

    let day = if day_text.is_empty() {
        None
    } else {
        let day = day_text
            .parse::<i32>()
            .map_err(|_| "published_date day must be an integer".to_string())?;
        validate_day(day)
            .map_err(|_| "published_date day must be between 1 and 31".to_string())?;
        Some(day)
    };

    merge_year_month_day(Some(year), month, day)
        .ok_or_else(|| "invalid published_date".to_string())
        .map(Some)
}

fn validate_year(year: i32) -> Result<i32, ()> {
    if (1000..=9999).contains(&year) {
        Ok(year)
    } else {
        Err(())
    }
}

fn validate_month(month: i32) -> Result<i32, ()> {
    if (1..=12).contains(&month) {
        Ok(month)
    } else {
        Err(())
    }
}

fn validate_day(day: i32) -> Result<i32, ()> {
    if (1..=31).contains(&day) {
        Ok(day)
    } else {
        Err(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn merge_year_month_day_supports_graded_iso() {
        assert_eq!(merge_year_month_day(Some(2024), None, None).as_deref(), Some("2024"));
        assert_eq!(
            merge_year_month_day(Some(2024), Some(5), None).as_deref(),
            Some("2024-05")
        );
        assert_eq!(
            merge_year_month_day(Some(2024), Some(5), Some(31)).as_deref(),
            Some("2024-05-31")
        );
        assert_eq!(merge_year_month_day(None, Some(5), None), None);
    }

    #[test]
    fn merge_published_date_form_fields_supports_graded_iso() {
        assert_eq!(
            merge_published_date_form_fields("2024", "", "").expect("year"),
            Some("2024".to_string())
        );
        assert_eq!(
            merge_published_date_form_fields("2024", "5", "").expect("year-month"),
            Some("2024-05".to_string())
        );
        assert_eq!(
            merge_published_date_form_fields("2024", "5", "31").expect("full"),
            Some("2024-05-31".to_string())
        );
        assert!(merge_published_date_form_fields("", "5", "").is_err());
        assert!(merge_published_date_form_fields("2024", "", "5").is_err());
    }

    #[test]
    fn parse_and_validate_published_date() {
        assert!(validate_published_date("2024").is_ok());
        assert!(validate_published_date("2024-05").is_ok());
        assert!(validate_published_date("2024-05-31").is_ok());
        assert!(validate_published_date("2024-13").is_err());
        assert!(validate_published_date("not-a-date").is_err());
    }
}
