// Package source turns the three tools that describe a change into the layers
// diffview renders: git for the lines, ast-grep for the symbols, calldiff for
// the call edges. Each layer degrades on its own, so a language ast-grep cannot
// parse still prints its hunks.
package source

import (
	"fmt"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/git"
)

// Spec names one comparison, in git's own terms: no refs is HEAD against the
// working tree, one ref is that ref against the working tree, two refs compare
// the trees. Staged swaps the working tree for the index.
type Spec struct {
	Dir    string
	From   string
	To     string
	Staged bool
	Paths  []string
}

// Diff returns the unified patch. Zero context would drop the side by side
// view's carried lines, and git's default of three is what the renderer was
// tuned against.
func (s Spec) Diff() (string, error) {
	args := []string{"diff", "--no-color", "--no-ext-diff", "--find-renames"}
	if s.Staged {
		args = append(args, "--cached")
	}
	if s.From != "" {
		args = append(args, s.From)
	}
	if s.To != "" {
		args = append(args, s.To)
	}
	if len(s.Paths) > 0 {
		args = append(args, "--")
		args = append(args, s.Paths...)
	}
	out, err := git.Output(s.Dir, args...)
	if err != nil {
		return "", fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return out, nil
}

// Root resolves the repository the paths are relative to. Every layer keys on
// a repo relative path, so the three tools have to agree on one root.
func Root(dir string) (string, error) {
	if !git.IsRepo(dir) {
		return "", fmt.Errorf("%s is not a git repository", dir)
	}
	return git.Root(dir)
}

// IsRev asks git whether a positional argument names a tree. flag.Parse eats
// the -- separator, so a bare path would otherwise reach git as a revision and
// fail as an unknown one. git disambiguates the same way.
func IsRev(dir, s string) bool {
	if s == "" {
		return false
	}
	return git.Succeeds(dir, "rev-parse", "--verify", "--quiet", s+"^{object}")
}
