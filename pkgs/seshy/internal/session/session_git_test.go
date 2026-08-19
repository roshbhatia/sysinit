package session

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"
)

// withGlobalIgnore points git's global excludes at a temp file that ignores
// openspec/ and AGENTS.md, mirroring the user's real global ignore. A session
// repo must NOT inherit this once seshy sets its repo-local core.excludesFile.
func withGlobalIgnore(t *testing.T) {
	t.Helper()
	dir := t.TempDir()
	ignore := filepath.Join(dir, "global-ignore")
	if err := os.WriteFile(ignore, []byte("openspec/\nAGENTS.md\n.claude/\n"), 0644); err != nil {
		t.Fatalf("write global ignore: %v", err)
	}
	gcfg := filepath.Join(dir, "gitconfig")
	if err := os.WriteFile(gcfg, []byte("[core]\n\texcludesFile = "+ignore+"\n"), 0644); err != nil {
		t.Fatalf("write global gitconfig: %v", err)
	}
	t.Setenv("GIT_CONFIG_GLOBAL", gcfg)
}

// isIgnored reports whether path (relative to sessionPath) is ignored by the
// session repo.
func isIgnored(t *testing.T, sessionPath, rel string) bool {
	t.Helper()
	cmd := exec.Command("git", "-C", sessionPath, "check-ignore", "-q", "--", rel)
	err := cmd.Run()
	if err == nil {
		return true
	}
	if ee, ok := err.(*exec.ExitError); ok && ee.ExitCode() == 1 {
		return false
	}
	t.Fatalf("check-ignore %q: %v", rel, err)
	return false
}

func TestCreateGitModeIgnoresEntriesKeepsArtifactsTrackable(t *testing.T) {
	withGlobalIgnore(t)
	isolatedRoot(t)
	tmp := t.TempDir()

	repoDir := filepath.Join(tmp, "repoA")
	setupTestGitRepo(t, repoDir)
	plainDir := filepath.Join(tmp, "notes") // becomes a symlink entry
	if err := os.MkdirAll(plainDir, 0755); err != nil {
		t.Fatal(err)
	}

	infos, err := Create("gitsess", []string{repoDir, plainDir}, CreateOpts{
		BranchFormat: "sy/{{.Session}}/{{.Repo}}",
		GitEnabled:   true,
	})
	if err != nil {
		t.Fatalf("Create: %v", err)
	}
	if len(infos) != 2 {
		t.Fatalf("expected 2 entries, got %d", len(infos))
	}

	sessionPath, err := GetPath("gitsess")
	if err != nil {
		t.Fatal(err)
	}

	if !isSessionGitRepo(sessionPath) {
		t.Fatal("session root was not initialized as a git repo")
	}

	// Worktree and symlink entries must be ignored.
	if !isIgnored(t, sessionPath, "repoA") {
		t.Error("worktree entry repoA should be ignored")
	}
	if !isIgnored(t, sessionPath, "notes") {
		t.Error("symlink entry notes should be ignored")
	}

	// Loose coordination artifacts must stay trackable despite the global ignore.
	mustWrite(t, filepath.Join(sessionPath, "AGENTS.md"), "# agents\n")
	mustWrite(t, filepath.Join(sessionPath, "openspec", "changes", "x", "proposal.md"), "# why\n")
	if isIgnored(t, sessionPath, "AGENTS.md") {
		t.Error("AGENTS.md should be trackable, but is ignored")
	}
	if isIgnored(t, sessionPath, "openspec/changes/x/proposal.md") {
		t.Error("openspec artifact should be trackable, but is ignored")
	}
}

func TestCreateNonGitModeHasNoRepoOrIgnore(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()
	repoDir := filepath.Join(tmp, "repoA")
	setupTestGitRepo(t, repoDir)

	if _, err := Create("plainsess", []string{repoDir}, CreateOpts{
		BranchFormat: "sy/{{.Session}}/{{.Repo}}",
	}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	sessionPath, err := GetPath("plainsess")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(sessionPath, ".git")); !os.IsNotExist(err) {
		t.Error("non-git-mode session must not have a .git directory")
	}
	if _, err := os.Stat(sessionIgnorePath(sessionPath)); !os.IsNotExist(err) {
		t.Error("non-git-mode session must not have a managed ignore file")
	}
}

func TestSyncSessionIgnoreNoOpOffGitMode(t *testing.T) {
	tmp := t.TempDir()
	sessionPath := filepath.Join(tmp, "sess")
	if err := os.MkdirAll(sessionPath, 0755); err != nil {
		t.Fatal(err)
	}
	// No .git → must be a silent no-op, never creating an ignore file.
	if err := syncSessionIgnore(sessionPath, []RepoInfo{{Name: "repoA"}}); err != nil {
		t.Fatalf("syncSessionIgnore off git mode: %v", err)
	}
	if _, err := os.Stat(sessionIgnorePath(sessionPath)); !os.IsNotExist(err) {
		t.Error("syncSessionIgnore must not write a file when .git is absent")
	}
}

func TestAddReposUpdatesIgnore(t *testing.T) {
	isolatedRoot(t)
	tmp := t.TempDir()

	repoA := filepath.Join(tmp, "repoA")
	setupTestGitRepo(t, repoA)
	if _, err := Create("addsess", []string{repoA}, CreateOpts{
		BranchFormat: "sy/{{.Session}}/{{.Repo}}",
		GitEnabled:   true,
	}); err != nil {
		t.Fatalf("Create: %v", err)
	}

	repoB := filepath.Join(tmp, "repoB")
	setupTestGitRepo(t, repoB)
	if _, _, err := AddRepos("addsess", []string{repoB}, CreateOpts{
		BranchFormat: "sy/{{.Session}}/{{.Repo}}",
	}); err != nil {
		t.Fatalf("AddRepos: %v", err)
	}

	sessionPath, err := GetPath("addsess")
	if err != nil {
		t.Fatal(err)
	}
	if !isIgnored(t, sessionPath, "repoB") {
		t.Error("added entry repoB should be ignored after AddRepos")
	}
}

func mustWrite(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		t.Fatal(err)
	}
}
