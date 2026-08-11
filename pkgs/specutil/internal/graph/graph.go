// Package graph builds the cross-change dependency DAG from the repo-level
// specutil.yaml manifest and the loaded changes, and projects it to the
// renderer-independent json feed plus mermaid and dot. Everything here is pure
// and deterministic: identical inputs yield byte-identical output.
package graph

import (
	"fmt"
	"sort"

	"github.com/roshbhatia/specutil/internal/ir"
)

// Node is one change in the dependency DAG.
type Node struct {
	ID    string `json:"id"`
	Label string `json:"label"`
}

// Edge is a directed dependency edge: From is the prerequisite, To the
// dependent (i.e. To depends on From). It doubles as the manifest's `edges:`
// entry shape, hence the yaml tags.
type Edge struct {
	From string `json:"from" yaml:"from"`
	To   string `json:"to"   yaml:"to"`
}

// Graph is the canonical, sorted dependency DAG and the feed for visualizers.
type Graph struct {
	Nodes []Node `json:"nodes"`
	Edges []Edge `json:"edges"`
}

// Diagnostic reports a manifest problem (dangling reference, cycle) without
// aborting graph construction — the caller decides how loudly to surface it.
type Diagnostic struct {
	Kind string `json:"kind"` // "dangling" | "cycle"
	Msg  string `json:"msg"`
}

// Build assembles the DAG from the known changes and the manifest. It returns
// the graph plus diagnostics for dangling references and dependency cycles.
// Dangling edges are dropped from the graph but reported; cycles are reported
// but their edges are retained so the projection still reflects the manifest.
func Build(changes []*ir.Change, m *Manifest) (*Graph, []Diagnostic) {
	known := make(map[string]bool, len(changes))
	for _, c := range changes {
		known[c.Name] = true
	}

	var diags []Diagnostic
	nodes := make([]Node, 0, len(changes))
	for _, c := range changes {
		nodes = append(nodes, Node{ID: c.Name, Label: c.Name})
	}
	sort.Slice(nodes, func(i, j int) bool { return nodes[i].ID < nodes[j].ID })

	edges := make([]Edge, 0)
	seen := make(map[string]bool)
	for _, e := range m.edges() {
		if !known[e.From] {
			diags = append(diags, Diagnostic{
				Kind: "dangling",
				Msg:  fmt.Sprintf("dependency edge %s -> %s references unknown change %q", e.From, e.To, e.From),
			})
			continue
		}
		if !known[e.To] {
			diags = append(diags, Diagnostic{
				Kind: "dangling",
				Msg:  fmt.Sprintf("dependency edge %s -> %s references unknown change %q", e.From, e.To, e.To),
			})
			continue
		}
		key := e.From + "\x00" + e.To
		if seen[key] {
			continue
		}
		seen[key] = true
		edges = append(edges, e)
	}
	sort.Slice(edges, func(i, j int) bool {
		if edges[i].From != edges[j].From {
			return edges[i].From < edges[j].From
		}
		return edges[i].To < edges[j].To
	})

	g := &Graph{Nodes: nodes, Edges: edges}
	for _, cyc := range g.cycles() {
		diags = append(diags, Diagnostic{
			Kind: "cycle",
			Msg:  fmt.Sprintf("dependency cycle: %s", joinCycle(cyc)),
		})
	}
	return g, diags
}

// cycles returns each detected cycle as an ordered list of node IDs. It walks
// the graph with a deterministic DFS so the reported cycles are stable.
func (g *Graph) cycles() [][]string {
	adj := make(map[string][]string)
	for _, e := range g.Edges {
		adj[e.From] = append(adj[e.From], e.To)
	}

	const (
		white = 0 // unvisited
		gray  = 1 // on the current stack
		black = 2 // fully explored
	)
	color := make(map[string]int)
	var stack []string
	var found [][]string

	var visit func(n string)
	visit = func(n string) {
		color[n] = gray
		stack = append(stack, n)
		for _, to := range adj[n] {
			switch color[to] {
			case white:
				visit(to)
			case gray:
				// Back-edge: extract the cycle from the stack.
				for i := len(stack) - 1; i >= 0; i-- {
					if stack[i] == to {
						cyc := append([]string(nil), stack[i:]...)
						found = append(found, cyc)
						break
					}
				}
			}
		}
		stack = stack[:len(stack)-1]
		color[n] = black
	}

	for _, node := range g.Nodes {
		if color[node.ID] == white {
			visit(node.ID)
		}
	}
	return found
}

func joinCycle(cyc []string) string {
	out := ""
	for i, n := range cyc {
		if i > 0 {
			out += " -> "
		}
		out += n
	}
	if len(cyc) > 0 {
		out += " -> " + cyc[0]
	}
	return out
}
