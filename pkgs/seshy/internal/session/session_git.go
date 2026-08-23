package session

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

// sharedArtifacts live in the session root and must remain trackable even when
// the user's global gitignore excludes them. They belong to no one agent.
var sharedArtifacts = []string{
	"AGENTS.md",
	"openspec/",
}

// fallbackAgentDirs is what the list was before agents.json carried a context
// dir per agent. It stands in when the registry is unreadable, so an unwritten
// or malformed file loses no artifact that was kept before.
var fallbackAgentDirs = []string{".claude/"}

// coordinationArtifacts is the shared set plus one directory per declared
// agent. Naming only Claude Code's here is what silently dropped a session's
// atomic, pi, or hermes config from git.
func coordinationArtifacts() []string {
	dirs := agents.ContextDirs()
	if len(dirs) == 0 {
		dirs = fallbackAgentDirs
	}
	return append(append([]string{}, sharedArtifacts...), dirs...)
}

// isSessionGitRepo reports whether the session directory has been initialised
// as a git repository.
func isSessionGitRepo(sessionPath string) bool {
	_, err := os.Stat(filepath.Join(sessionPath, ".git"))
	return err == nil
}

// sessionIgnorePath returns the path to the seshy-managed gitignore file
// inside the session root.
func sessionIgnorePath(sessionPath string) string {
	return filepath.Join(sessionPath, ".gitignore")
}

// syncSessionIgnore writes (or overwrites) the managed .gitignore in the
// session root. It is a no-op when the session is not a git repository.
//
// The file ignores every repo entry by name so they don't clutter git status,
// then negates the global ignores for the coordination artifacts so those
// remain trackable despite the user's global excludes.
func syncSessionIgnore(sessionPath string, repos []RepoInfo) error {
	if !isSessionGitRepo(sessionPath) {
		return nil
	}

	var lines []string
	lines = append(lines, "# seshy-managed: regenerated on session changes — do not edit")
	for _, r := range repos {
		lines = append(lines, r.Name)
	}
	for _, a := range coordinationArtifacts() {
		lines = append(lines, "!"+a)
	}

	content := strings.Join(lines, "\n") + "\n"
	return os.WriteFile(sessionIgnorePath(sessionPath), []byte(content), 0644)
}
