package editevent

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
)

func TestRecordDeltaCarriesThePrompt(t *testing.T) {
	tree := checkout(t, "one\n")
	savePrompt(tree, "claude", "sess-1", "make it two\nand keep it short")
	write(t, tree, "two\n")

	sha := recordDelta(tree, deltaMeta{
		harness: "claude",
		session: "sess-1",
		kind:    "write",
		file:    filepath.Join(tree, "a.txt"),
		prompt:  loadPrompt(tree),
	})
	if sha == "" {
		t.Fatal("recordDelta returned no commit")
	}

	if subject := describe(t, tree, sha, "%s"); subject != "make it two" {
		t.Errorf("subject is %q, want the first prompt line", subject)
	}
	body := describe(t, tree, sha, "%B")
	for _, want := range []string{"and keep it short", "Sysinit-Session: sess-1", "Sysinit-Kind: write"} {
		if !strings.Contains(body, want) {
			t.Errorf("body is missing %q:\n%s", want, body)
		}
	}
}

// The first delta of a file must diff against the checkout's HEAD, not against nothing.
func TestRecordDeltaSeedsFromTheCheckout(t *testing.T) {
	tree := checkout(t, "one\n")
	write(t, tree, "two\n")

	sha := recordDelta(tree, deltaMeta{harness: "codex", kind: "edit", file: filepath.Join(tree, "a.txt")})
	if sha == "" {
		t.Fatal("recordDelta returned no commit")
	}

	patch := show(t, tree, sha)
	if !strings.Contains(patch, "-one") || !strings.Contains(patch, "+two") {
		t.Errorf("the delta is not a one-line change:\n%s", patch)
	}
	if subject := describe(t, tree, sha, "%s"); subject != "edit a.txt" {
		t.Errorf("subject is %q, want the kind and the file", subject)
	}
}

func TestRecordDeltaSkipsAnUnchangedWrite(t *testing.T) {
	tree := checkout(t, "one\n")
	file := filepath.Join(tree, "a.txt")
	write(t, tree, "two\n")

	if sha := recordDelta(tree, deltaMeta{harness: "claude", kind: "write", file: file}); sha == "" {
		t.Fatal("the first change must record a delta")
	}
	if sha := recordDelta(tree, deltaMeta{harness: "claude", kind: "write", file: file}); sha != "" {
		t.Errorf("a write that changed nothing recorded delta %s", sha)
	}
}

func TestRecordDeltaIgnoresAFileOutsideTheTree(t *testing.T) {
	tree := checkout(t, "one\n")
	outside := filepath.Join(t.TempDir(), "elsewhere.txt")
	if err := os.WriteFile(outside, []byte("x\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	if sha := recordDelta(tree, deltaMeta{harness: "claude", kind: "write", file: outside}); sha != "" {
		t.Errorf("a file outside the work tree recorded delta %s", sha)
	}
}

func checkout(t *testing.T, body string) string {
	t.Helper()
	state := t.TempDir()
	t.Setenv("XDG_STATE_HOME", state)
	t.Setenv("SYSINIT_PATHS_MANIFEST", filepath.Join(state, "absent.json"))
	t.Setenv("GIT_CONFIG_GLOBAL", filepath.Join(state, "gitconfig"))
	t.Setenv("GIT_CONFIG_SYSTEM", filepath.Join(state, "gitconfig"))

	tree := t.TempDir()
	write(t, tree, body)
	run(t, tree, "init", "--quiet")
	run(t, tree, "config", "user.name", "test")
	run(t, tree, "config", "user.email", "test@example.invalid")
	run(t, tree, "config", "commit.gpgsign", "false")
	run(t, tree, "add", "a.txt")
	run(t, tree, "commit", "--quiet", "-m", "start")
	return tree
}

func write(t *testing.T, tree, body string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(tree, "a.txt"), []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
}

func run(t *testing.T, tree string, args ...string) {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = tree
	cmd.Env = repo.CleanEnv()
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("git %s: %v\n%s", strings.Join(args, " "), err, out)
	}
}

func describe(t *testing.T, tree, sha, format string) string {
	t.Helper()
	out, err := git(repo.DeltaDir(tree), tree, nil, "show", "--no-patch", "--format="+format, sha)
	if err != nil {
		t.Fatalf("git show --format=%s: %v", format, err)
	}
	return strings.TrimSpace(out)
}

func show(t *testing.T, tree, sha string) string {
	t.Helper()
	out, err := git(repo.DeltaDir(tree), tree, nil, "show", "--format=", sha)
	if err != nil {
		t.Fatalf("git show: %v", err)
	}
	return out
}
