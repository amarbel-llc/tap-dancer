package tap

import (
	"bytes"
	"strings"
	"testing"
)

func TestConvertSinglePackageAllPass(t *testing.T) {
	jsonEvents := strings.Join([]string{
		`{"Action":"start","Package":"example.com/foo"}`,
		`{"Action":"run","Package":"example.com/foo","Test":"TestA"}`,
		`{"Action":"output","Package":"example.com/foo","Test":"TestA","Output":"=== RUN   TestA\n"}`,
		`{"Action":"pass","Package":"example.com/foo","Test":"TestA","Elapsed":0.001}`,
		`{"Action":"run","Package":"example.com/foo","Test":"TestB"}`,
		`{"Action":"output","Package":"example.com/foo","Test":"TestB","Output":"=== RUN   TestB\n"}`,
		`{"Action":"pass","Package":"example.com/foo","Test":"TestB","Elapsed":0.002}`,
		`{"Action":"output","Package":"example.com/foo","Output":"PASS\n"}`,
		`{"Action":"pass","Package":"example.com/foo","Elapsed":0.010}`,
	}, "\n") + "\n"

	var buf bytes.Buffer
	exitCode := ConvertGoTest(strings.NewReader(jsonEvents), &buf, false)

	if exitCode != 0 {
		t.Errorf("expected exit code 0, got %d", exitCode)
	}

	out := buf.String()

	// Validate the output is valid TAP-14
	reader := NewReader(strings.NewReader(out))
	summary := reader.Summary()
	if !summary.Valid {
		for _, d := range reader.Diagnostics() {
			t.Errorf("diagnostic: line %d: %s: %s", d.Line, d.Severity, d.Message)
		}
		t.Fatalf("output is not valid TAP-14:\n%s", out)
	}

	// Should have package as subtest with 2 inner tests
	if !strings.Contains(out, "# Subtest: example.com/foo") {
		t.Errorf("expected package subtest, got:\n%s", out)
	}
	if !strings.Contains(out, "ok 1 - example.com/foo") {
		t.Errorf("expected parent ok for package, got:\n%s", out)
	}
}
