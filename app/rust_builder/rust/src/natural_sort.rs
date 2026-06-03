//! Natural sort for archive entry paths (1, 2, 10 not 1, 10, 2).

pub fn compare(a: &str, b: &str) -> std::cmp::Ordering {
    natord::compare(a, b)
}

pub fn sort_paths(paths: &mut [String]) {
    paths.sort_by(|a, b| compare(a, b));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sorts_numeric_segments() {
        let mut paths = vec![
            "10.jpg".to_string(),
            "2.jpg".to_string(),
            "1.jpg".to_string(),
        ];
        sort_paths(&mut paths);
        assert_eq!(paths, vec!["1.jpg", "2.jpg", "10.jpg"]);
    }
}
