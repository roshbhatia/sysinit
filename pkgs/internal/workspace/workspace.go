// Package workspace resolves the boundary a tool works inside, and finds the
// git repositories under it. The boundary is declared rather than guessed:
// $SYSINIT_WORKSPACE when the directory sits inside it, then the git top level,
// then the directory itself. Every tool that spans repositories reads it from
// here, so a seshy session means the same thing to all of them.
package workspace

import (
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/git"
)

// A session holds its repositories a level or two down, and a deeper walk
// costs a full tree scan to find nothing.
const ScanDepth = 5

// Declared returns $SYSINIT_WORKSPACE only when dir sits inside it. A stale
// variable from another session would otherwise retarget the whole scan.
func Declared(dir string) string {
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

// Root resolves the boundary for dir.
func Root(dir string) string {
	if dir == "" {
		if here, err := os.Getwd(); err == nil {
			dir = here
		}
	}
	dir = strings.TrimRight(dir, "/")

	if declared := Declared(dir); declared != "" {
		return declared
	}
	if root, err := git.Root(dir); err == nil {
		return root
	}
	return dir
}

// Roots lists every git repository at or under the boundary for dir. The walk
// keeps descending past one it found, so a nested repository is reported too,
// and a caller that must not double count has to exclude the nesting itself.
func Roots(dir string) ([]string, error) {
	root := Root(dir)
	base := strings.Count(filepath.Clean(root), string(os.PathSeparator))

	var found []string
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, err error) error {
		if err != nil {
			if entry != nil && entry.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if !entry.IsDir() {
			return nil
		}
		if entry.Name() == ".git" {
			return filepath.SkipDir
		}
		if _, statErr := os.Lstat(filepath.Join(path, ".git")); statErr == nil {
			found = append(found, path)
		}
		if strings.Count(filepath.Clean(path), string(os.PathSeparator))-base >= ScanDepth {
			return filepath.SkipDir
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	sort.Strings(found)
	return found, nil
}
