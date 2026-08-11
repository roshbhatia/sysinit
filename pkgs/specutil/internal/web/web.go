// Package web renders the cross-change dependency graph and per-workstream
// detail into a single static HTML file. The data feeds are baked in as JSON
// literals; the graph itself is rendered client-side by Cytoscape.js. The
// binary performs zero network I/O — only the rendered page loads CDN assets.
package web

import (
	"bytes"
	"embed"
	"encoding/json"
	"fmt"
	"text/template"

	"github.com/roshbhatia/specutil/internal/detail"
	"github.com/roshbhatia/specutil/internal/graph"
)

//go:embed assets/page.html.tmpl
var assets embed.FS

// page is the inlined data the template needs. text/template performs no
// contextual escaping, so these are emitted verbatim — safe because
// json.Marshal already escapes <, >, & in the data literals.
type page struct {
	GraphJSON   string // the graph.json feed, embedded as a JS literal
	DetailJSON  string // the detail.json feed, embedded as a JS literal
	DiagJSON    string // manifest diagnostics, embedded as a JS literal (may be [])
	SuggestJSON string // graph --suggest candidates, embedded as a JS literal (may be [])
}

// Render returns a self-contained HTML document visualizing g, drilling into the
// detail feed d for per-workstream ticket content. Both feeds use the same
// renderer-independent schemas as graph.json / detail.json, so the data contract
// is shared with every other consumer. diags surfaces manifest problems (cycles,
// dangling references) in a health banner so a broken manifest is visible rather
// than discarded. candidates are the auto-inferred suggest edges shown in the UI
// so users don't have to run graph --suggest manually. d may be nil; diags and
// candidates may be empty.
func Render(g *graph.Graph, d *detail.Feed, diags []graph.Diagnostic, candidates []graph.Candidate) ([]byte, error) {
	if g == nil {
		g = &graph.Graph{Nodes: []graph.Node{}, Edges: []graph.Edge{}}
	}
	if d == nil {
		d = &detail.Feed{Changes: []detail.Change{}}
	}
	if diags == nil {
		diags = []graph.Diagnostic{}
	}
	if candidates == nil {
		candidates = []graph.Candidate{}
	}
	// json.Marshal escapes <, >, & by default, so the literals are safe to inline
	// inside a <script> block without breaking out of it.
	graphData, err := json.Marshal(g)
	if err != nil {
		return nil, fmt.Errorf("encoding graph: %w", err)
	}
	detailData, err := json.Marshal(d)
	if err != nil {
		return nil, fmt.Errorf("encoding detail: %w", err)
	}
	diagData, err := json.Marshal(diags)
	if err != nil {
		return nil, fmt.Errorf("encoding diagnostics: %w", err)
	}
	suggestData, err := json.Marshal(candidates)
	if err != nil {
		return nil, fmt.Errorf("encoding suggestions: %w", err)
	}

	tmplSrc, err := assets.ReadFile("assets/page.html.tmpl")
	if err != nil {
		return nil, fmt.Errorf("reading embedded template: %w", err)
	}
	tmpl, err := template.New("page").Parse(string(tmplSrc))
	if err != nil {
		return nil, fmt.Errorf("parsing template: %w", err)
	}

	var buf bytes.Buffer
	err = tmpl.Execute(&buf, page{
		GraphJSON:   string(graphData),
		DetailJSON:  string(detailData),
		DiagJSON:    string(diagData),
		SuggestJSON: string(suggestData),
	})
	if err != nil {
		return nil, fmt.Errorf("executing template: %w", err)
	}
	return buf.Bytes(), nil
}
