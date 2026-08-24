// Package attach answers which run traces opens, without being told. A reader
// who runs traces in a repository means the work happening in that repository,
// and a reader who runs it inside an agent session means that session.
//
// zoetrope reads the same directory for the same reason. The convention is
// Claude Code's: one directory per working directory under ~/.claude/projects,
// holding one transcript per session id.
package attach

import (
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/workspace"
)

// Env is the session id Claude Code exports to everything it runs, so a traces
// started from inside a session knows which one without a flag.
const Env = "CLAUDE_CODE_SESSION_ID"

func Current() string { return strings.TrimSpace(os.Getenv(Env)) }

// dirName is Claude Code's encoding: every character that is not a letter or a
// digit becomes a dash. /Users/x/work reads as -Users-x-work.
func dirName(dir string) string {
	out := make([]rune, 0, len(dir))
	for _, r := range dir {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9':
			out = append(out, r)
		default:
			out = append(out, '-')
		}
	}
	return string(out)
}

// ProjectDir is where Claude Code keeps this directory's transcripts.
func ProjectDir(dir string) string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	abs, err := filepath.Abs(dir)
	if err != nil {
		abs = dir
	}
	return filepath.Join(home, ".claude", "projects", dirName(abs))
}

// Scope lists the session ids that ran in dir or above it, newest first. A
// session is filed under the directory it started in, and a reader who cd's
// into a subdirectory still means the same work, so the walk goes up to the
// workspace boundary rather than stopping at the cwd.
func Scope(dir string) []string {
	abs, err := filepath.Abs(dir)
	if err != nil {
		abs = dir
	}
	stop := workspace.Root(abs)

	seen := map[string]bool{}
	out := []string{}
	for at := abs; ; at = filepath.Dir(at) {
		for _, id := range idsIn(at) {
			if seen[id] {
				continue
			}
			seen[id] = true
			out = append(out, id)
		}
		if at == stop || at == filepath.Dir(at) {
			break
		}
	}
	return out
}

// idsIn lists the sessions filed under one directory, newest first. A
// transcript is named for its session, so the listing is the answer and no file
// has to be read.
func idsIn(dir string) []string {
	entries, err := os.ReadDir(ProjectDir(dir))
	if err != nil {
		return nil
	}
	type seen struct {
		id  string
		mod int64
	}
	found := []seen{}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".jsonl") {
			continue
		}
		id := strings.TrimSuffix(name, ".jsonl")
		// A session id is a uuid. Anything else in here is not one, and a
		// prefix match on a stray name would scope traces to nothing.
		if len(id) != len("00000000-0000-0000-0000-000000000000") {
			continue
		}
		at := int64(0)
		if info, err := entry.Info(); err == nil {
			at = info.ModTime().UnixNano()
		}
		found = append(found, seen{id: id, mod: at})
	}
	sort.Slice(found, func(a, b int) bool { return found[a].mod > found[b].mod })

	out := make([]string, 0, len(found))
	for _, one := range found {
		out = append(out, one.id)
	}
	return out
}
