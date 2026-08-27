package lintgate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

func writeTestFile(t *testing.T, name, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

func TestGofmtUsesOutputAsFailure(t *testing.T) {
	one := byExtension[".go"][0]
	if !one.byOutput {
		t.Fatal("gofmt is not marked as an output checker")
	}
	clean := writeTestFile(t, "clean.go", "package sample\n\nfunc Exported() {}\n")
	if report := check(one, clean); report != "" {
		t.Fatalf("clean file report = %q", report)
	}
	messy := writeTestFile(t, "messy.go", "package sample\nfunc  Exported()  {}\n")
	if report := check(one, messy); !strings.Contains(report, "messy.go") {
		t.Fatalf("messy file report = %q", report)
	}
}

func TestInspectReportsAndSkips(t *testing.T) {
	messy := writeTestFile(t, "messy.go", "package sample\nfunc  Exported()  {}\n")
	if outcome := Inspect(messy); outcome.Kind != hookfmt.Context || !strings.Contains(outcome.Message, "messy.go") {
		t.Fatalf("messy file outcome = %+v", outcome)
	}
	if outcome := Inspect(""); outcome.Kind != hookfmt.Pass {
		t.Fatalf("empty path outcome = %+v", outcome)
	}
	if report := check(checker{binary: "missing-linter-for-test"}, messy); report != "" {
		t.Fatalf("missing checker report = %q", report)
	}
}

func TestClipAndColour(t *testing.T) {
	long := strings.Repeat("x", widest+100)
	if clipped := clip(long); !strings.HasSuffix(clipped, "[the rest is cut]") {
		t.Fatalf("long report was not clipped: %d bytes", len(clipped))
	}
	if got := colour.ReplaceAllString("\x1b[31mError:\x1b[0m x", ""); got != "Error: x" {
		t.Fatalf("colour-stripped output = %q", got)
	}
}
