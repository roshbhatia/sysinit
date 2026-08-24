package source

import (
	"context"
	"encoding/json"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/internal/diffview"
)

// calldiff prints one tree per entrypoint, already rendered as a plus and
// minus ASCII diff. The tree is the only place the per call site locations
// appear, so the edges are read back off it rather than out of a field.
type callTrees struct {
	Trees []struct {
		Entry string `json:"entry"`
		ASCII string `json:"ascii"`
	} `json:"trees"`
}

// A located call line ends in path:line or path:line-line. The leading marker
// says which side of the diff the call sits on, and an unmarked line is a call
// the edit left alone.
var callSite = regexp.MustCompile(`([^\s]+):(\d+)(?:-\d+)?\s*$`)

// Calls returns the call sites the change added or removed, keyed on the path
// calldiff reported. calldiff walks the whole graph, so it is the slowest
// layer by far and the only one worth a deadline of its own; on timeout the
// symbol rows simply carry churn without call counts.
func Calls(root, from, to string, paths []string, timeout time.Duration) map[string][]diffview.Edge {
	out := map[string][]diffview.Edge{}
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()

	args := []string{"diff"}
	if from != "" {
		args = append(args, from)
	}
	if to != "" {
		args = append(args, to)
	}
	args = append(args, "--locs", "--format", "json")
	if len(paths) > 0 {
		args = append(args, paths...)
	}
	cmd := exec.CommandContext(ctx, "calldiff", args...)
	cmd.Dir = root
	blob, err := cmd.Output()
	if err != nil {
		return out
	}
	trees := callTrees{}
	if json.Unmarshal(blob, &trees) != nil {
		return out
	}
	seen := map[string]map[diffview.Edge]bool{}
	for _, t := range trees.Trees {
		for _, ln := range strings.Split(t.ASCII, "\n") {
			marker, rest, ok := marked(ln)
			if !ok {
				continue
			}
			m := callSite.FindStringSubmatch(rest)
			if m == nil {
				continue
			}
			no, err := strconv.Atoi(m[2])
			if err != nil {
				continue
			}
			path, edge := m[1], diffview.Edge{Line: no, Added: marker == '+'}
			if seen[path] == nil {
				seen[path] = map[diffview.Edge]bool{}
			}
			// One call site reached from two entrypoints appears in two trees,
			// and counted twice it would double the call tally on its symbol.
			if seen[path][edge] {
				continue
			}
			seen[path][edge] = true
			out[path] = append(out[path], edge)
		}
	}
	return out
}

// The marker sits in the first column, ahead of the tree rail. A space there
// means the line is carried, which is every line the change did not touch.
func marked(ln string) (byte, string, bool) {
	if ln == "" {
		return 0, "", false
	}
	if ln[0] != '+' && ln[0] != '-' {
		return 0, "", false
	}
	return ln[0], ln[1:], true
}
