package source

import (
	"os"
	"path/filepath"

	"github.com/roshbhatia/sysinit/pkgs/internal/git"
)

// Tree returns a directory holding the "after" side of the comparison, and the
// paths that exist in it. The outline layer joins on new file line numbers, so
// reading the working tree while comparing two older trees would attribute a
// hunk to whichever symbol happens to live at that line today.
//
// The working tree is its own answer, so the common case copies nothing. Any
// other side is checked out into a temporary mirror, which keeps each path's
// extension and so keeps ast-grep's language detection.
func (s Spec) Tree(paths []string) (dir string, kept []string, done func()) {
	if !s.Staged && s.To == "" {
		for _, p := range paths {
			if _, err := os.Stat(filepath.Join(s.Dir, p)); err == nil {
				kept = append(kept, p)
			}
		}
		return s.Dir, kept, func() {}
	}

	tmp, err := os.MkdirTemp("", "changes-tree-")
	if err != nil {
		return s.Dir, nil, func() {}
	}
	done = func() { _ = os.RemoveAll(tmp) }
	for _, p := range paths {
		// A deleted path has no after side, and git show fails on it. That is
		// the signal to leave it out rather than an error to report.
		blob, err := git.Output(s.Dir, "show", s.rev()+":"+p)
		if err != nil {
			continue
		}
		at := filepath.Join(tmp, p)
		if os.MkdirAll(filepath.Dir(at), 0o755) != nil {
			continue
		}
		if os.WriteFile(at, []byte(blob), 0o644) != nil {
			continue
		}
		kept = append(kept, p)
	}
	return tmp, kept, done
}

// An empty rev is the index, which git spells as a bare colon.
func (s Spec) rev() string {
	if s.To != "" {
		return s.To
	}
	return ""
}
