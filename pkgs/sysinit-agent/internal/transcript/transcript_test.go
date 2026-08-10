package transcript

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// setup points the paths resolver at a temporary directory and makes the
func setup(t *testing.T) string {
	t.Helper()
	published := t.TempDir()
	body, err := json.Marshal(map[string]any{
		"version": 1,
		"paths":   map[string]string{"agentTranscripts": published},
	})
	if err != nil {
		t.Fatal(err)
	}
	manifest := filepath.Join(t.TempDir(), "paths.json")
	if err := os.WriteFile(manifest, body, 0o644); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SYSINIT_PATHS_MANIFEST", manifest)
	// The session-id fallback globs under the home directory. Point it at an
	t.Setenv("HOME", t.TempDir())

	previous := rootOf
	rootOf = func(dir string) (string, error) { return dir, nil }
	t.Cleanup(func() { rootOf = previous })

	return published
}

// run feeds a payload to the command the way a hook does.
func run(t *testing.T, harness, body string) int {
	t.Helper()
	stdin, err := os.CreateTemp(t.TempDir(), "payload-*")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := stdin.WriteString(body); err != nil {
		t.Fatal(err)
	}
	if _, err := stdin.Seek(0, 0); err != nil {
		t.Fatal(err)
	}
	previous := os.Stdin
	os.Stdin = stdin
	defer func() { os.Stdin = previous }()
	return Run([]string{harness})
}

func TestPublishesALinkNotACopy(t *testing.T) {
	published := setup(t)
	native := filepath.Join(t.TempDir(), "sess.jsonl")
	if err := os.WriteFile(native, []byte("{\"a\":1}\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	if code := run(t, "claude", `{"session_id":"sess","transcript_path":"`+native+`","cwd":"/repo/here"}`); code != 0 {
		t.Fatalf("exit code %d, want 0", code)
	}

	link := filepath.Join(published, "claude", "sess.jsonl")
	info, err := os.Lstat(link)
	if err != nil {
		t.Fatal(err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("the published transcript is a copy, so it stops following a live session")
	}
	target, err := os.Readlink(link)
	if err != nil {
		t.Fatal(err)
	}
	if target != native {
		t.Errorf("link points at %q, want %q", target, native)
	}

	// A link is only useful while it follows. Appending to the harness's file
	handle, err := os.OpenFile(native, os.O_APPEND|os.O_WRONLY, 0o644)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := handle.WriteString("{\"a\":2}\n"); err != nil {
		t.Fatal(err)
	}
	handle.Close()
	through, err := os.ReadFile(link)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(through), `"a":2`) {
		t.Errorf("an append did not reach the published name: %q", through)
	}
}

func TestSidecarMakesADirectoryEnoughToFindIt(t *testing.T) {
	setup(t)
	native := filepath.Join(t.TempDir(), "sess.jsonl")
	if err := os.WriteFile(native, []byte("x\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	run(t, "claude", `{"session_id":"sess","transcript_path":"`+native+`","cwd":"/repo/here"}`)

	got, ok := FindByWorktree("claude", "/repo/here")
	if !ok || got != "sess" {
		t.Errorf("FindByWorktree = %q, %v; want \"sess\", true", got, ok)
	}
	// A trailing slash is the same directory.
	if got, ok := FindByWorktree("claude", "/repo/here/"); !ok || got != "sess" {
		t.Errorf("a trailing slash lost the session: %q, %v", got, ok)
	}
	// The same, recorded with a trailing slash. Trimming only the query would
	run(t, "claude", `{"session_id":"slashy","transcript_path":"`+native+`","cwd":"/repo/slashy/"}`)
	if got, ok := FindByWorktree("claude", "/repo/slashy"); !ok || got != "slashy" {
		t.Errorf("a worktree recorded with a trailing slash was not found: %q, %v", got, ok)
	}

	if _, ok := FindByWorktree("claude", "/repo/elsewhere"); ok {
		t.Error("another worktree's transcript was returned")
	}
	if _, ok := FindByWorktree("codex", "/repo/here"); ok {
		t.Error("another harness's transcript was returned")
	}
}

func TestTheNewestSessionInADirectoryWins(t *testing.T) {
	published := setup(t)
	native := filepath.Join(t.TempDir(), "n.jsonl")
	if err := os.WriteFile(native, []byte("x\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	// Two sessions in one worktree is the ordinary case, not an oddity: every
	run(t, "claude", `{"session_id":"zzz-newest","transcript_path":"`+native+`","cwd":"/repo/here"}`)
	run(t, "claude", `{"session_id":"aaa-oldest","transcript_path":"`+native+`","cwd":"/repo/here"}`)

	// Stamp them apart rather than relying on both landing in the same second.
	stamp := func(session string, updated int64) {
		path := filepath.Join(published, "claude", session+".json")
		body, err := os.ReadFile(path)
		if err != nil {
			t.Fatal(err)
		}
		var record sidecar
		if err := json.Unmarshal(body, &record); err != nil {
			t.Fatal(err)
		}
		record.Updated = updated
		out, err := json.Marshal(record)
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, out, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	stamp("aaa-oldest", 100)
	stamp("zzz-newest", 200)

	if got, _ := FindByWorktree("claude", "/repo/here"); got != "zzz-newest" {
		t.Errorf("FindByWorktree = %q, want \"zzz-newest\"", got)
	}
}

func TestARepublishFollowsTheSessionToItsNewFile(t *testing.T) {
	// `--resume` moves a session's file. A link that is merely present is not a
	published := setup(t)
	first := filepath.Join(t.TempDir(), "one.jsonl")
	second := filepath.Join(t.TempDir(), "two.jsonl")
	for _, path := range []string{first, second} {
		if err := os.WriteFile(path, []byte("x\n"), 0o644); err != nil {
			t.Fatal(err)
		}
	}

	run(t, "claude", `{"session_id":"sess","transcript_path":"`+first+`","cwd":"/repo/here"}`)
	run(t, "claude", `{"session_id":"sess","transcript_path":"`+second+`","cwd":"/repo/here"}`)

	target, err := os.Readlink(filepath.Join(published, "claude", "sess.jsonl"))
	if err != nil {
		t.Fatal(err)
	}
	if target != second {
		t.Errorf("link points at %q, want the new file %q", target, second)
	}
}

func TestAnUnusablePayloadIsASilentNoOp(t *testing.T) {
	// A hook that blocks a prompt to report a bookkeeping problem is worse than
	published := setup(t)
	native := filepath.Join(t.TempDir(), "sess.jsonl")
	if err := os.WriteFile(native, []byte("x\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	cases := map[string]string{
		"empty object":          `{}`,
		"not json":              `not json at all`,
		"no session id":         `{"transcript_path":"` + native + `"}`,
		"session id escapes":    `{"session_id":"../escape","transcript_path":"` + native + `"}`,
		"session id is dotdot":  `{"session_id":"..","transcript_path":"` + native + `"}`,
		"transcript is a dir":   `{"session_id":"sess","transcript_path":"` + t.TempDir() + `"}`,
		"transcript is missing": `{"session_id":"sess","transcript_path":"/no/such/file.jsonl"}`,
		"session id is unknown": `{"session_id":"nothing-matches-this"}`,
	}
	for name, body := range cases {
		if code := run(t, "claude", body); code != 0 {
			t.Errorf("%s: exit code %d, want 0", name, code)
		}
	}

	entries, err := os.ReadDir(filepath.Join(published, "claude"))
	if err == nil && len(entries) != 0 {
		t.Errorf("an unusable payload published %d files", len(entries))
	}
}

func TestAHarnessNameIsNeverAPath(t *testing.T) {
	published := setup(t)
	native := filepath.Join(t.TempDir(), "sess.jsonl")
	if err := os.WriteFile(native, []byte("x\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if code := run(t, "../escape", `{"session_id":"sess","transcript_path":"`+native+`"}`); code != 0 {
		t.Errorf("exit code %d, want 0", code)
	}
	if _, err := os.Stat(filepath.Join(filepath.Dir(published), "escape")); err == nil {
		t.Error("a harness name escaped the transcripts directory")
	}
}
