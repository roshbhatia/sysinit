package source

import (
	"context"
	"encoding/json"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
)

// ast-grep prints one object per path, and every item carries the line range
// the symbol spans. Only the fields the join needs are decoded here.
type outlineFile struct {
	Path  string `json:"path"`
	Items []struct {
		SymbolType string `json:"symbolType"`
		Name       string `json:"name"`
		Signature  string `json:"signature"`
		IsImport   bool   `json:"isImport"`
		Range      struct {
			Start struct {
				Line int `json:"line"`
			} `json:"start"`
			End struct {
				Line int `json:"line"`
			} `json:"end"`
		} `json:"range"`
	} `json:"items"`
}

// Outline reads the symbols of every path in one ast-grep call. A path whose
// language has no bundled grammar is simply absent from the answer, and its
// file then renders as a flat list of hunks.
func Outline(root string, paths []string, timeout time.Duration) map[string][]diffview.Symbol {
	out := map[string][]diffview.Symbol{}
	if len(paths) == 0 {
		return out
	}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	args := append([]string{"outline", "--json=compact"}, paths...)
	cmd := exec.CommandContext(ctx, "ast-grep", args...)
	cmd.Dir = root
	blob, err := cmd.Output()
	if err != nil {
		return out
	}
	files := []outlineFile{}
	if json.Unmarshal(blob, &files) != nil {
		return out
	}
	for _, f := range files {
		key := f.Path
		if filepath.IsAbs(key) {
			if rel, err := filepath.Rel(root, key); err == nil {
				key = rel
			}
		}
		for _, it := range f.Items {
			// An import is a line, not a region, so it claims a hunk that
			// belongs to whatever declaration follows it.
			if it.IsImport {
				continue
			}
			name := signature(it.Signature)
			if name == "" {
				name = it.Name
			}
			// ast-grep counts lines from zero and git counts from one, so the
			// join key needs the shift or every hunk lands one symbol early.
			out[key] = append(out[key], diffview.Symbol{
				Kind: it.SymbolType,
				Name: name,
				From: it.Range.Start.Line + 1,
				To:   it.Range.End.Line + 1,
			})
		}
	}
	return out
}

// A signature carries the declaration's opening brace and, for a wrapped
// parameter list, its newlines. Neither says anything on a one line symbol row.
func signature(sig string) string {
	sig = strings.Join(strings.Fields(sig), " ")
	return strings.TrimSpace(strings.TrimSuffix(strings.TrimSpace(sig), "{"))
}
