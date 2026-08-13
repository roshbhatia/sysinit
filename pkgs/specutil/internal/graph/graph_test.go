package graph

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func changes(names ...string) []*ir.Change {
	out := make([]*ir.Change, len(names))
	for i, n := range names {
		out[i] = &ir.Change{Name: n}
	}
	return out
}

func TestManifestEdgeBuildsDAG(t *testing.T) {
	// B depends on A => edge A -> B.
	m := &Manifest{Changes: map[string]ManifestEntry{"B": {DependsOn: []string{"A"}}}}
	g, diags := Build(changes("A", "B"), m)
	if len(diags) != 0 {
		t.Fatalf("unexpected diagnostics: %v", diags)
	}
	if len(g.Edges) != 1 || g.Edges[0] != (Edge{From: "A", To: "B"}) {
		t.Fatalf("expected single edge A->B, got %v", g.Edges)
	}
}

func TestManifestEdgesListBuildsDAG(t *testing.T) {
	// The explicit `edges:` spelling must produce the same DAG as depends_on.
	m := &Manifest{Edges: []Edge{{From: "A", To: "B"}}}
	g, diags := Build(changes("A", "B"), m)
	if len(diags) != 0 {
		t.Fatalf("unexpected diagnostics: %v", diags)
	}
	if len(g.Edges) != 1 || g.Edges[0] != (Edge{From: "A", To: "B"}) {
		t.Fatalf("expected single edge A->B, got %v", g.Edges)
	}
}

func TestManifestSpellingsDeduplicate(t *testing.T) {
	// The same edge declared both ways must appear once.
	m := &Manifest{
		Changes: map[string]ManifestEntry{"B": {DependsOn: []string{"A"}}},
		Edges:   []Edge{{From: "A", To: "B"}},
	}
	g, _ := Build(changes("A", "B"), m)
	if len(g.Edges) != 1 {
		t.Fatalf("expected the duplicate edge to collapse to one, got %v", g.Edges)
	}
}

func TestLoadManifestReadsEdgesList(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "openspec"), 0o755); err != nil {
		t.Fatal(err)
	}
	src := "edges:\n  - from: A\n    to: B\n"
	if err := os.WriteFile(filepath.Join(dir, ManifestFile), []byte(src), 0o644); err != nil {
		t.Fatal(err)
	}
	m, err := LoadManifest(dir)
	if err != nil {
		t.Fatalf("LoadManifest: %v", err)
	}
	if len(m.Edges) != 1 || m.Edges[0] != (Edge{From: "A", To: "B"}) {
		t.Fatalf("expected the edges list to parse, got %v", m.Edges)
	}
}

func TestDanglingReferenceReported(t *testing.T) {
	m := &Manifest{Changes: map[string]ManifestEntry{"B": {DependsOn: []string{"ghost"}}}}
	g, diags := Build(changes("B"), m)
	if len(g.Edges) != 0 {
		t.Errorf("dangling edge should be dropped, got %v", g.Edges)
	}
	if len(diags) != 1 || diags[0].Kind != "dangling" {
		t.Fatalf("expected one dangling diagnostic, got %v", diags)
	}
	if !strings.Contains(diags[0].Msg, "ghost") {
		t.Errorf("diagnostic should name the missing change: %q", diags[0].Msg)
	}
}

func TestCycleDetected(t *testing.T) {
	m := &Manifest{Changes: map[string]ManifestEntry{
		"A": {DependsOn: []string{"B"}},
		"B": {DependsOn: []string{"A"}},
	}}
	_, diags := Build(changes("A", "B"), m)
	var cyc *Diagnostic
	for i := range diags {
		if diags[i].Kind == "cycle" {
			cyc = &diags[i]
		}
	}
	if cyc == nil {
		t.Fatalf("expected a cycle diagnostic, got %v", diags)
	}
	if !strings.Contains(cyc.Msg, "A") || !strings.Contains(cyc.Msg, "B") {
		t.Errorf("cycle diagnostic should name involved changes: %q", cyc.Msg)
	}
}

func TestJSONStable(t *testing.T) {
	m := &Manifest{Changes: map[string]ManifestEntry{"B": {DependsOn: []string{"A"}}}}
	g, _ := Build(changes("B", "A"), m)
	a, err := g.Project("json")
	if err != nil {
		t.Fatal(err)
	}
	b, err := g.Project("json")
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(a, b) {
		t.Error("json projection is not byte-stable")
	}
	// Nodes must be sorted regardless of input order.
	if !strings.Contains(string(a), `"id": "A"`) || strings.Index(string(a), `"A"`) > strings.Index(string(a), `"B"`) {
		t.Errorf("nodes not sorted: %s", a)
	}
}

func TestJSONFeedStaysPureDependencyContract(t *testing.T) {
	// The graph feed must carry only the dependency DAG — nodes (id/label) and edges
	// (from/to) — and MUST NOT leak task-level detail.
	m := &Manifest{Changes: map[string]ManifestEntry{"B": {DependsOn: []string{"A"}}}}
	g, _ := Build(changes("B", "A"), m)
	out, err := g.Project("json")
	if err != nil {
		t.Fatal(err)
	}

	var parsed struct {
		Nodes []map[string]json.RawMessage `json:"nodes"`
		Edges []map[string]json.RawMessage `json:"edges"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		t.Fatalf("graph json did not parse: %v\n%s", err, out)
	}
	for _, n := range parsed.Nodes {
		for k := range n {
			if k != "id" && k != "label" {
				t.Errorf("node carries unexpected key %q — graph feed must stay workstream-level", k)
			}
		}
	}
	for _, e := range parsed.Edges {
		for k := range e {
			if k != "from" && k != "to" {
				t.Errorf("edge carries unexpected key %q — graph feed must stay workstream-level", k)
			}
		}
	}
}

func TestMermaidAndDot(t *testing.T) {
	m := &Manifest{Changes: map[string]ManifestEntry{"add-auth": {DependsOn: []string{"add-db"}}}}
	g, _ := Build(changes("add-auth", "add-db"), m)

	mer, err := g.Project("mermaid")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(string(mer), "graph TD") {
		t.Errorf("mermaid should start with graph TD: %q", mer)
	}
	// Hyphenated change names must be sanitized into valid Mermaid IDs.
	if !strings.Contains(string(mer), "add_db --> add_auth") {
		t.Errorf("mermaid missing sanitized edge: %q", mer)
	}

	dot, err := g.Project("dot")
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(dot), "digraph specutil") || !strings.Contains(string(dot), `"add-db" -> "add-auth"`) {
		t.Errorf("unexpected dot output: %q", dot)
	}
}

func TestUnknownFormatRejected(t *testing.T) {
	g, _ := Build(changes("A"), &Manifest{})
	_, err := g.Project("bogus")
	if err == nil || !strings.Contains(err.Error(), "bogus") {
		t.Fatalf("expected error naming bogus format, got %v", err)
	}
}

func TestLoadManifestAbsentIsEmpty(t *testing.T) {
	m, err := LoadManifest(t.TempDir())
	if err != nil {
		t.Fatalf("absent manifest should not error: %v", err)
	}
	if len(m.Changes) != 0 {
		t.Errorf("expected empty manifest, got %v", m.Changes)
	}
}

func TestLoadManifestParses(t *testing.T) {
	dir := t.TempDir()
	if err := os.MkdirAll(filepath.Join(dir, "openspec"), 0o755); err != nil {
		t.Fatal(err)
	}
	content := "changes:\n  add-auth:\n    depends_on:\n      - add-db\n"
	if err := os.WriteFile(filepath.Join(dir, ManifestFile), []byte(content), 0o644); err != nil {
		t.Fatal(err)
	}
	m, err := LoadManifest(dir)
	if err != nil {
		t.Fatal(err)
	}
	if got := m.Changes["add-auth"].DependsOn; len(got) != 1 || got[0] != "add-db" {
		t.Errorf("manifest not parsed: %+v", m.Changes)
	}
}

func TestSuggestSharedCapability(t *testing.T) {
	producer := &ir.Change{Name: "add-db", Proposal: &ir.Proposal{
		Capabilities: ir.Capabilities{New: []ir.Capability{{Name: "storage"}}},
	}}
	consumer := &ir.Change{Name: "add-auth", Proposal: &ir.Proposal{
		Capabilities: ir.Capabilities{Modified: []ir.Capability{{Name: "storage"}}},
	}}
	cands := Suggest([]*ir.Change{consumer, producer})
	if len(cands) != 1 {
		t.Fatalf("expected one candidate, got %v", cands)
	}
	if cands[0] != (Candidate{From: "add-db", To: "add-auth", Capability: "storage"}) {
		t.Errorf("unexpected candidate: %+v", cands[0])
	}
}

func TestBuildSuggestPrompt(t *testing.T) {
	changes := []*ir.Change{
		{Name: "add-db", Proposal: &ir.Proposal{
			Why:         "need persistence",
			WhatChanges: "adds postgres",
			Capabilities: ir.Capabilities{
				New:      []ir.Capability{{Name: "storage"}},
				Modified: []ir.Capability{{Name: "config"}},
			},
		}},
		{Name: "no-proposal"},
	}
	prompt := buildSuggestPrompt(changes)
	for _, want := range []string{
		"add-db", "need persistence", "adds postgres",
		"Adds capability: storage", "Modifies capability: config",
		"no-proposal",
	} {
		if !strings.Contains(prompt, want) {
			t.Errorf("prompt missing %q", want)
		}
	}
}

func TestParseHarnessOutput(t *testing.T) {
	known := map[string]bool{"add-db": true, "add-auth": true}

	cases := []struct {
		name    string
		raw     []byte
		wantN   int
		wantErr bool
	}{
		{
			name:  "valid suggestions",
			raw:   []byte(`{"suggestions":[{"from":"add-db","to":"add-auth","reason":"auth uses storage"}]}`),
			wantN: 1,
		},
		{
			name:  "empty suggestions",
			raw:   []byte(`{"suggestions":[]}`),
			wantN: 0,
		},
		{
			name:  "strips markdown fences",
			raw:   []byte("```json\n{\"suggestions\":[{\"from\":\"add-db\",\"to\":\"add-auth\",\"reason\":\"r\"}]}\n```"),
			wantN: 1,
		},
		{
			name:  "unknown change names dropped",
			raw:   []byte(`{"suggestions":[{"from":"ghost","to":"add-auth","reason":"?"}]}`),
			wantN: 0,
		},
		{
			name:  "self-edges dropped",
			raw:   []byte(`{"suggestions":[{"from":"add-db","to":"add-db","reason":"self"}]}`),
			wantN: 0,
		},
		{
			name:    "invalid json",
			raw:     []byte(`not json`),
			wantErr: true,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := parseHarnessOutput(tc.raw, known)
			if (err != nil) != tc.wantErr {
				t.Fatalf("err = %v, wantErr = %v", err, tc.wantErr)
			}
			if !tc.wantErr && len(got) != tc.wantN {
				t.Errorf("got %d candidates, want %d: %+v", len(got), tc.wantN, got)
			}
		})
	}
}

func TestHarnessSuggestRejectsEmptyName(t *testing.T) {
	_, err := HarnessSuggest(nil, "")
	if err == nil {
		t.Fatal("expected error for empty harness name")
	}
}
