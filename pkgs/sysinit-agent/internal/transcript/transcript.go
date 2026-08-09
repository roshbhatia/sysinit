// Package transcript implements the `transcript-link` command: make a harness's
// own transcript reachable by a stable name.
//
// Claude only. It is the one harness whose hook payload carries a transcript
// reference at all. The others were checked rather than assumed: opencode's
// payload is typed `{ type, properties: { sessionID, status } }`, pi's handlers
// carry `toolName` and `input`, and codex's hooks are fixed argv that read no
// stdin. Ten of eleven harnesses are uncovered, and nothing here scrapes a
// terminal to close that gap.
//
// # A link, not a copy
//
// The published name is a symlink to the harness's own file, so
// `sysinit-agent watch transcript` tails a session that is still being written.
// A copy would be a second producer of the same bytes, would be stale between
// refreshes, and would double the disk of a long session.
//
// The cost is stated rather than hidden: this does not archive anything. If the
// harness deletes or moves its transcript, the link dangles and the viewer says
// nothing is there. Outliving the harness is a different job from being
// reachable, and this is the second one.
//
// # The sidecar
//
// A transcript is named by harness session id, which the owner does not know and
// cannot type. So each link gets a sidecar recording the worktree it belongs to,
// which is what lets the viewer resolve a transcript from the current directory.
package transcript

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
)

const Summary = "publish a harness transcript under a stable name"

const usageText = `Publish a harness transcript under a stable name.

Usage:
  transcript-link <harness>          read a hook payload on stdin

Reads the hook's JSON payload on stdin and publishes:
  <agentTranscripts>/<harness>/<session>.jsonl   a symlink to the harness's file
  <agentTranscripts>/<harness>/<session>.json    the worktree it belongs to

The link is how ` + "`watch transcript`" + ` reaches a live session. The sidecar is how
it reaches one from a directory, since nobody knows a harness session id.

Never fails a hook. A payload it cannot use is a silent no-op, because a hook
that blocks a prompt to report a bookkeeping problem is worse than no
bookkeeping.
`

// SidecarVersion is the sidecar's schema version. The link is the artifact; this
// is only the index that makes it findable.
const SidecarVersion = 1

// sidecar records what a session id cannot: which worktree it belongs to.
type sidecar struct {
	Version    int    `json:"version"`
	Harness    string `json:"harness"`
	Session    string `json:"session"`
	Repo       string `json:"repo"`
	Worktree   string `json:"worktree"`
	Transcript string `json:"transcript"`
	Updated    int64  `json:"updated"`
}

// payload is the subset of a hook payload this reads. Every field is optional:
// the shape is the harness's, not this repository's, and a missing field is
// handled rather than asserted away.
type payload struct {
	SessionID      string `json:"session_id"`
	TranscriptPath string `json:"transcript_path"`
	Cwd            string `json:"cwd"`
}

func Run(args []string) int {
	if len(args) != 1 || args[0] == "-h" || args[0] == "--help" {
		out := os.Stderr
		code := 2
		if len(args) == 1 {
			out, code = os.Stdout, 0
		}
		fmt.Fprint(out, usageText)
		return code
	}
	harness := args[0]
	if strings.Contains(harness, "/") || harness == "" {
		return 0
	}

	var event payload
	if json.NewDecoder(os.Stdin).Decode(&event) != nil {
		return 0
	}
	session := sanitize(event.SessionID)
	if session == "" {
		return 0
	}

	native := resolveTranscript(event.TranscriptPath, session)
	if native == "" {
		return 0
	}

	dir := filepath.Join(paths.AgentTranscripts(), harness)
	if os.MkdirAll(dir, 0o755) != nil {
		return 0
	}

	link := filepath.Join(dir, session+".jsonl")
	// Replace rather than skip. `--resume` moves a session's file, so a link
	// written on an earlier run can point at the wrong one, and a link that is
	// merely present is not a link that is correct.
	os.Remove(link)
	if os.Symlink(native, link) != nil {
		return 0
	}

	publishSidecar(filepath.Join(dir, session+".json"), sidecar{
		Version:    SidecarVersion,
		Harness:    harness,
		Session:    session,
		Repo:       repoName(event.Cwd),
		Worktree:   worktree(event.Cwd),
		Transcript: native,
		Updated:    time.Now().Unix(),
	})
	return 0
}

// sanitize keeps a session id usable as one path element. A harness owns the id
// and this owns the directory, so the id is checked rather than trusted.
func sanitize(id string) string {
	if strings.ContainsAny(id, "/\\") || id == "." || id == ".." {
		return ""
	}
	return strings.TrimSuffix(id, ".jsonl")
}

// resolveTranscript prefers the payload's own path and falls back to the session
// id, because a resumed session can carry a path that no longer names a file.
//
// The glob is claude's layout. It is here rather than in a shared place because
// it is one harness's private detail, and the next harness to carry a transcript
// reference will not share it.
func resolveTranscript(hint, session string) string {
	if hint != "" {
		if info, err := os.Stat(hint); err == nil && info.Mode().IsRegular() {
			return hint
		}
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	matches, err := filepath.Glob(filepath.Join(home, ".claude", "projects", "*", session+".jsonl"))
	if err != nil || len(matches) == 0 {
		return ""
	}
	// Newest wins: the same session id can appear under two project directories
	// when a worktree is moved, and the one still being written is the one worth
	// publishing.
	sort.Slice(matches, func(i, j int) bool {
		return modTime(matches[i]).After(modTime(matches[j]))
	})
	return matches[0]
}

func modTime(path string) time.Time {
	info, err := os.Stat(path)
	if err != nil {
		return time.Time{}
	}
	return info.ModTime()
}

// worktree is the repository root holding cwd, or cwd itself outside one. A
// directory is still a usable key when it is not a repository.
func worktree(cwd string) string {
	if cwd == "" {
		return ""
	}
	if root, err := rootOf(cwd); err == nil && root != "" {
		return root
	}
	return strings.TrimRight(cwd, "/")
}

func repoName(cwd string) string {
	root := worktree(cwd)
	if root == "" {
		return ""
	}
	return filepath.Base(root)
}

// rootOf answers for cwd rather than for this process's directory. A hook runs
// wherever the harness left it, which is not reliably the session's worktree.
//
// A variable so a test can answer without a repository on disk.
var rootOf = repo.RootAt

// publishSidecar writes through a temporary file, so a reader never sees half a
// record. Failure is silent for the reason in the usage text.
func publishSidecar(path string, record sidecar) {
	body, err := json.Marshal(record)
	if err != nil {
		return
	}
	tmp, err := os.CreateTemp(filepath.Dir(path), ".sidecar-*")
	if err != nil {
		return
	}
	name := tmp.Name()
	if _, err := tmp.Write(append(body, '\n')); err != nil {
		tmp.Close()
		os.Remove(name)
		return
	}
	if tmp.Close() != nil || os.Rename(name, path) != nil {
		os.Remove(name)
	}
}

// FindByWorktree returns the newest published session for a worktree, so a
// viewer can resolve a transcript from a directory. Empty when there is none.
//
// Exported because the viewer is the only caller and the alternative is the
// viewer re-deriving this layout, which is the duplication the sidecar exists to
// remove.
func FindByWorktree(harness, dir string) (session string, ok bool) {
	dir = strings.TrimRight(dir, "/")
	if dir == "" {
		return "", false
	}
	root := filepath.Join(paths.AgentTranscripts(), harness)
	entries, err := os.ReadDir(root)
	if err != nil {
		return "", false
	}

	var newest sidecar
	for _, entry := range entries {
		if !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}
		body, err := os.ReadFile(filepath.Join(root, entry.Name()))
		if err != nil {
			continue
		}
		var record sidecar
		if json.Unmarshal(body, &record) != nil {
			continue
		}
		if strings.TrimRight(record.Worktree, "/") != dir {
			continue
		}
		if record.Updated >= newest.Updated {
			newest = record
		}
	}
	if newest.Session == "" {
		return "", false
	}
	return newest.Session, true
}
