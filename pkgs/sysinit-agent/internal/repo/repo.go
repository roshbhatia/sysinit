// Package repo derives the repository root and the note-store path from it.
//
// The derivation is duplicated in lua/harness/diffnote.lua, which reads the
// store the CLI writes. A drift between the two is silent: the CLI reports
// success and the editor renders nothing. checks/diffnote-roundtrip.nix drives
// both halves for that reason.
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
)

// ErrOutsideRoot is returned for a path that does not name a file inside the
// repository, the repository root itself included.
var ErrOutsideRoot = errors.New("path is not inside the repository")

// Root returns the working tree's top level.
//
// GIT_DIR and friends are dropped: an agent invoked from a hook inherits them
// pointing at whatever repository triggered the hook, so the store would be
// keyed on a repository the caller is not in.
func Root() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
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

// StateHome returns XDG_STATE_HOME with any trailing slash removed, falling
// back to $HOME/.local/state.
//
// The trailing slash matters: nvim launched from a mux server inherits no
// session variables, so the fallback branch is the one that runs in practice,
// and the two halves must agree on both branches.
func StateHome() string {
	home := strings.TrimRight(os.Getenv("XDG_STATE_HOME"), "/")
	if home != "" {
		return home
	}
	return filepath.Join(os.Getenv("HOME"), ".local", "state")
}

// NoteFile returns the diffnote store path for root.
func NoteFile(root string) string {
	sum := sha256.Sum256([]byte(root))
	digest := hex.EncodeToString(sum[:])[:16]
	return fmt.Sprintf("%s/agents/diff-notes/%s-%s.json", StateHome(), filepath.Base(root), digest)
}

// normalizeAbsolute resolves "." and ".." lexically, without touching the disk.
//
// Lexical on purpose: the caller names a path that may not exist yet, and a
// stat-based resolution would accept an escape through a symlink the check
// forbids. A ".." that would climb above the first segment is refused rather
// than clamped.
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
//
// os.Getwd alone can answer logically from $PWD. git rev-parse --show-toplevel
// answers physically, so a relative path reached through a symlinked route
// would be measured against a root it does not textually share. macOS /tmp is
// such a symlink, which makes this the ordinary case there, not an exotic one.
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
//
// The root itself is refused: a note anchors on a file, and the editor keys its
// extmarks on a repo-relative file path that would be empty here.
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
