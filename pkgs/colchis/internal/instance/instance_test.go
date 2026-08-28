package instance

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCandidateUsesPhysicalScope(t *testing.T) {
	real := t.TempDir()
	physical, err := filepath.EvalSymlinks(real)
	if err != nil {
		t.Fatalf("EvalSymlinks() returned %v", err)
	}
	link := filepath.Join(t.TempDir(), "scope")
	if err := os.Symlink(real, link); err != nil {
		t.Fatalf("Symlink() returned %v", err)
	}
	record, _, err := Candidate(link)
	if err != nil {
		t.Fatalf("Candidate() returned %v", err)
	}
	if record.Scope != physical {
		t.Fatalf("scope = %q, want %q", record.Scope, physical)
	}
}

func TestContainsHonorsPathBoundaries(t *testing.T) {
	root := filepath.Join(t.TempDir(), "repo")
	for _, test := range []struct {
		path string
		want bool
	}{
		{path: root, want: true},
		{path: filepath.Join(root, "nested"), want: true},
		{path: root + "-other", want: false},
	} {
		if got := Contains(root, test.path); got != test.want {
			t.Fatalf("Contains(%q, %q) = %t, want %t", root, test.path, got, test.want)
		}
	}
}
