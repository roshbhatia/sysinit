package render

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func sampleChange() *ir.Change {
	return &ir.Change{
		Name: "demo",
		Proposal: &ir.Proposal{
			Why:         "Because we must.",
			WhatChanges: "- Introduce the widget.",
			NonGoals:    "- Not the gadget.",
			Capabilities: ir.Capabilities{
				New: []ir.Capability{{Name: "widget", Description: "the widget"}},
			},
		},
		Design: &ir.Design{
			Context:       "Greenfield.",
			Goals:         "- Ship it.",
			Decisions:     "Use Go.",
			Risks:         "Might be slow.",
			OpenQuestions: "How fast?",
		},
		Specs: []*ir.Spec{
			{
				Capability: "widget",
				Requirements: []ir.Requirement{
					{
						Name:  "Does widget things",
						Delta: ir.DeltaAdded,
						Text:  "It SHALL widget.",
						Scenarios: []ir.Scenario{
							{Name: "Widgets", Steps: []string{"**WHEN** asked", "**THEN** widgets"}},
						},
					},
				},
			},
		},
		Tasks: &ir.Tasks{
			Phases: []ir.Phase{
				{Number: "1", Name: "Build", Items: []ir.TaskItem{
					{ID: "1.1", Text: "Make it", Done: true, Kind: ir.KindPlain},
				}},
			},
		},
	}
}

func TestRenderTargets(t *testing.T) {
	c := sampleChange()
	for _, target := range SupportedTargets() {
		out, _, err := Render(c, target, Options{})
		if err != nil {
			t.Fatalf("render %s: %v", target, err)
		}
		if len(bytes.TrimSpace(out)) == 0 {
			t.Errorf("render %s produced empty output", target)
		}
	}
}

func TestRenderRFCHasCanonicalSectionsInOrder(t *testing.T) {
	out, _, err := Render(sampleChange(), "rfc", Options{})
	if err != nil {
		t.Fatal(err)
	}
	canonical := []string{
		"## Summary",
		"## Motivation",
		"## Guide-level explanation",
		"## Reference-level explanation",
		"## Drawbacks",
		"## Rationale and alternatives",
		"## Unresolved questions",
		"## Future possibilities",
	}
	s := string(out)
	last := -1
	for _, h := range canonical {
		i := strings.Index(s, h)
		if i < 0 {
			t.Errorf("missing canonical section %q", h)
			continue
		}
		if i < last {
			t.Errorf("section %q out of order", h)
		}
		last = i
	}
}

func TestRenderDeterministic(t *testing.T) {
	c := sampleChange()
	a, _, err := Render(c, "rfc", Options{})
	if err != nil {
		t.Fatal(err)
	}
	b, _, err := Render(c, "rfc", Options{})
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(a, b) {
		t.Error("render is not byte-deterministic across runs")
	}
}

func TestRenderUnknownTarget(t *testing.T) {
	_, _, err := Render(sampleChange(), "bogus", Options{})
	if err == nil {
		t.Fatal("expected error for unknown target")
	}
	if !strings.Contains(err.Error(), "bogus") || !strings.Contains(err.Error(), "rfc") {
		t.Errorf("error should name the bad target and list supported: %v", err)
	}
}

func TestRenderAbsentSectionWarnsAndPlaceholders(t *testing.T) {
	c := &ir.Change{Name: "bare", Proposal: &ir.Proposal{Why: "x"}}
	out, warns, err := Render(c, "rfc", Options{})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(out), placeholder) {
		t.Error("expected placeholder for absent sections")
	}
	if len(warns) == 0 {
		t.Error("expected warnings naming absent source sections")
	}
}

func TestRenderOverrideTemplate(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "rfc.md.tmpl"), []byte("OVERRIDE {{ .Title }}"), 0o644); err != nil {
		t.Fatal(err)
	}
	out, _, err := Render(sampleChange(), "rfc", Options{OverrideDir: dir})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(string(out), "OVERRIDE Demo") {
		t.Errorf("override template not honored: %q", string(out))
	}
}

func TestRenderOverrideMissingFallsBackLoudly(t *testing.T) {
	dir := t.TempDir()
	out, warns, err := Render(sampleChange(), "design", Options{OverrideDir: dir})
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(out), "# Design:") {
		t.Error("expected embedded default to be used as fallback")
	}
	found := false
	for _, w := range warns {
		if strings.Contains(w.Msg, "not found") && strings.Contains(w.Msg, "embedded default") {
			found = true
		}
	}
	if !found {
		t.Errorf("expected loud fallback warning, got %v", warns)
	}
}
