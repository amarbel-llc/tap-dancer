use std::io::{self, Write};

pub struct TestResult {
    pub number: usize,
    pub name: String,
    pub ok: bool,
    pub error_message: Option<String>,
    pub exit_code: Option<i32>,
    pub output: Option<String>,
}

pub struct TapWriter {
    counter: usize,
}

impl TapWriter {
    pub fn new() -> Self {
        Self { counter: 0 }
    }

    pub fn next(&mut self) -> usize {
        self.counter += 1;
        self.counter
    }

    pub fn count(&self) -> usize {
        self.counter
    }
}

pub fn write_version(w: &mut impl Write) -> io::Result<()> {
    todo!()
}

pub fn write_plan(w: &mut impl Write, count: usize) -> io::Result<()> {
    todo!()
}

pub fn write_test_point(w: &mut impl Write, result: &TestResult) -> io::Result<()> {
    todo!()
}

pub fn write_bail_out(w: &mut impl Write, reason: &str) -> io::Result<()> {
    todo!()
}

pub fn write_comment(w: &mut impl Write, text: &str) -> io::Result<()> {
    todo!()
}

pub fn write_skip(w: &mut impl Write, num: usize, desc: &str, reason: &str) -> io::Result<()> {
    todo!()
}

pub fn write_todo(w: &mut impl Write, num: usize, desc: &str, reason: &str) -> io::Result<()> {
    todo!()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn version_line() {
        let mut buf = Vec::new();
        write_version(&mut buf).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "TAP version 14\n");
    }

    #[test]
    fn plan_line() {
        let mut buf = Vec::new();
        write_plan(&mut buf, 3).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "1..3\n");
    }

    #[test]
    fn plan_zero() {
        let mut buf = Vec::new();
        write_plan(&mut buf, 0).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "1..0\n");
    }

    #[test]
    fn passing_test_point() {
        let mut buf = Vec::new();
        let result = TestResult {
            number: 1,
            name: "build".into(),
            ok: true,
            error_message: None,
            exit_code: None,
            output: None,
        };
        write_test_point(&mut buf, &result).unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "ok 1 - build\n");
    }

    #[test]
    fn passing_test_point_with_output() {
        let mut buf = Vec::new();
        let result = TestResult {
            number: 1,
            name: "build".into(),
            ok: true,
            error_message: None,
            exit_code: None,
            output: Some("building\n".into()),
        };
        write_test_point(&mut buf, &result).unwrap();
        let out = String::from_utf8(buf).unwrap();
        assert!(out.contains("ok 1 - build\n"));
        assert!(out.contains("  ---\n"));
        assert!(out.contains("  output: |\n"));
        assert!(out.contains("    building\n"));
        assert!(out.contains("  ...\n"));
    }

    #[test]
    fn failing_test_point() {
        let mut buf = Vec::new();
        let result = TestResult {
            number: 2,
            name: "test".into(),
            ok: false,
            error_message: Some("something failed".into()),
            exit_code: Some(1),
            output: None,
        };
        write_test_point(&mut buf, &result).unwrap();
        let out = String::from_utf8(buf).unwrap();
        assert!(out.contains("not ok 2 - test\n"));
        assert!(out.contains("  ---\n"));
        assert!(out.contains("  message: \"something failed\"\n"));
        assert!(out.contains("  severity: fail\n"));
        assert!(out.contains("  exitcode: 1\n"));
        assert!(out.contains("  ...\n"));
    }

    #[test]
    fn failing_test_point_with_multiline_output() {
        let mut buf = Vec::new();
        let result = TestResult {
            number: 1,
            name: "multi".into(),
            ok: false,
            error_message: None,
            exit_code: None,
            output: Some("line one\nline two".into()),
        };
        write_test_point(&mut buf, &result).unwrap();
        let out = String::from_utf8(buf).unwrap();
        assert!(out.contains("  output: |\n"));
        assert!(out.contains("    line one\n"));
        assert!(out.contains("    line two\n"));
    }

    #[test]
    fn bail_out() {
        let mut buf = Vec::new();
        write_bail_out(&mut buf, "database down").unwrap();
        assert_eq!(
            String::from_utf8(buf).unwrap(),
            "Bail out! database down\n"
        );
    }

    #[test]
    fn comment() {
        let mut buf = Vec::new();
        write_comment(&mut buf, "a note").unwrap();
        assert_eq!(String::from_utf8(buf).unwrap(), "# a note\n");
    }

    #[test]
    fn skip_directive() {
        let mut buf = Vec::new();
        write_skip(&mut buf, 3, "optional feature", "not supported").unwrap();
        assert_eq!(
            String::from_utf8(buf).unwrap(),
            "ok 3 - optional feature # SKIP not supported\n"
        );
    }

    #[test]
    fn todo_directive() {
        let mut buf = Vec::new();
        write_todo(&mut buf, 4, "future work", "not implemented").unwrap();
        assert_eq!(
            String::from_utf8(buf).unwrap(),
            "not ok 4 - future work # TODO not implemented\n"
        );
    }

    #[test]
    fn tap_writer_counter() {
        let mut tw = TapWriter::new();
        assert_eq!(tw.count(), 0);
        assert_eq!(tw.next(), 1);
        assert_eq!(tw.next(), 2);
        assert_eq!(tw.count(), 2);
    }
}
