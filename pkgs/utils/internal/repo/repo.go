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
