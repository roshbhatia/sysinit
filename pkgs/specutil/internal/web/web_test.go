package web

import (
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/detail"
	"github.com/roshbhatia/specutil/internal/graph"
)

func TestRenderInlinesFeeds(t *testing.T) {
	g := &graph.Graph{
		Nodes: []graph.Node{{ID: "db", Label: "db"}, {ID: "api", Label: "api"}},
		Edges: []graph.Edge{{From: "db", To: "api"}},
	}
	d := &detail.Feed{Changes: []detail.Change{
		{Name: "db", Lifecycle: "active", Done: 1, Total: 2},
		{Name: "api", Lifecycle: "proposed", Done: 0, Total: 3},
	}}
	out, err := Render(g, d, nil, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	html := string(out)

	// Both feeds are inlined as JS literals; no data file is ever fetched.
	for _, want := range []string{
		"<!doctype html>",
		"const GRAPH =",
		"const DETAIL =",
		`"db"`,
		`"api"`,
	} {
		if !strings.Contains(html, want) {
			t.Errorf("rendered page missing %q", want)
		}
	}

	// The presentation layer loads from a pinned CDN — the page must reference it,
	// not inline a vendored bundle. (Pinning/SRI/onerror is asserted in the guard.)
	if !strings.Contains(html, "cdn.jsdelivr.net") {
		t.Error("page should reference the pinned CDN for its presentation layer")
	}
}

func TestRenderNilArgs(t *testing.T) {
	if _, err := Render(nil, nil, nil, nil); err != nil {
		t.Fatalf("Render(nil, nil, nil, nil) should not error: %v", err)
	}
}

func TestRenderInlinesDiagnostics(t *testing.T) {
	// Manifest diagnostics must reach the page as an inlined literal so the
	// health banner can surface a broken manifest instead of discarding it.
	g := &graph.Graph{Nodes: []graph.Node{{ID: "a"}, {ID: "b"}}}
	diags := []graph.Diagnostic{{Kind: "cycle", Msg: "dependency cycle: a -> b -> a"}}
	out, err := Render(g, &detail.Feed{}, diags, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	for _, want := range []string{"const DIAG =", `"cycle"`, "dependency cycle"} {
		if !strings.Contains(string(out), want) {
			t.Errorf("rendered page missing diagnostic %q", want)
		}
	}
}

func TestRenderUsesLightOnlyTheme(t *testing.T) {
	out, err := Render(nil, nil, nil, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	html := string(out)
	for _, bad := range []string{"specutil-theme", "data-theme", "prefers-color-scheme", "Toggle color theme"} {
		if strings.Contains(html, bad) {
			t.Fatalf("light-only page should not contain theme switch machinery %q", bad)
		}
	}
}

func TestRenderSuggestedEdgeSnippetMatchesManifest(t *testing.T) {
	out, err := Render(nil, nil, nil, []graph.Candidate{{From: "db", To: "api", Capability: "auth"}})
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	html := string(out)
	if !strings.Contains(html, "depends_on") {
		t.Fatalf("suggested-edge snippet should use the manifest depends_on shape:\n%s", html)
	}
	if strings.Contains(html, `"- from: "`) {
		t.Fatalf("suggested-edge snippet should not advertise the unsupported from/to list shape")
	}
}

func TestRenderEscapesScriptBreakout(t *testing.T) {
	// A label that tries to close the script block must be escaped so it can't
	// break out of the inlined <script> data island. json.Marshal escapes < > &.
	g := &graph.Graph{Nodes: []graph.Node{{ID: "x", Label: "</script><b>"}}}
	d := &detail.Feed{Changes: []detail.Change{{Name: "</script><b>", Lifecycle: "proposed"}}}
	out, err := Render(g, d, nil, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	if strings.Contains(string(out), "</script><b>") {
		t.Error("script-breakout label was not escaped in the data island")
	}
}

func TestRenderInlinesExternalRefs(t *testing.T) {
	// detail.Item.ExternalRefs must reach the page as part of the inlined detail
	// JSON so the template can render "ENG-123" chips next to task keys.
	d := &detail.Feed{Changes: []detail.Change{
		{Name: "db", Lifecycle: "active", Phases: []detail.Phase{
			{Number: "1", Name: "Setup", Items: []detail.Item{
				{Text: "init", Key: "0a", ExternalRefs: []detail.ExternalRef{
					{Target: "linear", ExternalID: "ENG-42"},
				}},
			}},
		}},
	}}
	out, err := Render(nil, d, nil, nil)
	if err != nil {
		t.Fatalf("Render: %v", err)
	}
	for _, want := range []string{"ENG-42", "externalRefs", "linear"} {
		if !strings.Contains(string(out), want) {
			t.Errorf("rendered page missing external ref %q", want)
		}
	}
}
