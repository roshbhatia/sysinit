package session

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
)

func TestContaining(t *testing.T) {
	isolatedRoot(t)
	root := config.GetSessionsRoot()
	if err := os.MkdirAll(filepath.Join(root, "alpha", "repo", "deep"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, "beta"), 0o755); err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct {
		name string
		dir  string
		want string
	}{
		{"session root", filepath.Join(root, "alpha"), "alpha"},
		{"inside a repo", filepath.Join(root, "alpha", "repo"), "alpha"},
		{"deep inside a repo", filepath.Join(root, "alpha", "repo", "deep"), "alpha"},
		{"a sibling session", filepath.Join(root, "beta"), "beta"},
		{"the sessions root itself", root, ""},
		{"outside every session", t.TempDir(), ""},
		{"a name with no session", filepath.Join(root, "gamma"), ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			found, ok := Containing(tc.dir)
			if tc.want == "" {
				if ok {
					t.Fatalf("Containing(%q) = %q, want no session", tc.dir, found.Name)
				}
				return
			}
			if !ok {
				t.Fatalf("Containing(%q) found no session, want %q", tc.dir, tc.want)
			}
			if found.Name != tc.want {
				t.Fatalf("Containing(%q) = %q, want %q", tc.dir, found.Name, tc.want)
			}
		})
	}
}

// A repo inside a session is often a symlink to the original checkout. Resolving
// the working directory first would land outside the sessions root and report no
// session, so both the given path and the resolved one have to be tried.
func TestContainingThroughASymlinkedRepo(t *testing.T) {
	isolatedRoot(t)
	root := config.GetSessionsRoot()
	if err := os.MkdirAll(filepath.Join(root, "alpha"), 0o755); err != nil {
		t.Fatal(err)
	}
	outside := t.TempDir()
	link := filepath.Join(root, "alpha", "linked")
	if err := os.Symlink(outside, link); err != nil {
		t.Fatal(err)
	}

	found, ok := Containing(link)
	if !ok {
		t.Fatal("Containing found no session through the symlink")
	}
	if found.Name != "alpha" {
		t.Fatalf("Containing = %q, want alpha", found.Name)
	}
}
