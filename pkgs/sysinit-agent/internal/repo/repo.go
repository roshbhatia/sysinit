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
	sum := sha256.Sum256([]byte(root))
	digest := hex.EncodeToString(sum[:])[:16]
	return fmt.Sprintf("%s/%s-%s", paths.AgentDiffNotes(), filepath.Base(root), digest)
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
