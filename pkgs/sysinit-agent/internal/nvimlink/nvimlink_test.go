package nvimlink

import (
	"os"
	"path/filepath"
	"testing"
)

func TestServesRootAcceptsTheRootAndItsSubdirectories(t *testing.T) {
	root := t.TempDir()
	sub := filepath.Join(root, "src", "deep")
	if err := os.MkdirAll(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	for _, cwd := range []string{root, filepath.Join(root, "src"), sub} {
		if !servesRoot(cwd, root) {
			t.Errorf("an editor in %s should serve %s", cwd, root)
		}
	}
}

func TestServesRootRejectsASibling(t *testing.T) {
	base := t.TempDir()
	root := filepath.Join(base, "repo")
	other := filepath.Join(base, "repo-two")
	for _, dir := range []string{root, other} {
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
	}
	// The prefix test is why this case exists: "repo-two" starts with "repo".
	if servesRoot(other, root) {
		t.Fatalf("%s must not be treated as inside %s", other, root)
	}
	if servesRoot(base, root) {
		t.Fatalf("the parent %s must not be treated as inside %s", base, root)
	}
}

func TestServesRootComparesPhysicalPaths(t *testing.T) {
	base := t.TempDir()
	root := filepath.Join(base, "repo")
	if err := os.MkdirAll(root, 0o755); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(base, "link")
	if err := os.Symlink(root, link); err != nil {
		t.Skipf("cannot create the symlink: %v", err)
	}
	// git answers physically and the editor reports whatever route the user
	// took, so the two forms have to compare equal.
	if !servesRoot(link, root) {
		t.Fatal("an editor reached through a symlink should still serve the root")
	}
}

func TestSocketsReturnsNothingWhenNoEditorIsRunning(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("USER", "nobody-here")
	t.Setenv("XDG_RUNTIME_DIR", dir)
	t.Setenv("TMPDIR", dir)
	if got := Sockets(); len(got) != 0 {
		t.Fatalf("expected no sockets, got %v", got)
	}
}

func TestSocketsFindsTheNvimLayout(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("USER", "someone")
	t.Setenv("XDG_RUNTIME_DIR", dir)
	t.Setenv("TMPDIR", dir)
	// neovim's own layout: <run dir>/<random>/0.
	session := filepath.Join(dir, "nvim.someone", "XyIqNL")
	if err := os.MkdirAll(session, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(session, "0"), nil, 0o600); err != nil {
		t.Fatal(err)
	}
	got := Sockets()
	if len(got) != 1 {
		t.Fatalf("expected exactly one socket, got %v", got)
	}
}
