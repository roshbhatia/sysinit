package repo

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/git"
	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/internal/workspace"
)

func RootAt(dir string) (string, error) { return git.Root(dir) }

func EditLogFile(root string) string {
	return keyed(paths.AgentEdits(), root) + ".jsonl"
}

func DeltaDir(root string) string {
	return keyed(paths.AgentEdits(), root) + ".delta"
}

func PromptFile(root string) string {
	return keyed(paths.AgentEdits(), root) + ".prompt"
}

func CleanEnv() []string { return git.CleanEnv() }

func GitEnv(gitDir, workTree string) []string { return git.ShadowEnv(gitDir, workTree) }

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

// pkgs/internal/workspace owns the boundary rule, because changes reads it too
// and two copies would drift.
func DeclaredWorkspace(dir string) string { return workspace.Declared(dir) }

func Workspace(dir string) string { return workspace.Root(dir) }
