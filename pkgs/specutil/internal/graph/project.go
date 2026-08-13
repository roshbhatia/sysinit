package graph

import (
	"bytes"
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

// SupportedFormats lists the graph projection formats, sorted.
func SupportedFormats() []string {
	return []string{"dot", "json", "mermaid"}
}

// Project renders the graph in the named format. The json projection is the
// canonical, byte-stable feed; an unknown format is an error naming the
// supported set.
func (g *Graph) Project(format string) ([]byte, error) {
	switch format {
	case "json":
		return g.json()
	case "mermaid":
		return g.mermaid(), nil
	case "dot":
		return g.dot(), nil
	default:
		return nil, fmt.Errorf("unknown graph format %q; supported formats: %s",
			format, strings.Join(SupportedFormats(), ", "))
	}
}

// json emits the canonical feed: indented, trailing newline, fields in struct
// order, nodes/edges already sorted by Build. Byte-identical across runs.
func (g *Graph) json() ([]byte, error) {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetIndent("", "  ")
	enc.SetEscapeHTML(false)
	if err := enc.Encode(g); err != nil {
		return nil, fmt.Errorf("encoding graph json: %w", err)
	}
	return buf.Bytes(), nil
}

func (g *Graph) mermaid() []byte {
	var b strings.Builder
	b.WriteString("graph TD\n")
	for _, n := range g.Nodes {
		fmt.Fprintf(&b, "  %s[%q]\n", mermaidID(n.ID), n.Label)
	}
	for _, e := range g.Edges {
		fmt.Fprintf(&b, "  %s --> %s\n", mermaidID(e.From), mermaidID(e.To))
	}
	return []byte(b.String())
}

func (g *Graph) dot() []byte {
	var b strings.Builder
	b.WriteString("digraph specutil {\n")
	b.WriteString("  rankdir=LR;\n")
	for _, n := range g.Nodes {
		fmt.Fprintf(&b, "  %q [label=%q];\n", n.ID, n.Label)
	}
	for _, e := range g.Edges {
		fmt.Fprintf(&b, "  %q -> %q;\n", e.From, e.To)
	}
	b.WriteString("}\n")
	return []byte(b.String())
}

// mermaidID makes a change name safe as a Mermaid node identifier by replacing
// any character outside [A-Za-z0-9_] with an underscore.
func mermaidID(s string) string {
	var b strings.Builder
	for _, r := range s {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '_':
			b.WriteRune(r)
		default:
			b.WriteByte('_')
		}
	}
	return b.String()
}

// SuggestReport is the JSON envelope for `graph --suggest` output.
type SuggestReport struct {
	Candidates []Candidate `json:"candidates"`
}

// Candidate is a suggested dependency edge inferred from a shared capability,
// reported for review by `graph --suggest` and never written automatically.
type Candidate struct {
	From       string `json:"from"`
	To         string `json:"to"`
	Capability string `json:"capability"`
}

// Suggest infers candidate dependency edges from capabilities shared between changes.
func Suggest(changes []*ir.Change) []Candidate {
	type owner struct{ adds, mods []string }
	byCap := make(map[string]*owner)
	add := func(m map[string]*owner, capName, change string, isNew bool) {
		o := m[capName]
		if o == nil {
			o = &owner{}
			m[capName] = o
		}
		if isNew {
			o.adds = append(o.adds, change)
		} else {
			o.mods = append(o.mods, change)
		}
	}
	for _, c := range changes {
		if c.Proposal == nil {
			continue
		}
		for _, cap := range c.Proposal.Capabilities.New {
			add(byCap, cap.Name, c.Name, true)
		}
		for _, cap := range c.Proposal.Capabilities.Modified {
			add(byCap, cap.Name, c.Name, false)
		}
	}

	var out []Candidate
	caps := make([]string, 0, len(byCap))
	for name := range byCap {
		caps = append(caps, name)
	}
	sort.Strings(caps)
	for _, capName := range caps {
		o := byCap[capName]
		producers := append([]string(nil), o.adds...)
		sort.Strings(producers)
		consumers := append([]string(nil), o.mods...)
		sort.Strings(consumers)
		for _, p := range producers {
			for _, cons := range consumers {
				if p == cons {
					continue
				}
				out = append(out, Candidate{From: p, To: cons, Capability: capName})
			}
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].From != out[j].From {
			return out[i].From < out[j].From
		}
		if out[i].To != out[j].To {
			return out[i].To < out[j].To
		}
		return out[i].Capability < out[j].Capability
	})
	return out
}
