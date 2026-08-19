package web

import (
	"bytes"
	"embed"
	"encoding/json"
	"fmt"
	"text/template"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/detail"
	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/graph"
)

//go:embed assets/page.html.tmpl
var assets embed.FS

type page struct {
	GraphJSON   string
	DetailJSON  string
	DiagJSON    string
	SuggestJSON string
}

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
