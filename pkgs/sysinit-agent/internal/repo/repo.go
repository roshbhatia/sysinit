// Package repo derives the repository root and the note paths under it.
//
// The derivation lives here alone. It used to be duplicated in a second
// language, where a drift was silent, and both addresses now come from one
// function so there is nothing left to keep in step by hand.
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

// StateHome is the root the note record and its export sit under.
//
// It delegates rather than deriving. The layout has one owner, the paths
// manifest, and internal/paths is this module's only reader of it.
func StateHome() string {
	return paths.StateHome()
}

// NoteFile returns the note-record path for root.
func NoteFile(root string) string {
	return noteBase(root) + ".json"
}

// ExportFile returns the path of the viewer-shaped export derived from the
// record for root.
//
// Same base as NoteFile, so the two cannot drift and both ends compute one
// address from the root alone. Two viewers in two panes therefore read one file
// rather than each deriving its own.
func ExportFile(root string) string {
	return noteBase(root) + ".hunk.json"
}

func noteBase(root string) string {
	sum := sha256.Sum256([]byte(root))
	digest := hex.EncodeToString(sum[:])[:16]
	return fmt.Sprintf("%s/agents/diff-notes/%s-%s", StateHome(), filepath.Base(root), digest)
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
// The root itself is refused: a note anchors on a file, and every reader keys
// on a repo-relative file path that would be empty here.
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
