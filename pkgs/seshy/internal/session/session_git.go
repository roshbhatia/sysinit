package session

import (
	"os"
	"path/filepath"
	"strings"
)

// coordinationArtifacts are files/dirs that live in the session root and must
// remain trackable even when the user's global gitignore excludes them.
var coordinationArtifacts = []string{
	"AGENTS.md",
	"openspec/",
	".claude/",
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
// then negates the global ignores for coordination artifacts (AGENTS.md,
// openspec/, .claude/) so those remain trackable despite the user's global
// excludes.
func syncSessionIgnore(sessionPath string, repos []RepoInfo) error {
	if !isSessionGitRepo(sessionPath) {
		return nil
	}

	var lines []string
	lines = append(lines, "# seshy-managed: regenerated on session changes — do not edit")
	for _, r := range repos {
		lines = append(lines, r.Name)
	}
	for _, a := range coordinationArtifacts {
		lines = append(lines, "!"+a)
	}

	content := strings.Join(lines, "\n") + "\n"
	return os.WriteFile(sessionIgnorePath(sessionPath), []byte(content), 0644)
}
