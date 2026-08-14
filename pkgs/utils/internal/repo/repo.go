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

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/paths"
)

var ErrOutsideRoot = errors.New("path is not inside the repository")

func Root() (string, error) {
	return RootAt("")
}

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

func NoteFile(root string) string {
	return noteBase(root) + ".json"
}

func ExportFile(root string) string {
	return noteBase(root) + ".hunk.json"
}

func noteBase(root string) string {
	return keyed(paths.AgentDiffNotes(), root)
}

func EditLogFile(root string) string {
	return keyed(paths.AgentEdits(), root) + ".jsonl"
}

func WorkerDir(root string) string {
	return keyed(paths.AgentWorker(), root)
}

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

func keyed(dir, root string) string {
	sum := sha256.Sum256([]byte(root))
	digest := hex.EncodeToString(sum[:])[:16]
	return fmt.Sprintf("%s/%s-%s", dir, filepath.Base(root), digest)
}

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
