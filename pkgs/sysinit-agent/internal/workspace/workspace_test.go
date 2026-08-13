package workspace

import (
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

// isolate points the state root at a temporary directory so `repo.Workspace` does
// not resolve a real seshy session, and returns a directory outside any git
// repository to build a workspace under.
func isolate(t *testing.T) string {
	t.Helper()
	root := t.TempDir()
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(root, "absent.json"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(root, "state"))
	t.Setenv("ZMX_SESSION", "")

	// macOS hands out /var/folders, a symlink to /private/var/folders. git reports
	// the resolved form, so an unresolved fixture path never prefix-matches a root.
	work, err := filepath.EvalSymlinks(root)
	if err != nil {
		t.Fatalf("resolve temp dir: %v", err)
	}
	return work
}

func git(t *testing.T, dir string, args ...string) {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(),
		"GIT_AUTHOR_NAME=t", "GIT_AUTHOR_EMAIL=t@t",
		"GIT_COMMITTER_NAME=t", "GIT_COMMITTER_EMAIL=t@t",
	)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git %s in %s: %v: %s", strings.Join(args, " "), dir, err, out)
	}
}

func write(t *testing.T, path, body string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

// captureStdout runs fn with os.Stdout replaced by a pipe and returns what it wrote.
func captureStdout(t *testing.T, fn func() int) string {
	t.Helper()
	read, write, err := os.Pipe()
	if err != nil {
		t.Fatalf("pipe: %v", err)
	}
	saved := os.Stdout
	os.Stdout = write
	code := fn()
	os.Stdout = saved
	if err := write.Close(); err != nil {
		t.Fatalf("close pipe: %v", err)
	}
	body, err := io.ReadAll(read)
	if err != nil {
		t.Fatalf("read pipe: %v", err)
	}
	if code != 0 {
		t.Fatalf("Run returned %d, want 0: %s", code, body)
	}
	return string(body)
}

// commitRepo initialises dir as a repository with one committed file.
func commitRepo(t *testing.T, dir string) {
	t.Helper()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", dir, err)
	}
	git(t, dir, "init", "-q", ".")
	write(t, filepath.Join(dir, "tracked.txt"), "base\n")
	git(t, dir, "add", "tracked.txt")
	git(t, dir, "commit", "-qm", "init")
}

// TestRootsFindsNestedRepositories is the case the editor got wrong: the workspace
// is itself a repository, so a single `rev-parse` answers with the outer root and
// the nested ones are never seen.
func TestRootsFindsNestedRepositories(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	commitRepo(t, filepath.Join(ws, "repoA"))
	commitRepo(t, filepath.Join(ws, "repoB"))

	got, err := Roots(ws)
	if err != nil {
		t.Fatalf("Roots: %v", err)
	}

	want := []string{ws, filepath.Join(ws, "repoA"), filepath.Join(ws, "repoB")}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("Roots = %v, want %v", got, want)
	}
}

func TestRootsEmptyWorkspaceIsNotAnError(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "plain")
	if err := os.MkdirAll(filepath.Join(ws, "a", "b"), 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}

	got, err := Roots(ws)
	if err != nil {
		t.Fatalf("Roots: %v", err)
	}
	if len(got) != 0 {
		t.Fatalf("Roots = %v, want none", got)
	}
}

// TestRootsStopsAtScanDepth records the bound rather than leaving it implied. A
// repository deeper than scanDepth is invisible, which is why callers report the
// count they found instead of claiming the set is complete.
func TestRootsStopsAtScanDepth(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	if err := os.MkdirAll(ws, 0o755); err != nil {
		t.Fatalf("mkdir: %v", err)
	}

	atDepth := filepath.Join(ws, "a", "b", "c", "d", "e")
	commitRepo(t, atDepth)
	tooDeep := filepath.Join(atDepth, "f", "g", "deep")
	commitRepo(t, tooDeep)

	got, err := Roots(ws)
	if err != nil {
		t.Fatalf("Roots: %v", err)
	}
	if !reflect.DeepEqual(got, []string{atDepth}) {
		t.Fatalf("Roots = %v, want only %v", got, atDepth)
	}
}

// TestChangesExcludesNestedRepositories is why the parent's answer is filtered by
// pathspec: without it the parent reports `repoA/` as one untracked directory and
// the same work is counted twice, under a directory name and under a file name.
func TestChangesExcludesNestedRepositories(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	repoA := filepath.Join(ws, "repoA")
	commitRepo(t, repoA)

	write(t, filepath.Join(ws, "tracked.txt"), "outer changed\n")
	write(t, filepath.Join(repoA, "tracked.txt"), "inner changed\n")

	roots, err := Roots(ws)
	if err != nil {
		t.Fatalf("Roots: %v", err)
	}
	groups := Changes(roots)

	if len(groups) != 2 {
		t.Fatalf("Changes returned %d groups, want 2: %+v", len(groups), groups)
	}
	if want := []string{filepath.Join(ws, "tracked.txt")}; !reflect.DeepEqual(groups[0].Files, want) {
		t.Fatalf("outer files = %v, want %v", groups[0].Files, want)
	}
	if want := []string{filepath.Join(repoA, "tracked.txt")}; !reflect.DeepEqual(groups[1].Files, want) {
		t.Fatalf("repoA files = %v, want %v", groups[1].Files, want)
	}
}

func TestChangesSkipsCleanRepositories(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	commitRepo(t, filepath.Join(ws, "clean"))
	dirty := filepath.Join(ws, "dirty")
	commitRepo(t, dirty)
	write(t, filepath.Join(dirty, "tracked.txt"), "changed\n")

	roots, err := Roots(ws)
	if err != nil {
		t.Fatalf("Roots: %v", err)
	}
	groups := Changes(roots)

	if len(groups) != 1 || groups[0].Root != dirty {
		t.Fatalf("Changes = %+v, want only %s", groups, dirty)
	}
}

// TestChangesReadsARenameRecord pins the `-z` layout.
func TestChangesReadsARenameRecord(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	git(t, ws, "mv", "tracked.txt", "renamed.txt")

	groups := Changes([]string{ws})
	if len(groups) != 1 {
		t.Fatalf("Changes = %+v, want one group", groups)
	}
	if want := []string{filepath.Join(ws, "renamed.txt")}; !reflect.DeepEqual(groups[0].Files, want) {
		t.Fatalf("files = %v, want %v", groups[0].Files, want)
	}
}

// TestChangesNamesUntrackedFiles proves `-uall` rather than the default: a caller
// opening a diff needs a file path, and `-unormal` would answer with the directory.
func TestChangesNamesUntrackedFiles(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	write(t, filepath.Join(ws, "fresh", "new.txt"), "new\n")

	groups := Changes([]string{ws})
	if len(groups) != 1 {
		t.Fatalf("Changes = %+v, want one group", groups)
	}
	if want := []string{filepath.Join(ws, "fresh", "new.txt")}; !reflect.DeepEqual(groups[0].Files, want) {
		t.Fatalf("files = %v, want %v", groups[0].Files, want)
	}
}

func TestRunRejectsAnUnusableDirectory(t *testing.T) {
	work := isolate(t)
	if code := Run([]string{"roots", filepath.Join(work, "absent")}); code != 2 {
		t.Fatalf("Run on a missing directory returned %d, want 2", code)
	}
	if code := Run([]string{"roots", "a", "b"}); code != 2 {
		t.Fatalf("Run with two directories returned %d, want 2", code)
	}
	if code := Run([]string{"nonsense"}); code != 2 {
		t.Fatalf("Run with an unknown action returned %d, want 2", code)
	}
	if code := Run(nil); code != 2 {
		t.Fatalf("Run with no action returned %d, want 2", code)
	}
}

func TestRunHelpExitsZero(t *testing.T) {
	if code := Run([]string{"--help"}); code != 0 {
		t.Fatalf("Run --help returned %d, want 0", code)
	}
}

// TestRunHealthReportsWhatItSees pins the field names, because the report is read
// by a shell with `grep` and by the editor's health check. Renaming a key here
// silently empties both.
func TestRunHealthReportsWhatItSees(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)
	commitRepo(t, filepath.Join(ws, "repoA"))
	write(t, filepath.Join(ws, "repoA", "tracked.txt"), "drift\n")

	out := captureStdout(t, func() int { return Run([]string{"health", ws}) })

	for _, want := range []string{
		"roots=2",
		"dirty_roots=1",
		"changed_files=1",
		"scan_depth=5",
		"dirty=" + filepath.Join(ws, "repoA") + " 1",
	} {
		if !strings.Contains(out, want) {
			t.Errorf("health output missing %q:\n%s", want, out)
		}
	}
}

// TestRunOnACleanWorkspaceExitsZero: an empty answer is an answer. A non-zero exit
// here would make every caller treat "nothing changed" as a failure.
func TestRunOnACleanWorkspaceExitsZero(t *testing.T) {
	work := isolate(t)
	ws := filepath.Join(work, "ws")
	commitRepo(t, ws)

	if code := Run([]string{"changes", ws}); code != 0 {
		t.Fatalf("Run changes on a clean workspace returned %d, want 0", code)
	}
}
