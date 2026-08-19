package session

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/git"
)

func gitExec(repoPath string, args ...string) (string, error) {
	return git.Output(repoPath, args...)
}

func IsGitRepo(path string) bool { return git.IsRepo(path) }

func GetRepoBasename(path string) string {
	return filepath.Base(path)
}

func GetCurrentBranch(path string) (string, error) {
	return git.Branch(path)
}

// disambiguatedName generates a unique worktree directory name using bare basename.
// Tries: basename → <parent>-<basename> → <basename>-2, -3, etc.
func disambiguatedName(repoPath, sessionPath string) string {
	basename := GetRepoBasename(repoPath)

	if _, err := os.Stat(filepath.Join(sessionPath, basename)); os.IsNotExist(err) {
		return basename
	}

	parent := filepath.Base(filepath.Dir(repoPath))
	if parent != "" && parent != "." && parent != "/" {
		candidate := fmt.Sprintf("%s-%s", parent, basename)
		if _, err := os.Stat(filepath.Join(sessionPath, candidate)); os.IsNotExist(err) {
			return candidate
		}
	}

	for i := 2; ; i++ {
		candidate := fmt.Sprintf("%s-%d", basename, i)
		if _, err := os.Stat(filepath.Join(sessionPath, candidate)); os.IsNotExist(err) {
			return candidate
		}
	}
}

// CreateWorktree creates a git worktree for the given repo in the session directory.
// branchName is a pre-rendered branch name (from template or --branch flag).
func CreateWorktree(repoPath, sessionPath, branchName string) (string, error) {
	worktreeName := disambiguatedName(repoPath, sessionPath)
	worktreePath := filepath.Join(sessionPath, worktreeName)

	// Primary strategy: create a new branch from HEAD
	_, err := gitExec(repoPath, "worktree", "add", worktreePath, "-b", branchName, "HEAD")
	if err != nil {
		// Fallback: branch already exists, reuse it
		_, err2 := gitExec(repoPath, "worktree", "add", worktreePath, branchName)
		if err2 != nil {
			return "", fmt.Errorf("failed to create worktree (primary: %w) (fallback: %v)", err, err2)
		}
	}

	return worktreePath, nil
}

// CreateSymlink creates a symlink for non-git directories.
func CreateSymlink(target, sessionPath string) (string, error) {
	basename := filepath.Base(target)
	linkPath := filepath.Join(sessionPath, basename)

	if _, err := os.Stat(linkPath); err == nil {
		parent := filepath.Base(filepath.Dir(target))
		if parent != "" && parent != "." && parent != "/" {
			linkPath = filepath.Join(sessionPath, fmt.Sprintf("%s-%s", parent, basename))
		}
		if _, err := os.Stat(linkPath); err == nil {
			for i := 2; ; i++ {
				candidate := filepath.Join(sessionPath, fmt.Sprintf("%s-%d", basename, i))
				if _, err := os.Stat(candidate); os.IsNotExist(err) {
					linkPath = candidate
					break
				}
			}
		}
	}

	if err := os.Symlink(target, linkPath); err != nil {
		return "", fmt.Errorf("failed to create symlink for %s: %w", target, err)
	}
	return linkPath, nil
}

// removeWorktree unregisters a worktree from its main repo.
//
// force adds the second --force that git demands before it will remove a
// locked worktree. Without it, a single locked worktree leaves both the
// registration and the branch behind.
func removeWorktree(mainRepoPath, worktreePath string, force bool) error {
	args := []string{"worktree", "remove", worktreePath, "--force"}
	if force {
		args = append(args, "--force")
	}
	_, removeErr := gitExec(mainRepoPath, args...)
	if removeErr == nil {
		return nil
	}

	// prune clears registrations whose directory is already gone, which is the
	// common reason remove fails. It exits 0 even when it clears nothing, so
	// confirm the registration actually went away rather than trusting it.
	gitExec(mainRepoPath, "worktree", "prune")
	if worktreeRegistered(mainRepoPath, worktreePath) {
		return removeErr
	}
	return nil
}

// worktreeRegistered reports whether mainRepo still lists worktreePath.
func worktreeRegistered(mainRepoPath, worktreePath string) bool {
	out, err := gitExec(mainRepoPath, "worktree", "list", "--porcelain")
	if err != nil {
		return false
	}
	target := realPath(worktreePath)
	for _, line := range strings.Split(out, "\n") {
		listed, ok := strings.CutPrefix(line, "worktree ")
		if ok && realPath(listed) == target {
			return true
		}
	}
	return false
}

// realPath resolves symlinks where it can, falling back to a lexical clean for
// paths that no longer exist.
func realPath(path string) string {
	if resolved, err := filepath.EvalSymlinks(path); err == nil {
		return resolved
	}
	return filepath.Clean(path)
}

// CleanupWorktrees removes all git worktrees in a session directory and deletes their branches.
// Continues on individual failures and returns a combined error if any worktree could not be removed.
// force is passed through to worktree removal so locked worktrees can be torn down.
func CleanupWorktrees(sessionPath string, force bool) error {
	entries, err := os.ReadDir(sessionPath)
	if err != nil {
		return fmt.Errorf("failed to read session directory: %w", err)
	}

	var errs []error

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		entryPath := filepath.Join(sessionPath, entry.Name())

		_, err := gitExec(entryPath, "rev-parse", "--is-inside-work-tree")
		if err != nil {
			continue
		}

		branchName, _ := gitExec(entryPath, "rev-parse", "--abbrev-ref", "HEAD")

		gitCommonDir, err := gitExec(entryPath, "rev-parse", "--git-common-dir")
		if err != nil {
			errs = append(errs, fmt.Errorf("could not locate main repo for %s: %w", entry.Name(), err))
			continue
		}

		if !filepath.IsAbs(gitCommonDir) {
			gitCommonDir = filepath.Join(entryPath, gitCommonDir)
		}
		mainRepoPath := filepath.Dir(gitCommonDir)

		// standalone clone: the entry IS the main repo — skip rather than
		// trying to remove the main working tree via git worktree remove.
		if filepath.Clean(mainRepoPath) == filepath.Clean(entryPath) {
			continue
		}

		if err := removeWorktree(mainRepoPath, entryPath, force); err != nil {
			errs = append(errs, fmt.Errorf("failed to remove worktree %s: %w", entry.Name(), err))
			continue
		}

		if branchName != "" && branchName != "HEAD" {
			mainBranch, _ := gitExec(mainRepoPath, "rev-parse", "--abbrev-ref", "HEAD")
			if mainBranch != branchName {
				gitExec(mainRepoPath, "branch", "-D", branchName)
			}
		}
	}

	return errors.Join(errs...)
}

// RemoveRepoEntry removes a single repo entry from a session directory.
// For git worktrees: removes the worktree and deletes the branch.
// For symlinks: removes the symlink.
// force is passed through to worktree removal so locked worktrees can be removed.
func RemoveRepoEntry(sessionPath, repoName string, force bool) error {
	entryPath := filepath.Join(sessionPath, repoName)
	info, err := os.Lstat(entryPath)
	if err != nil {
		return fmt.Errorf("repo %q not found in session: %w", repoName, err)
	}

	if info.Mode()&os.ModeSymlink != 0 {
		return os.Remove(entryPath)
	}

	if !info.IsDir() {
		return fmt.Errorf("%q is not a directory or symlink", repoName)
	}

	branchName, _ := gitExec(entryPath, "rev-parse", "--abbrev-ref", "HEAD")
	gitCommonDir, err := gitExec(entryPath, "rev-parse", "--git-common-dir")
	if err != nil {
		return os.RemoveAll(entryPath)
	}

	if !filepath.IsAbs(gitCommonDir) {
		gitCommonDir = filepath.Join(entryPath, gitCommonDir)
	}
	mainRepoPath := filepath.Dir(gitCommonDir)

	// standalone clone: the entry IS the main repo, not a registered worktree —
	// git worktree remove would fail, so just delete the directory.
	if filepath.Clean(mainRepoPath) == filepath.Clean(entryPath) {
		return os.RemoveAll(entryPath)
	}

	if err := removeWorktree(mainRepoPath, entryPath, force); err != nil {
		return fmt.Errorf("failed to remove worktree: %w", err)
	}

	if branchName != "" && branchName != "HEAD" {
		mainBranch, _ := gitExec(mainRepoPath, "rev-parse", "--abbrev-ref", "HEAD")
		if mainBranch != branchName {
			gitExec(mainRepoPath, "branch", "-D", branchName)
		}
	}

	return nil
}

// GetWorktreeMainRepo finds the main repository for a worktree.
// --git-common-dir can return a relative path (e.g. ".git") for standalone
// clones, so we resolve it relative to the worktree path before computing the
// parent directory.
func GetWorktreeMainRepo(worktreePath string) (string, error) {
	gitCommonDir, err := gitExec(worktreePath, "rev-parse", "--git-common-dir")
	if err != nil {
		return "", err
	}
	if !filepath.IsAbs(gitCommonDir) {
		gitCommonDir = filepath.Join(worktreePath, gitCommonDir)
	}
	return filepath.Dir(gitCommonDir), nil
}

// ListRepoSources returns the resolved real paths for all repo sources in a session.
func ListRepoSources(sessionPath string) ([]string, error) {
	entries, err := os.ReadDir(sessionPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read session directory: %w", err)
	}

	var sources []string
	for _, entry := range entries {
		entryPath := filepath.Join(sessionPath, entry.Name())

		info, err := os.Lstat(entryPath)
		if err != nil {
			continue
		}

		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(entryPath)
			if err != nil {
				continue
			}
			resolved, err := filepath.EvalSymlinks(target)
			if err != nil {
				resolved = target
			}
			sources = append(sources, resolved)
			continue
		}

		if !info.IsDir() {
			continue
		}

		gitCommonDir, err := gitExec(entryPath, "rev-parse", "--git-common-dir")
		if err != nil {
			continue
		}

		if !filepath.IsAbs(gitCommonDir) {
			gitCommonDir = filepath.Join(entryPath, gitCommonDir)
		}
		mainRepoPath := filepath.Dir(gitCommonDir)
		resolved, err := filepath.EvalSymlinks(mainRepoPath)
		if err != nil {
			resolved = mainRepoPath
		}
		sources = append(sources, resolved)
	}

	return sources, nil
}
