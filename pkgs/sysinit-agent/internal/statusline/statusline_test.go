package statusline

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestWholePercentDropsTheFraction(t *testing.T) {
	// A status line has no room for decimals and the number moves constantly.
	for in, want := range map[string]string{
		"42.7": "42",
		"42":   "42",
		"0.1":  "0",
		"":     "",
		"100":  "100",
	} {
		if got := wholePercent(in); got != want {
			t.Errorf("wholePercent(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestSeshySessionNamesOnlyDirectoriesInsideASession(t *testing.T) {
	t.Setenv("HOME", "/home/someone")
	root := "/home/someone/.local/state/seshy/sessions"
	if got := seshySession(root + "/zulu/repo/src"); got != "zulu" {
		t.Errorf("seshySession = %q, want zulu", got)
	}
	if got := seshySession(root + "/zulu"); got != "zulu" {
		t.Errorf("seshySession on the session root = %q, want zulu", got)
	}
	// A sibling that merely shares the prefix is not inside a session.
	for _, dir := range []string{"/home/someone/code/repo", root, root + "-other/zulu"} {
		if got := seshySession(dir); got != "" {
			t.Errorf("seshySession(%q) = %q, want empty", dir, got)
		}
	}
}

// openspecTree builds a repository with an openspec config and named changes.
func openspecTree(t *testing.T, changes ...string) string {
	t.Helper()
	root := t.TempDir()
	if err := os.MkdirAll(filepath.Join(root, "openspec", "changes"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "openspec", "config.yaml"), []byte("x\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	// Stamped apart so the ordering is by mtime rather than by creation order,
	// which is the property the picker relies on.
	base := time.Now().Add(-time.Hour)
	for i, name := range changes {
		dir := filepath.Join(root, "openspec", "changes", name)
		if err := os.MkdirAll(dir, 0o755); err != nil {
			t.Fatal(err)
		}
		stamp := base.Add(time.Duration(i) * time.Minute)
		if err := os.Chtimes(dir, stamp, stamp); err != nil {
			t.Fatal(err)
		}
	}
	return root
}

func TestOpenspecChangePicksTheMostRecentlyTouched(t *testing.T) {
	root := openspecTree(t, "oldest", "middle", "newest")
	change, extra := openspecChange(root)
	if change != "newest" {
		t.Errorf("openspecChange = %q, want newest", change)
	}
	if extra != 2 {
		t.Errorf("extra = %d, want 2", extra)
	}
}

func TestOpenspecChangeIgnoresTheArchive(t *testing.T) {
	root := openspecTree(t, "only", "archive")
	// The archive holds completed work. Counting it would keep the line
	// claiming a change that shipped months ago.
	change, extra := openspecChange(root)
	if change != "only" {
		t.Errorf("openspecChange = %q, want only", change)
	}
	if extra != 0 {
		t.Errorf("extra = %d, want 0", extra)
	}
}

func TestOpenspecChangeWalksUpToTheConfig(t *testing.T) {
	root := openspecTree(t, "active")
	deep := filepath.Join(root, "src", "nested", "deeper")
	if err := os.MkdirAll(deep, 0o755); err != nil {
		t.Fatal(err)
	}
	// The status line reports the directory claude is in, which is usually a
	// subdirectory rather than the repository root.
	if change, _ := openspecChange(deep); change != "active" {
		t.Errorf("openspecChange from a subdirectory = %q, want active", change)
	}
}

func TestOpenspecChangeIsEmptyWithoutAConfig(t *testing.T) {
	if change, extra := openspecChange(t.TempDir()); change != "" || extra != 0 {
		t.Errorf("openspecChange invented %q +%d outside an openspec repo", change, extra)
	}
	if change, _ := openspecChange(""); change != "" {
		t.Errorf("openspecChange on an empty path = %q", change)
	}
}

func TestOpenspecChangeIsEmptyWithNoChanges(t *testing.T) {
	root := openspecTree(t)
	if change, extra := openspecChange(root); change != "" || extra != 0 {
		t.Errorf("openspecChange = %q +%d with no changes present", change, extra)
	}
}

func TestMalformedPayloadRendersNothingRatherThanFailing(t *testing.T) {
	// The line re-renders continuously. An error would replace it entirely.
	for _, body := range []string{"not json", "", "[]"} {
		r, w, err := os.Pipe()
		if err != nil {
			t.Fatal(err)
		}
		w.WriteString(body)
		w.Close()
		old := os.Stdin
		os.Stdin = r
		code := Run(nil)
		os.Stdin = old
		if code != 0 {
			t.Errorf("Run returned %d for payload %q", code, body)
		}
	}
}
