package cmd

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
)

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

// isolatedRoot redirects XDG_STATE_HOME and XDG_CONFIG_HOME to per-test temp
// dirs. Both must be isolated: a real config with sessionsDir set would
// override XDG_STATE_HOME and make tests see real sessions.
func isolatedRoot(t *testing.T) {
	t.Helper()
	t.Setenv("XDG_STATE_HOME", t.TempDir())
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
}

func setupGitRepo(t *testing.T, dir string) {
	t.Helper()
	cmds := [][]string{
		{"git", "init", dir},
		{"git", "-C", dir, "config", "user.email", "t@t.com"},
		{"git", "-C", dir, "config", "user.name", "T"},
	}
	for _, a := range cmds {
		if out, err := exec.Command(a[0], a[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v: %v\n%s", a, err, out)
		}
	}
	if err := os.WriteFile(filepath.Join(dir, "f"), []byte("x"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}
	for _, a := range [][]string{
		{"git", "-C", dir, "add", "."},
		{"git", "-C", dir, "commit", "-m", "init"},
	} {
		if out, err := exec.Command(a[0], a[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v: %v\n%s", a, err, out)
		}
	}
}

// runCmd executes a cobra command and returns stdout, stderr and error.
// It redirects os.Stdout so that fmt.Println calls in subcommands are captured.
func runCmd(args ...string) (stdout, stderr string, err error) {
	// Capture real os.Stdout via a pipe
	origStdout := os.Stdout
	r, w, pipeErr := os.Pipe()
	if pipeErr != nil {
		panic(pipeErr)
	}
	os.Stdout = w

	// Reset persistent flags before each run
	greedyQuery = ""
	forceDelete = false
	deleteArchived = false
	listArchived = false
	newBranch = ""
	newStdin = false
	newEmpty = false

	rootCmd.SetArgs(args)
	err = rootCmd.Execute()

	w.Close()
	os.Stdout = origStdout

	var buf bytes.Buffer
	buf.ReadFrom(r)
	r.Close()
	return buf.String(), "", err
}

// ---------------------------------------------------------------------------
// greedyMatch
// ---------------------------------------------------------------------------

func makeSessions(names ...string) []session.Session {
	out := make([]session.Session, len(names))
	for i, n := range names {
		out[i] = session.Session{Name: n, Path: "/sessions/" + n, LastModified: time.Now()}
	}
	return out
}

func TestGreedyMatchExact(t *testing.T) {
	sessions := makeSessions("platform-auth", "platform-core", "infra")
	match := greedyMatch("platform-auth", sessions)
	if match == nil || match.Name != "platform-auth" {
		t.Errorf("expected exact match 'platform-auth', got %v", match)
	}
}

func TestGreedyMatchExactCaseInsensitive(t *testing.T) {
	sessions := makeSessions("Platform-Auth", "platform-core")
	match := greedyMatch("platform-auth", sessions)
	if match == nil || match.Name != "Platform-Auth" {
		t.Errorf("expected case-insensitive match, got %v", match)
	}
}

func TestGreedyMatchPrefix(t *testing.T) {
	sessions := makeSessions("platform-auth", "platform-core", "infra")
	match := greedyMatch("plat", sessions)
	if match == nil {
		t.Fatal("expected prefix match, got nil")
	}
	if !strings.HasPrefix(strings.ToLower(match.Name), "plat") {
		t.Errorf("expected prefix match starting with 'plat', got %q", match.Name)
	}
}

func TestGreedyMatchSubstring(t *testing.T) {
	sessions := makeSessions("my-platform-v2", "infra")
	match := greedyMatch("platform", sessions)
	if match == nil || match.Name != "my-platform-v2" {
		t.Errorf("expected substring match 'my-platform-v2', got %v", match)
	}
}

func TestGreedyMatchExactBeatsPrefix(t *testing.T) {
	sessions := makeSessions("platform-extra", "platform")
	match := greedyMatch("platform", sessions)
	if match == nil || match.Name != "platform" {
		t.Errorf("expected exact match to win over prefix, got %v", match)
	}
}

func TestGreedyMatchPrefixBeatsSubstring(t *testing.T) {
	sessions := makeSessions("my-platform", "plat-something")
	match := greedyMatch("plat", sessions)
	if match == nil || match.Name != "plat-something" {
		t.Errorf("expected prefix match to win over substring, got %v", match)
	}
}

func TestGreedyMatchNoMatch(t *testing.T) {
	sessions := makeSessions("alpha", "beta")
	match := greedyMatch("gamma", sessions)
	if match != nil {
		t.Errorf("expected nil for no match, got %v", match)
	}
}

func TestGreedyMatchEmptyQuery(t *testing.T) {
	sessions := makeSessions("alpha")
	// Empty string is a substring of everything — first result
	match := greedyMatch("", sessions)
	if match == nil {
		t.Error("expected match for empty query (substring of all)")
	}
}

func TestGreedyMatchEmptySessions(t *testing.T) {
	match := greedyMatch("anything", []session.Session{})
	if match != nil {
		t.Error("expected nil for empty sessions slice")
	}
}

func TestGreedyMatchReturnsPointerToSliceElement(t *testing.T) {
	sessions := makeSessions("alpha", "beta")
	match := greedyMatch("alpha", sessions)
	if match == nil {
		t.Fatal("expected non-nil match")
	}
	// Path should be the one we set in makeSessions
	if match.Path != "/sessions/alpha" {
		t.Errorf("path mismatch: %q", match.Path)
	}
}

// ---------------------------------------------------------------------------
// list command
// ---------------------------------------------------------------------------

func TestListCommandNoSessions(t *testing.T) {
	isolatedRoot(t)
	stdout, _, err := runCmd("list")
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if !strings.Contains(stdout, "No sessions") {
		t.Errorf("expected 'No sessions' message, got: %q", stdout)
	}
}

func TestListCommandShowsSessions(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)

	if _, err := session.Create("my-session", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	stdout, _, err := runCmd("list")
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if !strings.Contains(stdout, "my-session") {
		t.Errorf("expected 'my-session' in list output, got: %q", stdout)
	}
}

func TestListAlias(t *testing.T) {
	isolatedRoot(t)
	stdout, _, err := runCmd("ls")
	if err != nil {
		t.Fatalf("ls: %v", err)
	}
	if !strings.Contains(stdout, "No sessions") {
		t.Errorf("expected 'No sessions' from ls alias, got: %q", stdout)
	}
}

func TestListShowsHeaders(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("hdr-test", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	stdout, _, _ := runCmd("list")
	for _, hdr := range []string{"SESSION", "REPOS", "MODIFIED"} {
		if !strings.Contains(stdout, hdr) {
			t.Errorf("expected header %q in list output, got: %q", hdr, stdout)
		}
	}
}

// ---------------------------------------------------------------------------
// path command
// ---------------------------------------------------------------------------

func TestPathCommandExists(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("path-test", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	stdout, _, err := runCmd("path", "path-test")
	if err != nil {
		t.Fatalf("path: %v", err)
	}
	path := strings.TrimSpace(stdout)
	if path == "" {
		t.Error("expected non-empty path output")
	}
	if _, err := os.Stat(path); err != nil {
		t.Errorf("path %q does not exist: %v", path, err)
	}
}

func TestPathCommandNotFound(t *testing.T) {
	isolatedRoot(t)
	_, _, err := runCmd("path", "no-such-session")
	if err == nil {
		t.Error("expected error for nonexistent session")
	}
}

// ---------------------------------------------------------------------------
// delete command
// ---------------------------------------------------------------------------

func TestDeleteCommandSuccess(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("del-me", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	_, _, err := runCmd("delete", "--force", "del-me")
	if err != nil {
		t.Fatalf("delete: %v", err)
	}
	if session.Exists("del-me") {
		t.Error("session still exists after delete")
	}
}

func TestDeleteCommandNotFound(t *testing.T) {
	isolatedRoot(t)
	_, _, err := runCmd("delete", "--force", "no-such")
	if err == nil {
		t.Error("expected error deleting nonexistent session")
	}
}

func TestDeleteAliasRm(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("rm-me", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	_, _, err := runCmd("rm", "--force", "rm-me")
	if err != nil {
		t.Fatalf("rm alias: %v", err)
	}
	if session.Exists("rm-me") {
		t.Error("session still exists after rm")
	}
}

func TestDeleteRmAliasDuplicate(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("rm-me2", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	_, _, err := runCmd("rm", "--force", "rm-me2")
	if err != nil {
		t.Fatalf("rm alias: %v", err)
	}
}

// TestDeleteForceRemovesLockedWorktree covers the force path end to end. git
// refuses to remove a locked worktree unless --force is given twice, so before
// the fix "sy delete --force" left both the registration and the branch behind
// in the main repo.
func TestDeleteForceRemovesLockedWorktree(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("stuck", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}

	sessionPath, _ := session.GetPath("stuck")
	worktree := filepath.Join(sessionPath, "r")
	if out, err := exec.Command("git", "-C", repo, "worktree", "lock", worktree).CombinedOutput(); err != nil {
		t.Fatalf("worktree lock: %v\n%s", err, out)
	}

	if _, _, err := runCmd("delete", "--force", "stuck"); err != nil {
		t.Fatalf("delete --force: %v", err)
	}
	if session.Exists("stuck") {
		t.Error("--force left the session directory in place")
	}

	out, err := exec.Command("git", "-C", repo, "worktree", "list", "--porcelain").CombinedOutput()
	if err != nil {
		t.Fatalf("worktree list: %v\n%s", err, out)
	}
	if strings.Contains(string(out), worktree) {
		t.Errorf("locked worktree still registered after --force:\n%s", out)
	}

	branches, err := exec.Command("git", "-C", repo, "branch", "--list", "sy/stuck/r").Output()
	if err != nil {
		t.Fatalf("branch list: %v", err)
	}
	if strings.TrimSpace(string(branches)) != "" {
		t.Errorf("branch not deleted after --force: %q", branches)
	}
}

// TestDeleteWithoutForceRefusesLockedWorktree is the other half: without
// --force a lock must stop the delete, leaving the session intact.
func TestDeleteWithoutForceRefusesLockedWorktree(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("held", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}

	sessionPath, _ := session.GetPath("held")
	if out, err := exec.Command("git", "-C", repo, "worktree", "lock", filepath.Join(sessionPath, "r")).CombinedOutput(); err != nil {
		t.Fatalf("worktree lock: %v\n%s", err, out)
	}

	if err := session.Delete("held", false); err == nil {
		t.Error("expected delete without force to refuse a locked worktree")
	}
	if !session.Exists("held") {
		t.Error("a refused delete must leave the session in place")
	}
}

// ---------------------------------------------------------------------------
// archive / unarchive commands
// ---------------------------------------------------------------------------

func TestArchiveCommand(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("shelve", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}

	if _, _, err := runCmd("archive", "shelve"); err != nil {
		t.Fatalf("archive: %v", err)
	}
	if session.Exists("shelve") {
		t.Error("session still active after archive")
	}
	if !session.ArchivedExists("shelve") {
		t.Error("session missing from archive")
	}
}

func TestArchiveCommandNotFound(t *testing.T) {
	isolatedRoot(t)
	if _, _, err := runCmd("archive", "no-such"); err == nil {
		t.Error("expected error archiving a nonexistent session")
	}
}

func TestUnarchiveCommand(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("shelve2", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, _, err := runCmd("archive", "shelve2"); err != nil {
		t.Fatalf("archive: %v", err)
	}

	if _, _, err := runCmd("unarchive", "shelve2"); err != nil {
		t.Fatalf("unarchive: %v", err)
	}
	if !session.Exists("shelve2") {
		t.Error("session not restored")
	}
	if session.ArchivedExists("shelve2") {
		t.Error("session still in archive after unarchive")
	}
}

func TestUnarchiveAliasRestore(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("shelve3", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, _, err := runCmd("archive", "shelve3"); err != nil {
		t.Fatalf("archive: %v", err)
	}
	if _, _, err := runCmd("restore", "shelve3"); err != nil {
		t.Fatalf("restore: %v", err)
	}
	if !session.Exists("shelve3") {
		t.Error("session not restored via alias")
	}
}

func TestUnarchiveCommandNotFound(t *testing.T) {
	isolatedRoot(t)
	if _, _, err := runCmd("unarchive", "no-such"); err == nil {
		t.Error("expected error unarchiving a nonexistent archive entry")
	}
}

func TestListArchivedFlag(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("hidden", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, _, err := runCmd("archive", "hidden"); err != nil {
		t.Fatalf("archive: %v", err)
	}

	stdout, _, err := runCmd("list", "--names")
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if strings.Contains(stdout, "hidden") {
		t.Errorf("archived session leaked into active list: %q", stdout)
	}

	stdout, _, err = runCmd("list", "--archived", "--names")
	if err != nil {
		t.Fatalf("list --archived: %v", err)
	}
	if strings.TrimSpace(stdout) != "hidden" {
		t.Errorf("list --archived = %q, want \"hidden\"", stdout)
	}
}

func TestDeleteArchivedFlag(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, err := session.Create("gone", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, _, err := runCmd("archive", "gone"); err != nil {
		t.Fatalf("archive: %v", err)
	}

	if _, _, err := runCmd("delete", "--archived", "--force", "gone"); err != nil {
		t.Fatalf("delete --archived: %v", err)
	}
	if session.ArchivedExists("gone") {
		t.Error("archived session still exists after delete --archived")
	}
}

// ---------------------------------------------------------------------------
// new command (argument validation only — picker is interactive)
// ---------------------------------------------------------------------------

func TestNewCommandInvalidName(t *testing.T) {
	isolatedRoot(t)
	_, _, err := runCmd("new", "bad name!")
	if err == nil {
		t.Error("expected error for invalid session name")
	}
}

func TestNewCommandDuplicate(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("dup", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	// new command would invoke the interactive picker, so we test the
	// duplicate guard through session.Create directly to avoid TTY requirement
	if _, err := session.Create("dup", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err == nil {
		t.Error("expected error for duplicate session name")
	}
}

func TestNewCommandEmptyFlag(t *testing.T) {
	isolatedRoot(t)
	if _, _, err := runCmd("new", "solo", "--empty"); err != nil {
		t.Fatalf("new --empty: %v", err)
	}
	path, err := session.GetPath("solo")
	if err != nil {
		t.Fatalf("session not created: %v", err)
	}
	if repos := session.GetSessionRepoInfos(path); len(repos) != 0 {
		t.Errorf("expected 0 repos, got %d", len(repos))
	}
}

func TestNewCommandEmptyFlagRejectsRepos(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	if _, _, err := runCmd("new", "solo", repo, "--empty"); err == nil {
		t.Error("expected error when --empty is combined with repo arguments")
	}
	if session.Exists("solo") {
		t.Error("session should not be created when the flags conflict")
	}
}

// --stdin with no lines must not fall back to the interactive picker: the
// caller already declared where the repo list comes from.
func TestNewCommandStdinNoLinesCreatesEmptySession(t *testing.T) {
	isolatedRoot(t)
	empty, err := os.Open(os.DevNull)
	if err != nil {
		t.Fatalf("open devnull: %v", err)
	}
	defer empty.Close()
	orig := os.Stdin
	os.Stdin = empty
	defer func() { os.Stdin = orig }()

	if _, _, err := runCmd("new", "piped", "--stdin"); err != nil {
		t.Fatalf("new --stdin: %v", err)
	}
	path, err := session.GetPath("piped")
	if err != nil {
		t.Fatalf("session not created: %v", err)
	}
	if repos := session.GetSessionRepoInfos(path); len(repos) != 0 {
		t.Errorf("expected 0 repos, got %d", len(repos))
	}
}

func TestEmptySessionListsArchivesAndDeletes(t *testing.T) {
	isolatedRoot(t)
	if _, _, err := runCmd("new", "solo", "--empty"); err != nil {
		t.Fatalf("new --empty: %v", err)
	}

	stdout, _, err := runCmd("list")
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if !strings.Contains(stdout, "solo") {
		t.Errorf("list did not show the empty session: %q", stdout)
	}

	if _, _, err := runCmd("status", "solo"); err != nil {
		t.Fatalf("status: %v", err)
	}
	if _, _, err := runCmd("archive", "solo"); err != nil {
		t.Fatalf("archive: %v", err)
	}
	if _, _, err := runCmd("unarchive", "solo"); err != nil {
		t.Fatalf("unarchive: %v", err)
	}
	if _, _, err := runCmd("delete", "solo", "--force"); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if session.Exists("solo") {
		t.Error("session still exists after delete")
	}
}

// ---------------------------------------------------------------------------
// version
// ---------------------------------------------------------------------------

func TestVersionFlag(t *testing.T) {
	isolatedRoot(t)
	stdout, _, _ := runCmd("--version")
	if !strings.Contains(stdout, version) {
		t.Errorf("expected version %q in output, got: %q", version, stdout)
	}
}

// ---------------------------------------------------------------------------
// formatRelativeTime
// ---------------------------------------------------------------------------

func TestFormatRelativeTimeJustNow(t *testing.T) {
	got := formatRelativeTime(time.Now())
	if got != "just now" {
		t.Errorf("expected 'just now', got %q", got)
	}
}

func TestFormatRelativeTimeMinutes(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-5 * time.Minute))
	if !strings.Contains(got, "minute") {
		t.Errorf("expected 'minutes' in output, got %q", got)
	}
}

func TestFormatRelativeTimeOneMinute(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-61 * time.Second))
	if got != "1 minute ago" {
		t.Errorf("expected '1 minute ago', got %q", got)
	}
}

func TestFormatRelativeTimeHours(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-3 * time.Hour))
	if !strings.Contains(got, "hour") {
		t.Errorf("expected 'hours' in output, got %q", got)
	}
}

func TestFormatRelativeTimeOneHour(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-61 * time.Minute))
	if got != "1 hour ago" {
		t.Errorf("expected '1 hour ago', got %q", got)
	}
}

func TestFormatRelativeTimeDays(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-3 * 24 * time.Hour))
	if !strings.Contains(got, "day") {
		t.Errorf("expected 'days' in output, got %q", got)
	}
}

func TestFormatRelativeTimeOneDay(t *testing.T) {
	got := formatRelativeTime(time.Now().Add(-25 * time.Hour))
	if got != "1 day ago" {
		t.Errorf("expected '1 day ago', got %q", got)
	}
}

func TestFormatRelativeTimeOldDate(t *testing.T) {
	old := time.Date(2020, 1, 15, 0, 0, 0, 0, time.UTC)
	got := formatRelativeTime(old)
	if !strings.Contains(got, "2020") {
		t.Errorf("expected year '2020' in output, got %q", got)
	}
}

// ---------------------------------------------------------------------------
// config command
// ---------------------------------------------------------------------------

func TestConfigCommandShowsDefaults(t *testing.T) {
	isolatedRoot(t)
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	stdout, _, err := runCmd("config")
	if err != nil {
		t.Fatalf("config: %v", err)
	}
	if !strings.Contains(stdout, "branchFormat") {
		t.Errorf("expected 'branchFormat' in config output, got: %q", stdout)
	}
	if !strings.Contains(stdout, "sy/") {
		t.Errorf("expected 'sy/' in branch format, got: %q", stdout)
	}
}

// ---------------------------------------------------------------------------
// list output formats
// ---------------------------------------------------------------------------

func TestListJSON(t *testing.T) {
	isolatedRoot(t)
	listJSON = false
	listNames = false
	listPaths = false
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("json-test", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	stdout, _, err := runCmd("list", "--json")
	if err != nil {
		t.Fatalf("list --json: %v", err)
	}
	if !strings.Contains(stdout, `"name": "json-test"`) {
		t.Errorf("expected JSON with name, got: %q", stdout)
	}
	if !strings.Contains(stdout, `"repoCount"`) {
		t.Errorf("expected repoCount in JSON, got: %q", stdout)
	}
}

func TestListNames(t *testing.T) {
	isolatedRoot(t)
	listJSON = false
	listNames = false
	listPaths = false
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("names-test", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	stdout, _, err := runCmd("list", "--names")
	if err != nil {
		t.Fatalf("list --names: %v", err)
	}
	if strings.TrimSpace(stdout) != "names-test" {
		t.Errorf("expected 'names-test', got %q", strings.TrimSpace(stdout))
	}
}

func TestListPaths(t *testing.T) {
	isolatedRoot(t)
	listJSON = false
	listNames = false
	listPaths = false
	tmp := t.TempDir()
	repo := filepath.Join(tmp, "r")
	setupGitRepo(t, repo)
	_, _ = session.Create("paths-test", []string{repo}, session.CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})

	stdout, _, err := runCmd("list", "--paths")
	if err != nil {
		t.Fatalf("list --paths: %v", err)
	}
	if !strings.Contains(stdout, "paths-test") {
		t.Errorf("expected path containing 'paths-test', got %q", stdout)
	}
}

func TestListEmpty(t *testing.T) {
	isolatedRoot(t)
	listJSON = false
	listNames = false
	listPaths = false
	stdout, _, err := runCmd("list", "--json")
	if err != nil {
		t.Fatalf("list --json empty: %v", err)
	}
	if !strings.Contains(stdout, "[]") {
		t.Errorf("expected empty JSON array, got %q", stdout)
	}
}

// ---------------------------------------------------------------------------
// table rendering
// ---------------------------------------------------------------------------

// TestPrintSessionListAlignsColoredHeader guards the padding bug: ANSI escapes
// carry no display width, so padding must be applied before coloring or the
// header drifts out of line with the rows below it.
func TestPrintSessionListAlignsColoredHeader(t *testing.T) {
	ui.SetStdoutColorsEnabled(true)
	defer ui.SetStdoutColorsEnabled(false)

	sessions := []session.Session{
		{Name: "a-very-long-session-name", RepoCount: 3, LastModified: time.Now()},
		{Name: "sh", RepoCount: 12, LastModified: time.Now()},
	}

	origStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w
	err := printSessionList(sessions, "", "none")
	w.Close()
	os.Stdout = origStdout
	if err != nil {
		t.Fatalf("printSessionList: %v", err)
	}
	var buf bytes.Buffer
	buf.ReadFrom(r)
	r.Close()

	lines := strings.Split(strings.TrimRight(buf.String(), "\n"), "\n")
	if len(lines) != 3 {
		t.Fatalf("expected header plus 2 rows, got %d lines", len(lines))
	}

	// The name column is as wide as the longest name, plus a two-space gutter,
	// so the second column starts at the same offset on every line.
	offset := len("a-very-long-session-name") + 2
	for i, want := range []string{"REPOS", "3", "12"} {
		plain := stripANSI(lines[i])
		if len(plain) < offset || !strings.HasPrefix(plain[offset:], want) {
			t.Errorf("line %d: second column does not start at %d with %q\n%q", i, offset, want, plain)
		}
	}
}

// TestPrintSessionListNoColorWhenStdoutRedirected keeps escape codes out of a
// piped or redirected listing.
func TestPrintSessionListNoColorWhenStdoutRedirected(t *testing.T) {
	ui.SetStdoutColorsEnabled(false)

	sessions := []session.Session{{Name: "plain", RepoCount: 1, LastModified: time.Now()}}

	origStdout := os.Stdout
	r, w, _ := os.Pipe()
	os.Stdout = w
	err := printSessionList(sessions, "", "none")
	w.Close()
	os.Stdout = origStdout
	if err != nil {
		t.Fatalf("printSessionList: %v", err)
	}
	var buf bytes.Buffer
	buf.ReadFrom(r)
	r.Close()

	if strings.Contains(buf.String(), "\033[") {
		t.Errorf("expected no ANSI escapes in redirected output, got %q", buf.String())
	}
}

// stripANSI removes SGR escape sequences so tests can measure display width.
func stripANSI(s string) string {
	var out strings.Builder
	for i := 0; i < len(s); i++ {
		if s[i] == '\033' {
			for i < len(s) && s[i] != 'm' {
				i++
			}
			continue
		}
		out.WriteByte(s[i])
	}
	return out.String()
}
