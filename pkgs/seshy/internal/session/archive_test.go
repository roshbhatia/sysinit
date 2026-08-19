package session

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
)

func defaultOpts() CreateOpts {
	return CreateOpts{BranchFormat: "sy/{{.Session}}/{{.Repo}}"}
}

func TestArchiveMovesSessionOutOfSessionsRoot(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("arch-me", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}

	archivePath, err := Archive("arch-me")
	if err != nil {
		t.Fatalf("archive: %v", err)
	}

	if Exists("arch-me") {
		t.Error("session still present in sessions root after archive")
	}
	if !ArchivedExists("arch-me") {
		t.Error("session not present in archive root after archive")
	}
	if _, err := os.Stat(filepath.Join(archivePath, "repo")); err != nil {
		t.Errorf("worktree missing from archived session: %v", err)
	}
}

func TestArchiveDefaultsBesideSessionsRoot(t *testing.T) {
	isolatedRoot(t)
	sessionsRoot := config.GetSessionsRoot()
	archiveRoot := config.GetArchiveRoot()

	if want := filepath.Join(filepath.Dir(sessionsRoot), "archive"); archiveRoot != want {
		t.Errorf("archive root = %q, want %q", archiveRoot, want)
	}
	if !strings.HasSuffix(archiveRoot, filepath.Join("seshy", "archive")) {
		t.Errorf("archive root %q should live under seshy/archive", archiveRoot)
	}
}

func TestArchiveKeepsWorktreeUsable(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("wt-arch", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}

	archivePath, err := Archive("wt-arch")
	if err != nil {
		t.Fatalf("archive: %v", err)
	}

	worktree := filepath.Join(archivePath, "repo")
	branch, err := GetCurrentBranch(worktree)
	if err != nil {
		t.Fatalf("archived worktree is not a working git checkout: %v", err)
	}
	if branch != "sy/wt-arch/repo" {
		t.Errorf("branch = %q, want sy/wt-arch/repo", branch)
	}

	// The main repo must know where the worktree moved to.
	out, err := exec.Command("git", "-C", repo, "worktree", "list").CombinedOutput()
	if err != nil {
		t.Fatalf("worktree list: %v\n%s", err, out)
	}
	if !strings.Contains(string(out), archivePath) {
		t.Errorf("main repo does not track archived worktree:\n%s", out)
	}
}

func TestArchivePreservesUncommittedWork(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("dirty", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}

	sessionPath, _ := GetPath("dirty")
	scratch := filepath.Join(sessionPath, "repo", "wip.txt")
	if err := os.WriteFile(scratch, []byte("in progress\n"), 0644); err != nil {
		t.Fatalf("write: %v", err)
	}

	archivePath, err := Archive("dirty")
	if err != nil {
		t.Fatalf("archive: %v", err)
	}

	data, err := os.ReadFile(filepath.Join(archivePath, "repo", "wip.txt"))
	if err != nil {
		t.Fatalf("uncommitted file lost: %v", err)
	}
	if string(data) != "in progress\n" {
		t.Errorf("uncommitted file content = %q", data)
	}
}

func TestArchiveMissingSession(t *testing.T) {
	isolatedRoot(t)
	if _, err := Archive("ghost"); err == nil {
		t.Error("expected error archiving a nonexistent session")
	}
}

func TestArchiveAlreadyArchived(t *testing.T) {
	isolatedRoot(t)
	// A plain directory, so recreating the session does not collide with the
	// branch the archived worktree still holds.
	repo := plainRepo(t, "plain")
	if _, err := Create("twice", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := Archive("twice"); err != nil {
		t.Fatalf("archive: %v", err)
	}
	if _, err := Create("twice", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("recreate: %v", err)
	}

	if _, err := Archive("twice"); err == nil {
		t.Error("expected error archiving over an existing archive entry")
	}
	if !Exists("twice") {
		t.Error("failed archive must leave the live session in place")
	}
}

func TestUnarchiveRestoresSession(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("round-trip", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := Archive("round-trip"); err != nil {
		t.Fatalf("archive: %v", err)
	}

	sessionPath, err := Unarchive("round-trip")
	if err != nil {
		t.Fatalf("unarchive: %v", err)
	}

	if !Exists("round-trip") {
		t.Error("session not restored to sessions root")
	}
	if ArchivedExists("round-trip") {
		t.Error("session still present in archive after unarchive")
	}
	branch, err := GetCurrentBranch(filepath.Join(sessionPath, "repo"))
	if err != nil {
		t.Fatalf("restored worktree is not a working git checkout: %v", err)
	}
	if branch != "sy/round-trip/repo" {
		t.Errorf("branch = %q, want sy/round-trip/repo", branch)
	}
}

func TestUnarchiveMissing(t *testing.T) {
	isolatedRoot(t)
	if _, err := Unarchive("ghost"); err == nil {
		t.Error("expected error unarchiving a nonexistent archive entry")
	}
}

func TestUnarchiveNameCollision(t *testing.T) {
	isolatedRoot(t)
	repo := plainRepo(t, "plain")
	if _, err := Create("clash", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := Archive("clash"); err != nil {
		t.Fatalf("archive: %v", err)
	}
	if _, err := Create("clash", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("recreate: %v", err)
	}

	if _, err := Unarchive("clash"); err == nil {
		t.Error("expected error unarchiving over an existing session")
	}
	if !ArchivedExists("clash") {
		t.Error("failed unarchive must leave the archive entry in place")
	}
}

func TestListArchived(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)

	for _, name := range []string{"a1", "a2"} {
		if _, err := Create(name, []string{repo}, defaultOpts()); err != nil {
			t.Fatalf("create %s: %v", name, err)
		}
		if _, err := Archive(name); err != nil {
			t.Fatalf("archive %s: %v", name, err)
		}
	}
	if _, err := Create("live", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create live: %v", err)
	}

	archived, err := ListArchived()
	if err != nil {
		t.Fatalf("list archived: %v", err)
	}
	if len(archived) != 2 {
		t.Fatalf("archived count = %d, want 2", len(archived))
	}
	for _, s := range archived {
		if s.Name == "live" {
			t.Error("live session leaked into the archived list")
		}
		if s.RepoCount != 1 {
			t.Errorf("%s repo count = %d, want 1", s.Name, s.RepoCount)
		}
	}

	live, err := List()
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(live) != 1 || live[0].Name != "live" {
		t.Errorf("live list = %v, want [live]", live)
	}
}

func TestListArchivedEmptyWhenNoArchiveRoot(t *testing.T) {
	isolatedRoot(t)
	archived, err := ListArchived()
	if err != nil {
		t.Fatalf("list archived: %v", err)
	}
	if len(archived) != 0 {
		t.Errorf("expected empty archived list, got %d", len(archived))
	}
}

func TestDeleteArchived(t *testing.T) {
	isolatedRoot(t)
	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("purge", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}
	if _, err := Archive("purge"); err != nil {
		t.Fatalf("archive: %v", err)
	}

	if err := DeleteArchived("purge", false); err != nil {
		t.Fatalf("delete archived: %v", err)
	}
	if ArchivedExists("purge") {
		t.Error("archived session still exists after delete")
	}

	out, err := exec.Command("git", "-C", repo, "branch", "--list", "sy/purge/repo").Output()
	if err != nil {
		t.Fatalf("branch list: %v", err)
	}
	if strings.TrimSpace(string(out)) != "" {
		t.Errorf("branch not cleaned up: %q", out)
	}
}

func TestArchiveHonoursArchiveDirConfig(t *testing.T) {
	isolatedRoot(t)
	custom := filepath.Join(config.GetSessionsRoot(), "..", "vault")
	writeConfig(t, "archiveDir: "+custom+"\n")

	repo := filepath.Join(t.TempDir(), "repo")
	setupTestGitRepo(t, repo)
	if _, err := Create("custom", []string{repo}, defaultOpts()); err != nil {
		t.Fatalf("create: %v", err)
	}

	archivePath, err := Archive("custom")
	if err != nil {
		t.Fatalf("archive: %v", err)
	}
	if filepath.Clean(archivePath) != filepath.Clean(filepath.Join(custom, "custom")) {
		t.Errorf("archive path = %q, want %q", archivePath, filepath.Join(custom, "custom"))
	}
}

// plainRepo creates a non-git directory, which sessions link rather than
// check out as a worktree.
func plainRepo(t *testing.T, name string) string {
	t.Helper()
	dir := filepath.Join(t.TempDir(), name)
	if err := os.MkdirAll(dir, 0755); err != nil {
		t.Fatalf("mkdir %s: %v", dir, err)
	}
	return dir
}

func writeConfig(t *testing.T, body string) {
	t.Helper()
	if err := os.MkdirAll(config.ConfigDir(), 0755); err != nil {
		t.Fatalf("mkdir config: %v", err)
	}
	if err := os.WriteFile(config.ConfigPath(), []byte(body), 0644); err != nil {
		t.Fatalf("write config: %v", err)
	}
}
