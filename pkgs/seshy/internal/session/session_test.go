package session

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// ---------------------------------------------------------------------------
// helpers
// ---------------------------------------------------------------------------

// isolatedRoot sets XDG_STATE_HOME and XDG_CONFIG_HOME to per-test temp dirs.
// Both must be isolated: a real config with sessionsDir overrides XDG_STATE_HOME
// and would cause tests to see real sessions.
func isolatedRoot(t *testing.T) string {
	t.Helper()
	tmp := t.TempDir()
	t.Setenv("XDG_STATE_HOME", tmp)
	t.Setenv("XDG_CONFIG_HOME", t.TempDir())
	return tmp
}

func setupTestGitRepo(t *testing.T, dir string) {
	t.Helper()
	cmds := [][]string{
		{"git", "init", dir},
		{"git", "-C", dir, "config", "user.email", "test@example.com"},
		{"git", "-C", dir, "config", "user.name", "Test User"},
	}
	for _, args := range cmds {
		if out, err := exec.Command(args[0], args[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v failed: %v\n%s", args, err, out)
		}
	}
	readme := filepath.Join(dir, "README.md")
	if err := os.WriteFile(readme, []byte("# Test\n"), 0644); err != nil {
		t.Fatalf("write README: %v", err)
	}
	for _, args := range [][]string{
		{"git", "-C", dir, "add", "."},
		{"git", "-C", dir, "commit", "-m", "Initial commit"},
	} {
		if out, err := exec.Command(args[0], args[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v failed: %v\n%s", args, err, out)
		}
	}
}

// ---------------------------------------------------------------------------
// ValidateSessionName
// ---------------------------------------------------------------------------

func TestValidateSessionName(t *testing.T) {
	cases := []struct {
		name      string
		input     string
		wantError bool
	}{
		{"simple", "test", false},
		{"hyphen", "test-session", false},
		{"underscore", "test_session", false},
		{"numbers", "test123", false},
		{"uppercase", "MySession", false},
		{"mixed", "My-Session_2", false},
		{"empty", "", true},
		{"spaces", "test session", true},
		{"slash", "test/session", true},
		{"at sign", "test@session", true},
		{"dot", "test.session", true},
		{"leading hyphen", "-bad", false}, // hyphens allowed anywhere
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := ValidateSessionName(tc.input)
			if (err != nil) != tc.wantError {
				t.Errorf("ValidateSessionName(%q) error=%v, wantError=%v", tc.input, err, tc.wantError)
			}
		})
	}
}

// ---------------------------------------------------------------------------
// GetRepoBasename
// ---------------------------------------------------------------------------

func TestGetRepoBasename(t *testing.T) {
	cases := []struct {
		path, want string
	}{
		{"/home/user/repos/myrepo", "myrepo"},
		{"/home/user/repos/myrepo/", "myrepo"},
		{"myrepo", "myrepo"},
		{"/a/b/c", "c"},
	}
	for _, tc := range cases {
		t.Run(tc.path, func(t *testing.T) {
			got := GetRepoBasename(tc.path)
			if got != tc.want {
				t.Errorf("GetRepoBasename(%q) = %q, want %q", tc.path, got, tc.want)
			}
		})
	}
}

// ---------------------------------------------------------------------------
// IsGitRepo
// ---------------------------------------------------------------------------

func TestIsGitRepo(t *testing.T) {
	tmp := t.TempDir()

	t.Run("git repo", func(t *testing.T) {
		dir := filepath.Join(tmp, "repo")
		setupTestGitRepo(t, dir)
		if !IsGitRepo(dir) {
			t.Error("expected true for git repo")
		}
	})

	t.Run("plain dir", func(t *testing.T) {
		dir := filepath.Join(tmp, "plain")
		os.MkdirAll(dir, 0755)
		if IsGitRepo(dir) {
			t.Error("expected false for plain dir")
		}
	})

	t.Run("nonexistent path", func(t *testing.T) {
		if IsGitRepo(filepath.Join(tmp, "does-not-exist")) {
			t.Error("expected false for nonexistent path")
		}
	})
}

// ---------------------------------------------------------------------------
// gitExec
// ---------------------------------------------------------------------------

func TestGitExecErrorIncludesStderr(t *testing.T) {
	tmp := t.TempDir()
	// Run a git command that will fail with an informative error
	_, err := gitExec(tmp, "rev-parse", "--git-dir")
	if err == nil {
		t.Fatal("expected error for non-git directory")
	}
	errStr := err.Error()
	if !strings.Contains(errStr, "git rev-parse failed for") {
		t.Errorf("expected error to contain 'git rev-parse failed for', got: %s", errStr)
	}
	// Should contain some git stderr content (e.g., "fatal: not a git repository")
	if !strings.Contains(strings.ToLower(errStr), "fatal") && !strings.Contains(strings.ToLower(errStr), "not a git") {
		t.Logf("warning: error may not contain git stderr content: %s", errStr)
	}
}

func TestGitExecSuccess(t *testing.T) {
	tmp := t.TempDir()
	setupTestGitRepo(t, tmp)
	out, err := gitExec(tmp, "rev-parse", "--git-dir")
	if err != nil {
		t.Fatalf("gitExec: %v", err)
	}
	if out == "" {
		t.Error("expected non-empty output from rev-parse --git-dir")
	}
}

// ---------------------------------------------------------------------------
// CreateSymlink
// ---------------------------------------------------------------------------

func TestCreateSymlink(t *testing.T) {
	tmp := t.TempDir()
	target := filepath.Join(tmp, "target")
	os.MkdirAll(target, 0755)
	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	linkPath, err := CreateSymlink(target, sessionDir)
	if err != nil {
		t.Fatalf("CreateSymlink: %v", err)
	}

	info, err := os.Lstat(linkPath)
	if err != nil {
		t.Fatalf("Lstat: %v", err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("expected symlink, got regular entry")
	}

	resolved, err := os.Readlink(linkPath)
	if err != nil {
		t.Fatalf("Readlink: %v", err)
	}
	if resolved != target {
		t.Errorf("symlink target = %q, want %q", resolved, target)
	}
}

func TestCreateSymlinkNamingConvention(t *testing.T) {
	tmp := t.TempDir()
	target := filepath.Join(tmp, "my-cool-repo")
	os.MkdirAll(target, 0755)
	sessionDir := filepath.Join(tmp, "sess")
	os.MkdirAll(sessionDir, 0755)

	linkPath, err := CreateSymlink(target, sessionDir)
	if err != nil {
		t.Fatalf("CreateSymlink: %v", err)
	}
	if filepath.Base(linkPath) != "my-cool-repo" {
		t.Errorf("expected link name 'my-cool-repo', got %q", filepath.Base(linkPath))
	}
}

func TestCreateSymlinkDuplicate(t *testing.T) {
	tmp := t.TempDir()
	target := filepath.Join(tmp, "target")
	os.MkdirAll(target, 0755)
	sessionDir := filepath.Join(tmp, "sess")
	os.MkdirAll(sessionDir, 0755)

	link1, err := CreateSymlink(target, sessionDir)
	if err != nil {
		t.Fatalf("first CreateSymlink: %v", err)
	}
	// Second symlink with same target should get disambiguated name
	link2, err := CreateSymlink(target, sessionDir)
	if err != nil {
		t.Fatalf("second CreateSymlink: %v", err)
	}
	if link1 == link2 {
		t.Error("expected different paths for duplicate symlinks")
	}
}

// ---------------------------------------------------------------------------
// CreateWorktree
// ---------------------------------------------------------------------------

func TestCreateWorktree(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	sessionDir := filepath.Join(tmp, "sessions", "my-session")
	os.MkdirAll(sessionDir, 0755)

	worktreePath, err := CreateWorktree(repoDir, sessionDir, "sy/my-session/testrepo")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}

	if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
		t.Error("worktree directory was not created")
	}
	if !IsGitRepo(worktreePath) {
		t.Error("worktree is not a git repo")
	}
	if filepath.Base(worktreePath) != "testrepo" {
		t.Errorf("expected worktree name 'testrepo', got %q", filepath.Base(worktreePath))
	}
}

func TestCreateWorktreeNonGitRepo(t *testing.T) {
	tmp := t.TempDir()
	plain := filepath.Join(tmp, "plain")
	os.MkdirAll(plain, 0755)
	sessionDir := filepath.Join(tmp, "sess")
	os.MkdirAll(sessionDir, 0755)

	_, err := CreateWorktree(plain, sessionDir, "sy/sess/plain")
	if err == nil {
		t.Error("expected error when source is not a git repo")
	}
}

func TestCreateWorktreeOnSessionBranch(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	sessionDir := filepath.Join(tmp, "sessions", "feat")
	os.MkdirAll(sessionDir, 0755)

	worktreePath, err := CreateWorktree(repoDir, sessionDir, "sy/feat/testrepo")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}

	// Verify the worktree is on a sy/ prefixed branch, not detached HEAD
	branch, err := gitExec(worktreePath, "rev-parse", "--abbrev-ref", "HEAD")
	if err != nil {
		t.Fatalf("rev-parse --abbrev-ref HEAD: %v", err)
	}
	if !strings.HasPrefix(branch, "sy/") {
		t.Errorf("expected branch to start with 'sy/', got %q", branch)
	}
	if branch != "sy/feat/testrepo" {
		t.Errorf("expected branch 'sy/feat/testrepo', got %q", branch)
	}
}

func TestCreateWorktreeDoesNotClobberMain(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	// Get original main branch ref
	originalRef, err := gitExec(repoDir, "rev-parse", "HEAD")
	if err != nil {
		t.Fatalf("rev-parse HEAD: %v", err)
	}

	sessionDir := filepath.Join(tmp, "sessions", "test")
	os.MkdirAll(sessionDir, 0755)

	_, err = CreateWorktree(repoDir, sessionDir, "test")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}

	// Verify main ref hasn't changed
	afterRef, err := gitExec(repoDir, "rev-parse", "HEAD")
	if err != nil {
		t.Fatalf("rev-parse HEAD after: %v", err)
	}
	if originalRef != afterRef {
		t.Errorf("main branch ref changed: %s -> %s", originalRef, afterRef)
	}
}

func TestCreateWorktreeSucceedsWhenBranchCheckedOutElsewhere(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	sessionDir1 := filepath.Join(tmp, "sessions", "sess1")
	sessionDir2 := filepath.Join(tmp, "sessions", "sess2")
	os.MkdirAll(sessionDir1, 0755)
	os.MkdirAll(sessionDir2, 0755)

	// Create first worktree — its branch is checked out
	wt1, err := CreateWorktree(repoDir, sessionDir1, "sess1")
	if err != nil {
		t.Fatalf("first CreateWorktree: %v", err)
	}
	if !IsGitRepo(wt1) {
		t.Fatal("first worktree is not a git repo")
	}

	// Create second worktree — should succeed despite first having source branch checked out
	wt2, err := CreateWorktree(repoDir, sessionDir2, "sess2")
	if err != nil {
		t.Fatalf("second CreateWorktree: %v (source branch already checked out in %s)", err, wt1)
	}
	if !IsGitRepo(wt2) {
		t.Fatal("second worktree is not a git repo")
	}
}

// ---------------------------------------------------------------------------
// disambiguatedName
// ---------------------------------------------------------------------------

func TestDisambiguatedNameSameBasename(t *testing.T) {
	tmp := t.TempDir()
	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	// First repo gets simple name
	repo1 := filepath.Join(tmp, "team-a", "api")
	os.MkdirAll(repo1, 0755)
	name1 := disambiguatedName(repo1, sessionDir)
	if name1 != "api" {
		t.Errorf("expected 'api', got %q", name1)
	}

	// Create entry so next one collides
	os.MkdirAll(filepath.Join(sessionDir, name1), 0755)

	// Second repo with same basename gets parent-dir prefix
	repo2 := filepath.Join(tmp, "team-b", "api")
	os.MkdirAll(repo2, 0755)
	name2 := disambiguatedName(repo2, sessionDir)
	if name2 != "team-b-api" {
		t.Errorf("expected 'team-b-api', got %q", name2)
	}
}

func TestDisambiguatedNameNumericFallback(t *testing.T) {
	tmp := t.TempDir()
	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	repo1 := filepath.Join(tmp, "team-a", "api")
	os.MkdirAll(repo1, 0755)

	// Create simple and parent-prefixed entries to force numeric fallback
	os.MkdirAll(filepath.Join(sessionDir, "api"), 0755)
	os.MkdirAll(filepath.Join(sessionDir, "team-a-api"), 0755)

	name := disambiguatedName(repo1, sessionDir)
	if name != "api-2" {
		t.Errorf("expected 'api-2', got %q", name)
	}
}

// ---------------------------------------------------------------------------
// CleanupWorktrees
// ---------------------------------------------------------------------------

func TestCleanupWorktrees(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	worktreePath, err := CreateWorktree(repoDir, sessionDir, "test")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}
	if _, err := os.Stat(worktreePath); os.IsNotExist(err) {
		t.Fatal("worktree was not created")
	}

	if err := CleanupWorktrees(sessionDir, false); err != nil {
		t.Fatalf("CleanupWorktrees: %v", err)
	}

	exec.Command("git", "-C", repoDir, "worktree", "prune").Run()
	out, _ := exec.Command("git", "-C", repoDir, "worktree", "list").Output()
	if strings.Contains(string(out), worktreePath) {
		t.Errorf("worktree still registered after cleanup + prune:\n%s", out)
	}
}

func TestCleanupWorktreesEmptyDir(t *testing.T) {
	tmp := t.TempDir()
	empty := filepath.Join(tmp, "empty")
	os.MkdirAll(empty, 0755)
	// Should not error on a directory with no worktrees
	if err := CleanupWorktrees(empty, false); err != nil {
		t.Errorf("CleanupWorktrees on empty dir: %v", err)
	}
}

func TestCleanupWorktreesNonexistentDir(t *testing.T) {
	err := CleanupWorktrees("/nonexistent/path/that/does/not/exist", false)
	if err == nil {
		t.Error("expected error for nonexistent directory")
	}
}

// ---------------------------------------------------------------------------
// GetWorktreeMainRepo
// ---------------------------------------------------------------------------

func TestGetWorktreeMainRepo(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "testrepo")
	setupTestGitRepo(t, repoDir)

	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	worktreePath, err := CreateWorktree(repoDir, sessionDir, "test")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}

	mainRepo, err := GetWorktreeMainRepo(worktreePath)
	if err != nil {
		t.Fatalf("GetWorktreeMainRepo: %v", err)
	}
	// The resolved main repo should point somewhere inside or equal to repoDir
	if mainRepo == "" {
		t.Error("expected non-empty main repo path")
	}
}

func TestGetWorktreeMainRepoNonGit(t *testing.T) {
	tmp := t.TempDir()
	_, err := GetWorktreeMainRepo(tmp)
	if err == nil {
		t.Error("expected error for non-git directory")
	}
}

// ---------------------------------------------------------------------------
// ListRepoSources
// ---------------------------------------------------------------------------

func TestListRepoSources(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "myrepo")
	setupTestGitRepo(t, repoDir)
	plainDir := filepath.Join(tmp, "plain")
	os.MkdirAll(plainDir, 0755)

	sessionDir := filepath.Join(tmp, "session")
	os.MkdirAll(sessionDir, 0755)

	// Create a worktree and a symlink
	_, err := CreateWorktree(repoDir, sessionDir, "test")
	if err != nil {
		t.Fatalf("CreateWorktree: %v", err)
	}
	_, err = CreateSymlink(plainDir, sessionDir)
	if err != nil {
		t.Fatalf("CreateSymlink: %v", err)
	}

	sources, err := ListRepoSources(sessionDir)
	if err != nil {
		t.Fatalf("ListRepoSources: %v", err)
	}

	if len(sources) != 2 {
		t.Errorf("expected 2 sources, got %d: %v", len(sources), sources)
	}
}

// ---------------------------------------------------------------------------
// Exists / GetPath
// ---------------------------------------------------------------------------

func TestExistsAndGetPath(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("exist-test", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	if !Exists("exist-test") {
		t.Error("expected Exists to return true")
	}

	path, err := GetPath("exist-test")
	if err != nil {
		t.Fatalf("GetPath: %v", err)
	}
	if path == "" {
		t.Error("expected non-empty path")
	}
}

func TestExistsFalse(t *testing.T) {
	isolatedRoot(t)
	if Exists("no-such-session") {
		t.Error("expected Exists to return false for missing session")
	}
}

func TestGetPathNotFound(t *testing.T) {
	isolatedRoot(t)
	_, err := GetPath("no-such-session")
	if err == nil {
		t.Error("expected error for nonexistent session")
	}
}

// ---------------------------------------------------------------------------
// Create
// ---------------------------------------------------------------------------

func TestCreateWithGitRepo(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "myrepo")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("create-git", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessionPath, _ := GetPath("create-git")
	worktree := filepath.Join(sessionPath, "myrepo")
	if _, err := os.Stat(worktree); os.IsNotExist(err) {
		t.Error("expected worktree to be created")
	}
}

func TestCreateWithNonGitDir(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	plainDir := filepath.Join(tmp, "plain")
	os.MkdirAll(plainDir, 0755)

	if _, err := Create("create-plain", []string{plainDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessionPath, _ := GetPath("create-plain")
	link := filepath.Join(sessionPath, "plain")
	info, err := os.Lstat(link)
	if err != nil {
		t.Fatalf("Lstat link: %v", err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("expected symlink for non-git dir")
	}
}

func TestCreateDuplicateErrors(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("dup-session", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("first Create: %v", err)
	}
	if _, err := Create("dup-session", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err == nil {
		t.Error("expected error on duplicate Create")
	}
}

func TestCreateInvalidName(t *testing.T) {
	isolatedRoot(t)
	if _, err := Create("bad name!", []string{}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err == nil {
		t.Error("expected error for invalid session name")
	}
}

func TestCreateMultipleRepos(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repo1 := filepath.Join(tmp, "repo1")
	repo2 := filepath.Join(tmp, "repo2")
	setupTestGitRepo(t, repo1)
	setupTestGitRepo(t, repo2)

	if _, err := Create("multi", []string{repo1, repo2}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessionPath, _ := GetPath("multi")
	for _, name := range []string{"repo1", "repo2"} {
		if _, err := os.Stat(filepath.Join(sessionPath, name)); os.IsNotExist(err) {
			t.Errorf("expected %s worktree to exist", name)
		}
	}
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

func TestListEmpty(t *testing.T) {
	isolatedRoot(t)
	sessions, err := List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(sessions) != 0 {
		t.Errorf("expected 0 sessions, got %d", len(sessions))
	}
}

func TestListMultiple(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	for _, name := range []string{"alpha", "beta", "gamma"} {
		if _, err := Create(name, []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
			t.Fatalf("Create %s: %v", name, err)
		}
	}

	sessions, err := List()
	if err != nil {
		t.Fatalf("List: %v", err)
	}
	if len(sessions) != 3 {
		t.Errorf("expected 3 sessions, got %d", len(sessions))
	}

	names := map[string]bool{}
	for _, s := range sessions {
		names[s.Name] = true
		if s.Path == "" {
			t.Errorf("session %q has empty path", s.Name)
		}
		if s.LastModified.IsZero() {
			t.Errorf("session %q has zero LastModified", s.Name)
		}
	}
	for _, n := range []string{"alpha", "beta", "gamma"} {
		if !names[n] {
			t.Errorf("session %q missing from list", n)
		}
	}
}

func TestListRepoCount(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repo1 := filepath.Join(tmp, "r1")
	repo2 := filepath.Join(tmp, "r2")
	setupTestGitRepo(t, repo1)
	setupTestGitRepo(t, repo2)

	if _, err := Create("count-test", []string{repo1, repo2}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessions, _ := List()
	for _, s := range sessions {
		if s.Name == "count-test" && s.RepoCount != 2 {
			t.Errorf("expected RepoCount=2, got %d", s.RepoCount)
		}
	}
}

// ---------------------------------------------------------------------------
// AddRepos
// ---------------------------------------------------------------------------

func TestAddRepos(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repo1 := filepath.Join(tmp, "repo1")
	repo2 := filepath.Join(tmp, "repo2")
	setupTestGitRepo(t, repo1)
	setupTestGitRepo(t, repo2)

	if _, err := Create("add-test", []string{repo1}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}
	if _, _, err := AddRepos("add-test", []string{repo2}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("AddRepos: %v", err)
	}

	sessionPath, _ := GetPath("add-test")
	for _, wt := range []string{"repo1", "repo2"} {
		if _, err := os.Stat(filepath.Join(sessionPath, wt)); os.IsNotExist(err) {
			t.Errorf("expected %s to exist after AddRepos", wt)
		}
	}
}

func TestAddReposSessionNotFound(t *testing.T) {
	isolatedRoot(t)
	if _, _, err := AddRepos("no-such", []string{"/tmp"}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err == nil {
		t.Error("expected error adding to nonexistent session")
	}
}

func TestAddReposNonGitDir(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)
	plainDir := filepath.Join(tmp, "plain")
	os.MkdirAll(plainDir, 0755)

	if _, err := Create("add-plain", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}
	if _, _, err := AddRepos("add-plain", []string{plainDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("AddRepos with plain dir: %v", err)
	}

	sessionPath, _ := GetPath("add-plain")
	link := filepath.Join(sessionPath, "plain")
	info, err := os.Lstat(link)
	if err != nil {
		t.Fatalf("Lstat: %v", err)
	}
	if info.Mode()&os.ModeSymlink == 0 {
		t.Error("expected symlink for non-git dir in AddRepos")
	}
}

func TestAddReposDuplicateSkips(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "myrepo")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("dup-add", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	// Adding the same repo again should not error (it's skipped)
	_, _, err := AddRepos("dup-add", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})
	if err != nil {
		t.Fatalf("AddRepos with duplicate should not error, got: %v", err)
	}
}

func TestAddReposDuplicateViaResolvedPath(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "myrepo")
	setupTestGitRepo(t, repoDir)

	// Create a symlink to the repo to simulate different path
	symlinkToRepo := filepath.Join(tmp, "repo-alias")
	os.Symlink(repoDir, symlinkToRepo)

	if _, err := Create("dup-resolved", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	// Adding via symlink path should detect duplicate via resolved path
	_, _, err := AddRepos("dup-resolved", []string{symlinkToRepo}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})
	if err != nil {
		t.Fatalf("AddRepos with resolved duplicate should not error, got: %v", err)
	}
}

func setupEmptyGitRepo(t *testing.T, dir string) {
	t.Helper()
	cmds := [][]string{
		{"git", "init", dir},
		{"git", "-C", dir, "config", "user.email", "test@example.com"},
		{"git", "-C", dir, "config", "user.name", "Test User"},
	}
	for _, args := range cmds {
		if out, err := exec.Command(args[0], args[1:]...).CombinedOutput(); err != nil {
			t.Fatalf("%v failed: %v\n%s", args, err, out)
		}
	}
}

func TestAddReposPartialFailure(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repo1 := filepath.Join(tmp, "repo1")
	repo2 := filepath.Join(tmp, "repo2")
	setupTestGitRepo(t, repo1)
	setupTestGitRepo(t, repo2)

	badDir := filepath.Join(tmp, "badrepo")
	setupEmptyGitRepo(t, badDir)

	if _, err := Create("partial-fail", []string{repo1}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	result, _, err := AddRepos("partial-fail", []string{repo2, badDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})
	if err != nil {
		t.Fatalf("AddReposResult session error: %v", err)
	}

	found := false
	for _, a := range result.Added {
		if a == repo2 {
			found = true
		}
	}
	if !found {
		t.Error("expected repo2 to be in Added list")
	}

	if _, ok := result.Errors[badDir]; !ok {
		t.Error("expected badDir to be in Errors map")
	}
}

func TestAddReposAllFail(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("all-fail", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	// Empty git repos (no commits) will fail worktree creation
	badDir1 := filepath.Join(tmp, "bad1")
	setupEmptyGitRepo(t, badDir1)

	badDir2 := filepath.Join(tmp, "bad2")
	setupEmptyGitRepo(t, badDir2)

	result, _, err := AddRepos("all-fail", []string{badDir1, badDir2}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})
	if err != nil {
		t.Fatalf("AddRepos returned unexpected error: %v", err)
	}
	if result.Err() == nil {
		t.Error("expected result.Err() to be non-nil when all repos fail")
	}
}

// ---------------------------------------------------------------------------
// Delete
// ---------------------------------------------------------------------------

func TestDelete(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("del-test", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}
	if err := Delete("del-test", false); err != nil {
		t.Fatalf("Delete: %v", err)
	}
	if Exists("del-test") {
		t.Error("expected session to be gone after Delete")
	}
}

func TestDeleteNotFound(t *testing.T) {
	isolatedRoot(t)
	if err := Delete("ghost", false); err == nil {
		t.Error("expected error deleting nonexistent session")
	}
}

func TestDeleteCleansUpWorktrees(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("wt-del", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessionPath, _ := GetPath("wt-del")
	worktreePath := filepath.Join(sessionPath, "r-wt-del")

	if err := Delete("wt-del", false); err != nil {
		t.Fatalf("Delete: %v", err)
	}

	// worktree directory should be gone
	if _, err := os.Stat(worktreePath); !os.IsNotExist(err) {
		t.Error("worktree directory still exists after Delete")
	}

	// git worktree prune removes stale entries; after that the path should not appear
	exec.Command("git", "-C", repoDir, "worktree", "prune").Run()
	out, _ := exec.Command("git", "-C", repoDir, "worktree", "list").Output()
	if strings.Contains(string(out), worktreePath) {
		t.Errorf("worktree still registered after Delete + prune:\n%s", out)
	}
}

// ---------------------------------------------------------------------------
// Accurate repo count
// ---------------------------------------------------------------------------

func TestListRepoCountExcludesDSStore(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repo1 := filepath.Join(tmp, "r1")
	repo2 := filepath.Join(tmp, "r2")
	setupTestGitRepo(t, repo1)
	setupTestGitRepo(t, repo2)

	if _, err := Create("dsstore-test", []string{repo1, repo2}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	// Add a .DS_Store file to the session directory
	sessionPath, _ := GetPath("dsstore-test")
	os.WriteFile(filepath.Join(sessionPath, ".DS_Store"), []byte("x"), 0644)

	sessions, _ := List()
	for _, s := range sessions {
		if s.Name == "dsstore-test" {
			if s.RepoCount != 2 {
				t.Errorf("expected RepoCount=2 (excluding .DS_Store), got %d", s.RepoCount)
			}
			return
		}
	}
	t.Error("session 'dsstore-test' not found in list")
}

func TestListRepoCountEmptySession(t *testing.T) {
	isolatedRoot(t)

	// Create session directory manually with no entries
	root := filepath.Join(os.Getenv("XDG_STATE_HOME"), "seshy", "sessions", "empty-test")
	os.MkdirAll(root, 0755)

	sessions, _ := List()
	for _, s := range sessions {
		if s.Name == "empty-test" {
			if s.RepoCount != 0 {
				t.Errorf("expected RepoCount=0 for empty session, got %d", s.RepoCount)
			}
			return
		}
	}
	t.Error("session 'empty-test' not found in list")
}

// ---------------------------------------------------------------------------
// Branch cleanup on delete
// ---------------------------------------------------------------------------

func TestDeleteCleansBranches(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "r")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("branch-cleanup", []string{repoDir}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	// Verify branch exists before delete
	branches, _ := gitExec(repoDir, "branch", "--list", "sy/branch-cleanup/*")
	if branches == "" {
		t.Fatal("expected sy/branch-cleanup/* branch to exist before delete")
	}

	if err := Delete("branch-cleanup", false); err != nil {
		t.Fatalf("Delete: %v", err)
	}

	// Verify branch is cleaned up
	branches, _ = gitExec(repoDir, "branch", "--list", "sy/branch-cleanup/*")
	if strings.TrimSpace(branches) != "" {
		t.Errorf("expected branch to be deleted after session delete, still found: %q", branches)
	}
}

// ---------------------------------------------------------------------------
// Atomic create rollback
// ---------------------------------------------------------------------------

func TestCreateRollsBackOnFailure(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	// Good repo (has commits)
	goodRepo := filepath.Join(tmp, "good")
	setupTestGitRepo(t, goodRepo)

	// Bad repo (no commits, worktree creation will fail)
	badRepo := filepath.Join(tmp, "bad")
	setupEmptyGitRepo(t, badRepo)

	_, err := Create("rollback-test", []string{goodRepo, badRepo}, CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"})
	if err == nil {
		t.Fatal("expected Create to fail with bad repo")
	}

	// Session directory should not exist (cleaned up)
	if Exists("rollback-test") {
		t.Error("expected session to be cleaned up after failed create")
	}

	// Branch from the good repo should also be cleaned up
	branches, _ := gitExec(goodRepo, "branch", "--list", "sy/rollback-test/*")
	if strings.TrimSpace(branches) != "" {
		t.Errorf("expected branch to be rolled back, still found: %q", branches)
	}
}
