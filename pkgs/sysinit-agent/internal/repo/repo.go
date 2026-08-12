// Package repo derives the repository root and the note paths under it.
package repo

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
)

// ErrOutsideRoot is returned for a path that does not name a file inside the
var ErrOutsideRoot = errors.New("path is not inside the repository")

// Root returns the working tree's top level.
func Root() (string, error) {
	return RootAt("")
}

// RootAt returns the top level of the working tree holding dir, or of the
func RootAt(dir string) (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	cmd.Dir = dir
	cmd.Env = filterEnv(os.Environ(), "GIT_DIR", "GIT_WORK_TREE", "GIT_INDEX_FILE")
	out, err := cmd.Output()
	if err != nil {
		return "", errors.New("not inside a git repository")
	}
	root := strings.TrimRight(string(out), "\n")
	if root == "" {
		return "", errors.New("not inside a git repository")
	}
	return root, nil
}

func filterEnv(env []string, drop ...string) []string {
	kept := make([]string, 0, len(env))
	for _, entry := range env {
		skip := false
		for _, name := range drop {
			if strings.HasPrefix(entry, name+"=") {
				skip = true
				break
			}
		}
		if !skip {
			kept = append(kept, entry)
		}
	}
	return kept
}

// NoteFile returns the note-record path for root.
func NoteFile(root string) string {
	return noteBase(root) + ".json"
}

// ExportFile returns the path of the viewer-shaped export derived from the
func ExportFile(root string) string {
	return noteBase(root) + ".hunk.json"
}

func noteBase(root string) string {
	return keyed(paths.AgentDiffNotes(), root)
}

// EditLogFile returns the edit-event log path for root.
func EditLogFile(root string) string {
	return keyed(paths.AgentEdits(), root) + ".jsonl"
}

// WorkerDir returns the directory holding one workspace's worker state: the pane
// id, its mux generation, the run counter, and every run's log and exit code.
//
// A directory rather than a file, because a workspace has many runs and one
// pane. The name is the same keyed shape the note and the edit log use, so a
// prune can tell a current key from the superseded `pane-N` shape by matching the
// name alone.
func WorkerDir(root string) string {
	return keyed(paths.AgentWorker(), root)
}

// WorkerKeyed reports whether name is a current-shape worker key: a basename, a
// hyphen, and the 16 hex characters keyed appends.
//
// Checked before the superseded `pane-N` shape, never after. A workspace whose
// basename is literally `pane-3` keys to `pane-3-<16 hex>`, which an unanchored
// `pane-*` test would claim.
func WorkerKeyed(name string) bool {
	cut := strings.LastIndex(name, "-")
	if cut <= 0 || len(name)-cut-1 != 16 {
		return false
	}
	for _, r := range name[cut+1:] {
		if (r < '0' || r > '9') && (r < 'a' || r > 'f') {
			return false
		}
	}
	return true
}

// keyed names a per-directory state file under dir. The basename is for a human
// reading `ls`; the digest is what makes it unique, because two checkouts of one
// repository share a basename.
func keyed(dir, root string) string {
	sum := sha256.Sum256([]byte(root))
	digest := hex.EncodeToString(sum[:])[:16]
	return fmt.Sprintf("%s/%s-%s", dir, filepath.Base(root), digest)
}

// DeclaredWorkspace returns the workspace boundary the environment states, or ""
// when it states none, names something that is not a directory, or names a
// directory that does not contain dir.
//
// The variable is read instead of a session manager's state directory being
// recognised by path, so whatever put the caller in a workspace is what states
// where it ends. It answers only for a directory it contains, because an explicit
// path outside it is the caller meaning that path.
func DeclaredWorkspace(dir string) string {
	root := strings.TrimRight(strings.TrimSpace(os.Getenv("SYSINIT_WORKSPACE")), "/")
	if root == "" {
		return ""
	}
	if info, err := os.Stat(root); err != nil || !info.IsDir() {
		return ""
	}
	if dir == root || strings.HasPrefix(dir, root+"/") {
		return root
	}
	return ""
}

// Workspace resolves dir to the directory a state file should be keyed on: what
// the environment declares, else the git top level, else dir itself.
//
// The git step is what makes a subdirectory agree with its repository root, so a
// hook firing from `src/` and an editor opened at the top key the same file.
//
// It runs no `git status`, since a hook on the edit path should not pay for a
// working-tree scan it does not read.
func Workspace(dir string) string {
	if dir == "" {
		if here, err := os.Getwd(); err == nil {
			dir = here
		}
	}
	dir = strings.TrimRight(dir, "/")

	if declared := DeclaredWorkspace(dir); declared != "" {
		return declared
	}

	if root, err := RootAt(dir); err == nil {
		return root
	}
	return dir
}

// normalizeAbsolute resolves "." and ".." lexically, without touching the disk.
func normalizeAbsolute(path string) (string, error) {
	rest := strings.TrimPrefix(path, "/")
	result := ""
	for rest != "" {
		var segment string
		if i := strings.Index(rest, "/"); i < 0 {
			segment, rest = rest, ""
		} else {
			segment, rest = rest[:i], rest[i+1:]
		}
		switch segment {
		case "", ".":
		case "..":
			if result == "" {
				return "", ErrOutsideRoot
			}
			result = result[:strings.LastIndex(result, "/")]
		default:
			result += "/" + segment
		}
	}
	if result == "" {
		return "/", nil
	}
	return result, nil
}

// physicalWD returns the working directory with symlinks resolved.
func physicalWD() (string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(wd)
	if err != nil {
		return wd, nil
	}
	return resolved, nil
}

// RelativeToRoot returns path expressed relative to root, or ErrOutsideRoot.
func RelativeToRoot(root, path string) (string, error) {
	absolute := path
	if !strings.HasPrefix(path, "/") {
		base, err := physicalWD()
		if err != nil {
			return "", err
		}
		absolute = base + "/" + path
	}
	normalized, err := normalizeAbsolute(absolute)
	if err != nil {
		return "", err
	}
	if normalized == root {
		return "", ErrOutsideRoot
	}
	if !strings.HasPrefix(normalized, root+"/") {
		return "", ErrOutsideRoot
	}
	return strings.TrimPrefix(normalized, root+"/"), nil
}
