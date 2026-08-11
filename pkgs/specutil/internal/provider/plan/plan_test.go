package plan_test

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/specutil/internal/provider/plan"
)

const planComplete = `# my-feature

## Why

We need this feature to improve user retention.

## What Changes

- user-auth: adds login and session management

## Tasks

### Phase 1: Foundation

- [ ] 1.1 Create login endpoint
- [ ] 1.2 Add session management

### Phase 2: Polish

- [ ] 2.1 Add error messages
`

const planPartial = `# partial-feature

## Why

Only the why section.
`

const planUnknownHeadings = `# my-feature

## Why

Motivation.

## Appendix

This should be silently ignored.

## Tasks

### Phase 1: Work

- [ ] 1.1 Do something
`

func writePlan(t *testing.T, dir, content string) string {
	t.Helper()
	path := filepath.Join(dir, "plan.md")
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("writing plan.md: %v", err)
	}
	return path
}

func TestPlanCompleteParsing(t *testing.T) {
	dir := t.TempDir()
	writePlan(t, dir, planComplete)

	p := plan.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	if c.Name != "my-feature" {
		t.Errorf("Name = %q, want %q", c.Name, "my-feature")
	}
	if c.Proposal == nil || c.Proposal.Why == "" {
		t.Error("Proposal.Why should be populated from ## Why")
	}
	if c.Proposal == nil || c.Proposal.WhatChanges == "" {
		t.Error("Proposal.WhatChanges should be populated from ## What Changes")
	}
	if c.Tasks == nil {
		t.Error("Tasks should be populated from ## Tasks")
	} else if len(c.Tasks.Phases) != 2 {
		t.Errorf("len(Tasks.Phases) = %d, want 2", len(c.Tasks.Phases))
	}
}

func TestPlanMissingSectionWarns(t *testing.T) {
	dir := t.TempDir()
	writePlan(t, dir, planPartial)

	p := plan.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load should not fail on partial plan: %v", err)
	}

	if c.Proposal == nil || c.Proposal.Why == "" {
		t.Error("Proposal.Why should be populated")
	}

	var warnFound bool
	for _, w := range c.Warnings {
		if w.Msg == `[plan]: section "Tasks" absent` {
			warnFound = true
		}
	}
	if !warnFound {
		t.Error("expected warning about missing Tasks section")
	}
}

func TestPlanUnknownHeadingSilentlySkipped(t *testing.T) {
	dir := t.TempDir()
	writePlan(t, dir, planUnknownHeadings)

	p := plan.New(dir, "")
	c, err := p.Load("")
	if err != nil {
		t.Fatalf("Load: %v", err)
	}

	// No warnings about the ## Appendix section.
	for _, w := range c.Warnings {
		if w.Msg != "" && w.Msg == `[plan]: section "Appendix" unrecognized` {
			t.Error("unexpected warning for unknown heading")
		}
	}
	if c.Tasks == nil {
		t.Error("Tasks should still be populated despite unknown heading")
	}
}

func TestPlanAutoDiscover(t *testing.T) {
	dir := t.TempDir()
	writePlan(t, dir, planComplete)

	p := plan.New(dir, "") // no path — auto-discovers plan.md
	names, err := p.List()
	if err != nil {
		t.Fatal(err)
	}
	if len(names) != 1 || names[0] != "my-feature" {
		t.Errorf("List() = %v, want [my-feature]", names)
	}
}

func TestPlanMissingFileError(t *testing.T) {
	dir := t.TempDir()
	p := plan.New(dir, "") // no plan.md in dir
	_, err := p.Load("")
	if err == nil {
		t.Error("expected error for missing plan.md")
	}
}

func TestPlanChangeNameOverride(t *testing.T) {
	dir := t.TempDir()
	writePlan(t, dir, planComplete)

	p := plan.New(dir, "")
	c, err := p.Load("overridden-name")
	if err != nil {
		t.Fatal(err)
	}
	if c.Name != "overridden-name" {
		t.Errorf("Name = %q, want %q", c.Name, "overridden-name")
	}
}
