// Package ir defines the normalized, framework-agnostic intermediate
// representation that every specutil projection (render, plan, graph, web)
// consumes. The model is hybrid: each section carries both structured fields
// and its retained raw markdown block for lossless round-trip.
package ir

// Section is the common base for any parsed artifact section. Raw holds the
// original markdown body verbatim so renderers can pass prose through untouched.
type Section struct {
	Raw string
}

// Change is a single workstream loaded from a provider (e.g. an OpenSpec
// change). Artifact pointers are nil when the source omitted them.
// Annotations carries provider-specific metadata (e.g. "bmad.status",
// "github.url") without polluting the typed struct. Nil is equivalent to
// an empty map; callers must not assume it is non-nil.
type Change struct {
	Name        string
	Root        string
	Proposal    *Proposal
	Specs       []*Spec
	Design      *Design
	Tasks       *Tasks
	Warnings    []Warning
	Annotations map[string]string
}

// Proposal models proposal.md.
type Proposal struct {
	Section
	Why          string
	WhatChanges  string
	NonGoals     string
	Capabilities Capabilities
	Impact       string
}

// Capabilities splits the proposal's capability declarations.
type Capabilities struct {
	New      []Capability
	Modified []Capability
}

// Capability is one entry under New or Modified capabilities.
type Capability struct {
	Name        string
	Description string
}

// DeltaOp tags a requirement block with its spec delta operation.
type DeltaOp string

const (
	DeltaAdded    DeltaOp = "ADDED"
	DeltaModified DeltaOp = "MODIFIED"
	DeltaRemoved  DeltaOp = "REMOVED"
	DeltaRenamed  DeltaOp = "RENAMED"
)

// Spec models one specs/<capability>/spec.md file.
type Spec struct {
	Section
	Capability   string
	Requirements []Requirement
}

// Requirement is a `### Requirement:` block and its scenarios.
type Requirement struct {
	Section
	Name      string
	Delta     DeltaOp
	Text      string
	Scenarios []Scenario
	// Markers holds schema-declared facts lifted from the block's bullets by
	// the extract pass. Nil when the repository declares no extraction.
	Markers map[string]string
}

// Scenario is a `#### Scenario:` block.
type Scenario struct {
	Section
	Name  string
	Steps []string
	// Markers holds schema-declared facts lifted from the block's bullets by
	// the extract pass (e.g. "polarity": "negative"). Nil when the repository
	// declares no extraction.
	Markers map[string]string
}

// Design models design.md.
type Design struct {
	Section
	Context       string
	Goals         string
	NonGoals      string
	Decisions     string
	Risks         string
	Rollout       string
	Migration     string
	OpenQuestions string
}

// TaskKind classifies a task item per the verify/apply/confirm discipline.
type TaskKind string

const (
	KindPlain   TaskKind = "task"
	KindVerify  TaskKind = "verify"
	KindApply   TaskKind = "apply"
	KindConfirm TaskKind = "confirm"
)

// Tasks models tasks.md.
type Tasks struct {
	Section
	Phases []Phase
}

// Phase is a `## N. Name` task group.
type Phase struct {
	Number string
	Name   string
	Items  []TaskItem
	// Notes holds the phase's non-checkbox bullets verbatim. They are retained
	// rather than dropped so a config-driven extract pass can interpret the
	// ones a spec framework defines; whatever it does not claim stays here.
	Notes []string
	// Markers holds schema-declared facts lifted from Notes by the extract pass
	// (e.g. "shape": "loop"). Nil when the repository declares no extraction.
	Markers map[string]string
}

// TaskItem is a single `- [ ] N.M` checkbox.
type TaskItem struct {
	ID         string
	Text       string
	Done       bool
	Kind       TaskKind
	Tags       []string // bracket-prefixed labels extracted from text: [BLOCKER], [residency], …
	InlineRefs []string // ticket/PR references found in text: INF-2345, #219, …
	// Fields holds schema-declared inline values lifted from Text by the
	// extract pass. Nil when the repository declares no extraction.
	Fields map[string][]string
	// DependsOn lists the IDs of sibling tasks this task waits on, resolved
	// from any taskRefs-typed field. Empty when none are declared.
	DependsOn []string
}

// Warning records a recoverable parse problem so malformed input is surfaced
// loudly rather than dropped silently.
type Warning struct {
	File string
	Line int
	Msg  string
}

// EdgeKind labels an internal IR edge.
type EdgeKind string

const (
	EdgeContains    EdgeKind = "contains"     // change -> capability
	EdgeSpecifiedBy EdgeKind = "specified_by" // capability -> requirement
	EdgeVerifiedBy  EdgeKind = "verified_by"  // requirement/change -> task
)

// Edge is a directed internal edge in a change's structure graph.
type Edge struct {
	Kind EdgeKind
	From string
	To   string
}

// Edges projects the change's internal structure as directed edges:
// change -> capability -> requirement, plus change -> task. Task-to-requirement
// linkage is left to higher layers since OpenSpec does not encode it explicitly.
func (c *Change) Edges() []Edge {
	var edges []Edge
	if c.Proposal != nil {
		for _, cap := range c.Proposal.Capabilities.New {
			edges = append(edges, Edge{EdgeContains, c.Name, cap.Name})
		}
		for _, cap := range c.Proposal.Capabilities.Modified {
			edges = append(edges, Edge{EdgeContains, c.Name, cap.Name})
		}
	}
	for _, s := range c.Specs {
		for _, r := range s.Requirements {
			edges = append(edges, Edge{EdgeSpecifiedBy, s.Capability, r.Name})
		}
	}
	if c.Tasks != nil {
		for _, p := range c.Tasks.Phases {
			for _, t := range p.Items {
				edges = append(edges, Edge{EdgeVerifiedBy, c.Name, t.ID})
			}
		}
	}
	return edges
}
