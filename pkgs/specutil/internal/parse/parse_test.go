package parse

import (
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

const sampleProposal = `## Why

We need a thing.

## What Changes

- Introduce the thing.

### Non-goals

- Not the other thing.

## Capabilities

### New Capabilities
- ` + "`cli-foundation`" + `: the cobra root and build tooling.
- ` + "`spec-ingestion`" + `: the provider port and IR.

### Modified Capabilities
<!-- None. -->

## Impact

- New code everywhere.
`

func TestParseProposal(t *testing.T) {
	p, warns := ParseProposal("proposal.md", sampleProposal)
	if len(warns) != 0 {
		t.Fatalf("unexpected warnings: %v", warns)
	}
	if !strings.Contains(p.Why, "need a thing") {
		t.Errorf("Why = %q", p.Why)
	}
	if !strings.Contains(p.WhatChanges, "Introduce the thing") {
		t.Errorf("WhatChanges = %q", p.WhatChanges)
	}
	if !strings.Contains(p.NonGoals, "other thing") {
		t.Errorf("NonGoals = %q", p.NonGoals)
	}
	if len(p.Capabilities.New) != 2 {
		t.Fatalf("expected 2 new capabilities, got %d: %+v", len(p.Capabilities.New), p.Capabilities.New)
	}
	if p.Capabilities.New[0].Name != "cli-foundation" {
		t.Errorf("cap[0].Name = %q", p.Capabilities.New[0].Name)
	}
	if !strings.Contains(p.Capabilities.New[0].Description, "cobra root") {
		t.Errorf("cap[0].Description = %q", p.Capabilities.New[0].Description)
	}
	if len(p.Capabilities.Modified) != 0 {
		t.Errorf("expected 0 modified capabilities, got %+v", p.Capabilities.Modified)
	}

	if p.Raw != sampleProposal {
		t.Errorf("Raw not retained verbatim")
	}
}

const sampleSpec = `## ADDED Requirements

### Requirement: Does a thing
The system SHALL do a thing.

#### Scenario: It does the thing
- **WHEN** invoked
- **THEN** the thing is done

#### Scenario: It rejects bad input
- **WHEN** invoked with garbage
- **THEN** it errors

## MODIFIED Requirements

### Requirement: Changed behavior
It SHALL behave differently now.

#### Scenario: New behavior
- **WHEN** triggered
- **THEN** new behavior
`

func TestParseSpec(t *testing.T) {
	spec, warns := ParseSpec("specs/x/spec.md", "x", sampleSpec)
	if len(warns) != 0 {
		t.Fatalf("unexpected warnings: %v", warns)
	}
	if spec.Capability != "x" {
		t.Errorf("Capability = %q", spec.Capability)
	}
	if len(spec.Requirements) != 2 {
		t.Fatalf("expected 2 requirements, got %d", len(spec.Requirements))
	}
	r0 := spec.Requirements[0]
	if r0.Delta != ir.DeltaAdded {
		t.Errorf("r0.Delta = %q, want ADDED", r0.Delta)
	}
	if r0.Name != "Does a thing" {
		t.Errorf("r0.Name = %q", r0.Name)
	}
	if !strings.Contains(r0.Text, "SHALL do a thing") {
		t.Errorf("r0.Text = %q", r0.Text)
	}
	if len(r0.Scenarios) != 2 {
		t.Fatalf("expected 2 scenarios, got %d", len(r0.Scenarios))
	}
	if r0.Scenarios[0].Name != "It does the thing" {
		t.Errorf("scenario name = %q", r0.Scenarios[0].Name)
	}
	if len(r0.Scenarios[0].Steps) != 2 {
		t.Errorf("expected 2 steps, got %v", r0.Scenarios[0].Steps)
	}
	if !strings.Contains(r0.Scenarios[0].Steps[0], "WHEN") {
		t.Errorf("step[0] = %q", r0.Scenarios[0].Steps[0])
	}
	if spec.Requirements[1].Delta != ir.DeltaModified {
		t.Errorf("r1.Delta = %q, want MODIFIED", spec.Requirements[1].Delta)
	}
}

func TestParseSpecWarnsOnMisnestedScenario(t *testing.T) {
	misnested := `## ADDED Requirements

### Requirement: A req
Text.

### Scenario: Wrong depth
- **WHEN** x
- **THEN** y
`
	spec, warns := ParseSpec("specs/x/spec.md", "x", misnested)
	if len(spec.Requirements) != 1 {
		t.Fatalf("expected 1 requirement (stray scenario should not become one), got %d", len(spec.Requirements))
	}

	if len(spec.Requirements[0].Scenarios) != 1 {
		t.Errorf("expected the stray scenario reattached, got %d scenarios", len(spec.Requirements[0].Scenarios))
	}
	foundDepthWarning := false
	for _, w := range warns {
		if strings.Contains(w.Msg, "expected 4") && strings.Contains(w.Msg, "attaching") {
			foundDepthWarning = true
		}
	}
	if !foundDepthWarning {
		t.Errorf("expected a wrong-depth recovery warning, got %v", warns)
	}
}

func TestParseSpecScenarioWarningSkipsRemovedAndRenamed(t *testing.T) {
	src := `## ADDED Requirements

### Requirement: Has scenarios
Text.

#### Scenario: ok
- **WHEN** x
- **THEN** y

## REMOVED Requirements

### Requirement: Old thing
**Reason**: Replaced.
**Migration**: Use the new thing.

## RENAMED Requirements

### Requirement: Renamed thing
**Reason**: Clearer name.
`
	_, warns := ParseSpec("specs/x/spec.md", "x", src)
	for _, w := range warns {
		if strings.Contains(w.Msg, "has no scenarios") {
			t.Errorf("REMOVED/RENAMED requirements must not warn about missing scenarios, got: %s", w.Msg)
		}
	}

	_, warns = ParseSpec("specs/x/spec.md", "x", "## ADDED Requirements\n\n### Requirement: Empty\nText.\n")
	found := false
	for _, w := range warns {
		if strings.Contains(w.Msg, "has no scenarios") {
			found = true
		}
	}
	if !found {
		t.Errorf("expected a 'has no scenarios' warning for an ADDED requirement with none, got %v", warns)
	}
}

const sampleTasks = `## 1. Foundation

- [x] 1.1 Initialize the module
- [ ] 1.2 Verify: build succeeds
- [ ] 1.3 Confirm: tests are green

## 2. Rollout

- [ ] 2.1 Apply: push the branch
`

func TestParseTasks(t *testing.T) {
	tasks, warns := ParseTasks("tasks.md", sampleTasks)
	if len(warns) != 0 {
		t.Fatalf("unexpected warnings: %v", warns)
	}
	if len(tasks.Phases) != 2 {
		t.Fatalf("expected 2 phases, got %d", len(tasks.Phases))
	}
	p0 := tasks.Phases[0]
	if p0.Number != "1" || p0.Name != "Foundation" {
		t.Errorf("phase0 = %q/%q", p0.Number, p0.Name)
	}
	if len(p0.Items) != 3 {
		t.Fatalf("expected 3 items, got %d", len(p0.Items))
	}
	if !p0.Items[0].Done {
		t.Errorf("item 1.1 should be done")
	}
	if p0.Items[0].ID != "1.1" {
		t.Errorf("item0 ID = %q", p0.Items[0].ID)
	}
	if p0.Items[1].Kind != ir.KindVerify {
		t.Errorf("item 1.2 kind = %q, want verify", p0.Items[1].Kind)
	}
	if p0.Items[2].Kind != ir.KindConfirm {
		t.Errorf("item 1.3 kind = %q, want confirm", p0.Items[2].Kind)
	}
	if tasks.Phases[1].Items[0].Kind != ir.KindApply {
		t.Errorf("item 2.1 kind = %q, want apply", tasks.Phases[1].Items[0].Kind)
	}
}

func TestSplitSectionsIgnoresFencedHeadings(t *testing.T) {
	src := "## Real\n\ntext\n\n" + "```\n## Not a heading\n```\n\n## AlsoReal\n"
	_, roots := SplitSections(src)
	if len(roots) != 2 {
		t.Fatalf("expected 2 roots (fenced heading ignored), got %d: %+v", len(roots), titles(roots))
	}
	if roots[0].Title != "Real" || roots[1].Title != "AlsoReal" {
		t.Errorf("titles = %v", titles(roots))
	}
}

func titles(ns []*Node) []string {
	var out []string
	for _, n := range ns {
		out = append(out, n.Title)
	}
	return out
}

func TestExtractBracketTags(t *testing.T) {
	cases := []struct {
		in       string
		wantTags []string
		wantText string
	}{
		{"[BLOCKER] do the thing", []string{"BLOCKER"}, "do the thing"},
		{"[residency] [last] some work", []string{"residency", "last"}, "some work"},
		{"plain task text", nil, "plain task text"},
		{"[done] **bold text**", []string{"done"}, "**bold text**"},
		{"[BLOCKER] [Urgent] foo", []string{"BLOCKER", "Urgent"}, "foo"},
		{"  [tag]  text  ", []string{"tag"}, "text"},
	}
	for _, tc := range cases {
		tags, text := extractBracketTags(tc.in)
		if len(tags) != len(tc.wantTags) {
			t.Errorf("extractBracketTags(%q) tags = %v, want %v", tc.in, tags, tc.wantTags)
			continue
		}
		for i, tag := range tags {
			if tag != tc.wantTags[i] {
				t.Errorf("extractBracketTags(%q) tag[%d] = %q, want %q", tc.in, i, tag, tc.wantTags[i])
			}
		}
		if text != tc.wantText {
			t.Errorf("extractBracketTags(%q) text = %q, want %q", tc.in, text, tc.wantText)
		}
	}
}

func TestExtractInlineRefs(t *testing.T) {
	cases := []struct {
		in   string
		want []string
	}{
		{"do the thing (INF-2345)", []string{"INF-2345"}},
		{"INF-2149 and INF-2154 — two deps", []string{"INF-2149", "INF-2154"}},
		{"merged PR #219 into main", []string{"#219"}},
		{"INF-2345 twice, INF-2345 again", []string{"INF-2345"}},
		{"no refs here at all", nil},
		{"**bold** `code` plain", nil},
	}
	for _, tc := range cases {
		got := extractInlineRefs(tc.in)
		if len(got) != len(tc.want) {
			t.Errorf("extractInlineRefs(%q) = %v, want %v", tc.in, got, tc.want)
			continue
		}
		for i, r := range got {
			if r != tc.want[i] {
				t.Errorf("extractInlineRefs(%q)[%d] = %q, want %q", tc.in, i, r, tc.want[i])
			}
		}
	}
}

func TestParseTasksExtractsTagsAndRefs(t *testing.T) {
	src := `## 1. Setup

- [ ] 1.1 [BLOCKER] **provision the cluster** (INF-2345); clone ` + "`lhr.tf`" + `
- [x] 1.2 [done] DNS retired (INF-2454)
- [ ] 1.3 plain task with no tags
`
	tasks, _ := ParseTasks("t.md", src)
	if len(tasks.Phases) == 0 || len(tasks.Phases[0].Items) < 3 {
		t.Fatal("expected 3 items in phase 1")
	}
	item0 := tasks.Phases[0].Items[0]
	if len(item0.Tags) != 1 || item0.Tags[0] != "BLOCKER" {
		t.Errorf("item0 tags = %v, want [BLOCKER]", item0.Tags)
	}
	if len(item0.InlineRefs) != 1 || item0.InlineRefs[0] != "INF-2345" {
		t.Errorf("item0 inlineRefs = %v, want [INF-2345]", item0.InlineRefs)
	}
	if strings.Contains(item0.Text, "[BLOCKER]") {
		t.Errorf("item0.Text should not contain the bracket tag: %q", item0.Text)
	}

	item1 := tasks.Phases[0].Items[1]
	if len(item1.Tags) != 1 || item1.Tags[0] != "done" {
		t.Errorf("item1 tags = %v, want [done]", item1.Tags)
	}
	if len(item1.InlineRefs) != 1 || item1.InlineRefs[0] != "INF-2454" {
		t.Errorf("item1 inlineRefs = %v, want [INF-2454]", item1.InlineRefs)
	}

	item2 := tasks.Phases[0].Items[2]
	if len(item2.Tags) != 0 {
		t.Errorf("item2 should have no tags, got %v", item2.Tags)
	}
	if len(item2.InlineRefs) != 0 {
		t.Errorf("item2 should have no inlineRefs, got %v", item2.InlineRefs)
	}
}
