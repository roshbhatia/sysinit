package session

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/tmpl"
)

// Session represents a seshy session.
type Session struct {
	Name         string
	Path         string
	RepoCount    int
	LastModified time.Time
}

// RepoInfo describes a repo that was created in a session.
type RepoInfo struct {
	Name       string // basename in session dir
	Path       string // absolute worktree/symlink path
	SourcePath string // absolute original repo path
	Branch     string // rendered branch name (empty for non-git)
}

// AddResult holds the outcome of adding multiple repos.
type AddResult struct {
	Added   []string
	Skipped []string
	Errors  map[string]error
}

// Err returns a combined error if any repos failed to add, or nil.
func (r AddResult) Err() error {
	if len(r.Errors) == 0 {
		return nil
	}
	var parts []string
	for repo, err := range r.Errors {
		parts = append(parts, fmt.Sprintf("  %s: %v", repo, err))
	}
	return fmt.Errorf("failed to add %d repo(s):\n%s", len(r.Errors), strings.Join(parts, "\n"))
}

// ValidateSessionName checks if a session name is valid.
func ValidateSessionName(name string) error {
	if name == "" {
		return fmt.Errorf("session name cannot be empty")
	}
	for _, c := range name {
		if (c < 'a' || c > 'z') && (c < 'A' || c > 'Z') &&
			(c < '0' || c > '9') && c != '-' && c != '_' {
			return fmt.Errorf("session name must contain only letters, numbers, hyphens, and underscores")
		}
	}
	return nil
}

// GetPath returns the absolute path to a session.
func GetPath(name string) (string, error) {
	root := config.GetSessionsRoot()
	sessionPath := filepath.Join(root, name)
	if _, err := os.Stat(sessionPath); os.IsNotExist(err) {
		return "", fmt.Errorf("session '%s' not found", name)
	}
	return sessionPath, nil
}

// Exists checks if a session exists.
func Exists(name string) bool {
	root := config.GetSessionsRoot()
	_, err := os.Stat(filepath.Join(root, name))
	return err == nil
}

// branchForRepo computes the branch name for a repo.
func branchForRepo(branchFormat, branchOverride, sessionName, repoPath string) (string, error) {
	if branchOverride != "" {
		if err := ValidateBranchName(branchOverride); err != nil {
			return "", err
		}
		return branchOverride, nil
	}
	return RenderBranchName(branchFormat, sessionName, GetRepoBasename(repoPath))
}

// CreateOpts holds options for session creation.
type CreateOpts struct {
	BranchFormat   string
	BranchOverride string
	// GitEnabled initialises the session directory as a git repository and
	// maintains a .gitignore that hides repo entries while keeping coordination
	// artifacts (AGENTS.md, openspec/, .claude/) trackable.
	GitEnabled bool
}

// Create creates a new session with the given repos. Atomic: on failure,
// all previously created worktrees and branches are cleaned up.
// Returns RepoInfo for each successfully created repo.
func Create(name string, repoPaths []string, opts CreateOpts) ([]RepoInfo, error) {
	if err := ValidateSessionName(name); err != nil {
		return nil, err
	}
	if Exists(name) {
		return nil, fmt.Errorf("session '%s' already exists", name)
	}

	root := config.GetSessionsRoot()
	sessionPath := filepath.Join(root, name)

	if err := os.MkdirAll(sessionPath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create session directory: %w", err)
	}

	if opts.GitEnabled {
		if _, err := gitExec(sessionPath, "init"); err != nil {
			_ = os.RemoveAll(sessionPath)
			return nil, fmt.Errorf("failed to init session git repo: %w", err)
		}
	}

	type created struct {
		worktreePath string
		repoPath     string
		branchName   string
	}
	var createdList []created
	var repoInfos []RepoInfo

	cleanup := func() {
		for i := len(createdList) - 1; i >= 0; i-- {
			c := createdList[i]
			if IsGitRepo(c.repoPath) && c.branchName != "" {
				_ = removeWorktree(c.repoPath, c.worktreePath, true)
				_, _ = gitExec(c.repoPath, "branch", "-D", c.branchName)
			}
		}
		_ = os.RemoveAll(sessionPath)
	}

	for _, repoPath := range repoPaths {
		// Resolve to absolute path so symlinks are never self-referential.
		if abs, err := filepath.Abs(repoPath); err == nil {
			repoPath = abs
		}

		if IsGitRepo(repoPath) {
			branch, err := branchForRepo(opts.BranchFormat, opts.BranchOverride, name, repoPath)
			if err != nil {
				cleanup()
				return nil, fmt.Errorf("branch name for %s: %w", repoPath, err)
			}

			wtPath, err := CreateWorktree(repoPath, sessionPath, branch)
			if err != nil {
				cleanup()
				return nil, fmt.Errorf("failed to create worktree for %s: %w", repoPath, err)
			}
			createdList = append(createdList, created{worktreePath: wtPath, repoPath: repoPath, branchName: branch})
			repoInfos = append(repoInfos, RepoInfo{
				Name:       filepath.Base(wtPath),
				Path:       wtPath,
				SourcePath: repoPath,
				Branch:     branch,
			})
		} else {
			linkPath, err := CreateSymlink(repoPath, sessionPath)
			if err != nil {
				cleanup()
				return nil, fmt.Errorf("failed to create symlink for %s: %w", repoPath, err)
			}
			repoInfos = append(repoInfos, RepoInfo{
				Name:       filepath.Base(linkPath),
				Path:       linkPath,
				SourcePath: repoPath,
			})
		}
	}

	if opts.GitEnabled {
		if err := syncSessionIgnore(sessionPath, repoInfos); err != nil {
			cleanup()
			return nil, fmt.Errorf("failed to sync session ignore: %w", err)
		}
	}

	return repoInfos, nil
}

// List returns all sessions.
func List() ([]Session, error) {
	return listIn(config.GetSessionsRoot())
}

// listIn returns every session directory under root.
func listIn(root string) ([]Session, error) {
	if _, err := os.Stat(root); os.IsNotExist(err) {
		return []Session{}, nil
	}

	entries, err := os.ReadDir(root)
	if err != nil {
		return nil, fmt.Errorf("failed to read sessions directory: %w", err)
	}

	sessions := make([]Session, 0)
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		sessionPath := filepath.Join(root, entry.Name())
		info, err := entry.Info()
		if err != nil {
			continue
		}

		repoCount := 0
		sessionEntries, err := os.ReadDir(sessionPath)
		if err == nil {
			for _, se := range sessionEntries {
				if strings.HasPrefix(se.Name(), ".") {
					continue
				}
				if se.IsDir() || se.Type()&os.ModeSymlink != 0 {
					repoCount++
				}
			}
		}

		sessions = append(sessions, Session{
			Name:         entry.Name(),
			Path:         sessionPath,
			RepoCount:    repoCount,
			LastModified: info.ModTime(),
		})
	}

	return sessions, nil
}

func resolveRepoPath(path string) string {
	resolved, err := filepath.EvalSymlinks(path)
	if err != nil {
		return path
	}
	return resolved
}

// AddRepos adds repositories to an existing session (best-effort).
// Returns AddResult, RepoInfo for newly added repos, and error.
func AddRepos(name string, repoPaths []string, opts CreateOpts) (AddResult, []RepoInfo, error) {
	sessionPath, err := GetPath(name)
	if err != nil {
		return AddResult{}, nil, err
	}

	result := AddResult{Errors: make(map[string]error)}
	var newRepos []RepoInfo

	existingSources, err := ListRepoSources(sessionPath)
	if err != nil {
		existingSources = nil
	}
	existingSet := make(map[string]bool, len(existingSources))
	for _, s := range existingSources {
		existingSet[resolveRepoPath(s)] = true
	}

	for _, repoPath := range repoPaths {
		// Resolve to absolute path so symlinks are never self-referential.
		if abs, err := filepath.Abs(repoPath); err == nil {
			repoPath = abs
		}

		resolved := resolveRepoPath(repoPath)
		if existingSet[resolved] {
			result.Skipped = append(result.Skipped, repoPath)
			continue
		}

		if IsGitRepo(repoPath) {
			branch, err := branchForRepo(opts.BranchFormat, opts.BranchOverride, name, repoPath)
			if err != nil {
				result.Errors[repoPath] = err
				continue
			}
			wtPath, err := CreateWorktree(repoPath, sessionPath, branch)
			if err != nil {
				result.Errors[repoPath] = err
				continue
			}
			newRepos = append(newRepos, RepoInfo{
				Name:       filepath.Base(wtPath),
				Path:       wtPath,
				SourcePath: repoPath,
				Branch:     branch,
			})
		} else {
			linkPath, err := CreateSymlink(repoPath, sessionPath)
			if err != nil {
				result.Errors[repoPath] = err
				continue
			}
			newRepos = append(newRepos, RepoInfo{
				Name:       filepath.Base(linkPath),
				Path:       linkPath,
				SourcePath: repoPath,
			})
		}

		result.Added = append(result.Added, repoPath)
		existingSet[resolved] = true
	}

	if isSessionGitRepo(sessionPath) {
		allRepos := GetSessionRepoInfos(sessionPath)
		_ = syncSessionIgnore(sessionPath, allRepos)
	}

	return result, newRepos, nil
}

// BuildTemplateData creates TemplateData from session info.
func BuildTemplateData(name, sessionPath string, repos []RepoInfo) tmpl.TemplateData {
	repoData := make([]tmpl.RepoData, len(repos))
	for i, r := range repos {
		repoData[i] = tmpl.RepoData{
			Name:   r.Name,
			Path:   r.Path,
			Source: r.SourcePath,
			Branch: r.Branch,
		}
	}
	return tmpl.NewTemplateData(name, sessionPath, repoData)
}

// GetSessionRepoInfos returns RepoInfo for every repo entry in the session directory.
func GetSessionRepoInfos(sessionPath string) []RepoInfo {
	entries, err := os.ReadDir(sessionPath)
	if err != nil {
		return nil
	}
	var repos []RepoInfo
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), ".") {
			continue
		}
		entryPath := filepath.Join(sessionPath, e.Name())
		info, err := os.Lstat(entryPath)
		if err != nil {
			continue
		}
		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(entryPath)
			if err != nil {
				continue
			}
			resolved, _ := filepath.EvalSymlinks(target)
			if resolved == "" {
				resolved = target
			}
			repos = append(repos, RepoInfo{Name: e.Name(), Path: entryPath, SourcePath: resolved})
		} else if info.IsDir() {
			mainRepo, err := GetWorktreeMainRepo(entryPath)
			if err != nil {
				continue
			}
			branch, _ := GetCurrentBranch(entryPath)
			repos = append(repos, RepoInfo{Name: e.Name(), Path: entryPath, SourcePath: mainRepo, Branch: branch})
		}
	}
	return repos
}

// RenameSession renames a session directory and repairs git worktree registrations.
// Branch names are not changed.
func RenameSession(oldName, newName string) error {
	if err := ValidateSessionName(newName); err != nil {
		return err
	}
	if !Exists(oldName) {
		return fmt.Errorf("session '%s' not found", oldName)
	}
	if Exists(newName) {
		return fmt.Errorf("session '%s' already exists", newName)
	}

	root := config.GetSessionsRoot()
	oldPath := filepath.Join(root, oldName)
	newPath := filepath.Join(root, newName)

	if err := os.Rename(oldPath, newPath); err != nil {
		return fmt.Errorf("failed to rename session: %w", err)
	}

	repairWorktreeRegistrations(newPath)

	return nil
}

// repairWorktreeRegistrations updates each main repo's record of where its
// worktrees live after a session directory has moved. Worktrees are grouped by
// main repo so we issue one repair call per repo.
func repairWorktreeRegistrations(sessionPath string) {
	mainToWorktrees := make(map[string][]string)
	entries, _ := os.ReadDir(sessionPath)
	for _, e := range entries {
		if !e.IsDir() || strings.HasPrefix(e.Name(), ".") {
			continue
		}
		entryPath := filepath.Join(sessionPath, e.Name())
		mainRepo, err := GetWorktreeMainRepo(entryPath)
		if err != nil {
			continue
		}
		mainToWorktrees[mainRepo] = append(mainToWorktrees[mainRepo], entryPath)
	}
	for mainRepo, worktrees := range mainToWorktrees {
		args := append([]string{"worktree", "repair"}, worktrees...)
		_, _ = gitExec(mainRepo, args...)
	}
}

// ErrCleanupIncomplete reports that a session directory was removed but some
// worktree registrations or branches were left behind.
var ErrCleanupIncomplete = errors.New("worktree cleanup incomplete")

// Delete removes a session and cleans up worktrees + branches.
//
// When force is set, a worktree cleanup failure no longer stops the session
// directory from being removed. The cleanup failure is still reported, wrapped
// in ErrCleanupIncomplete, so the caller can tell a partial success from a
// refusal to act.
func Delete(name string, force bool) error {
	sessionPath, err := GetPath(name)
	if err != nil {
		return err
	}
	return deleteAt(sessionPath, force)
}

func deleteAt(sessionPath string, force bool) error {
	cleanupErr := CleanupWorktrees(sessionPath, force)
	if cleanupErr != nil && !force {
		return fmt.Errorf("failed to cleanup worktrees: %w", cleanupErr)
	}

	if err := os.RemoveAll(sessionPath); err != nil {
		return fmt.Errorf("failed to remove session directory: %w", err)
	}

	if cleanupErr != nil {
		return fmt.Errorf("%w: %w", ErrCleanupIncomplete, cleanupErr)
	}
	return nil
}
