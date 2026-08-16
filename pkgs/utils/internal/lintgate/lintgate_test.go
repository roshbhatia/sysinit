package lintgate

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func write(t *testing.T, name, body string) string {
	t.Helper()
	path := filepath.Join(t.TempDir(), name)
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return path
}

// gofmt exits 0 whether or not the file is formatted, so only its output tells.
func TestByOutputReadsStdout(t *testing.T) {
	one := byExtension[".go"][0]
	if !one.byOutput {
		t.Fatal("gofmt reports on stdout")
	}

	clean := write(t, "clean.go", "package a\n\nfunc B() {}\n")
	if report := check(one, clean); report != "" {
		t.Fatalf("a formatted file should say nothing, got %q", report)
	}

	messy := write(t, "messy.go", "package a\nfunc  B()  {}\n")
	if report := check(one, messy); !strings.Contains(report, "messy.go") {
		t.Fatalf("an unformatted file should name itself, got %q", report)
	}
}

func TestExitCodeCheckerStaysQuietOnACleanFile(t *testing.T) {
	one := byExtension[".sh"][0]
	clean := write(t, "clean.sh", "#!/usr/bin/env bash\necho hello\n")
	if report := check(one, clean); report != "" {
		t.Fatalf("a clean script should say nothing, got %q", report)
	}
}

// A checker that is not installed is not a finding.
func TestAMissingBinarySaysNothing(t *testing.T) {
	path := write(t, "a.txt", "hello\n")
	if report := check(checker{binary: "no-such-linter-anywhere"}, path); report != "" {
		t.Fatalf("got %q", report)
	}
}

func TestEveryCheckerCarriesABinary(t *testing.T) {
	for ext, list := range byExtension {
		if len(list) == 0 {
			t.Errorf("%s maps to no checker", ext)
		}
		for _, one := range list {
			if one.binary == "" {
				t.Errorf("%s has a checker with no binary", ext)
			}
		}
	}
}

func TestClip(t *testing.T) {
	if got := clip("short"); got != "short" {
		t.Fatalf("got %q", got)
	}
	long := strings.Repeat("x", widest+100)
	got := clip(long)
	if len(got) <= widest || !strings.HasSuffix(got, "[the rest is cut]") {
		t.Fatalf("a long report should be cut, got %d bytes", len(got))
	}
}

func TestColourIsStripped(t *testing.T) {
	if got := colour.ReplaceAllString("\x1b[31mError:\x1b[0m x", ""); got != "Error: x" {
		t.Fatalf("got %q", got)
	}
}
