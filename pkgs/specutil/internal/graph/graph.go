package graph

import (
	"fmt"
	"sort"

	"github.com/roshbhatia/specutil/internal/ir"
)

type Node struct {
	ID    string `json:"id"`
	Label string `json:"label"`
}

type Edge struct {
	From string `json:"from" yaml:"from"`
	To   string `json:"to"   yaml:"to"`
}

type Graph struct {
	Nodes []Node `json:"nodes"`
	Edges []Edge `json:"edges"`
}

type Diagnostic struct {
	Kind string `json:"kind"`
	Msg  string `json:"msg"`
}

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

func (g *Graph) cycles() [][]string {
	adj := make(map[string][]string)
	for _, e := range g.Edges {
		adj[e.From] = append(adj[e.From], e.To)
	}

	const (
		white = 0
		gray  = 1
		black = 2
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
