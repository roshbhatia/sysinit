package ir

type Section struct {
	Raw string
}

type Change struct {
	Name     string
	Root     string
	Proposal *Proposal
	Specs    []*Spec
	Design   *Design
	Tasks    *Tasks
	Warnings []Warning
}

type Proposal struct {
	Section
	Why          string
	WhatChanges  string
	NonGoals     string
	Capabilities Capabilities
}

type Capabilities struct {
	New      []Capability
	Modified []Capability
}

type Capability struct {
	Name        string
	Description string
}

type DeltaOp string

const (
	DeltaAdded    DeltaOp = "ADDED"
	DeltaModified DeltaOp = "MODIFIED"
	DeltaRemoved  DeltaOp = "REMOVED"
	DeltaRenamed  DeltaOp = "RENAMED"
)

type Spec struct {
	Section
	Capability   string
	Requirements []Requirement
}

type Requirement struct {
	Section
	Name      string
	Delta     DeltaOp
	Text      string
	Scenarios []Scenario

	Markers map[string]string
}

type Scenario struct {
	Section
	Name  string
	Steps []string

	Markers map[string]string
}

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

type TaskKind string

const (
	KindPlain   TaskKind = "task"
	KindVerify  TaskKind = "verify"
	KindApply   TaskKind = "apply"
	KindConfirm TaskKind = "confirm"
)

type Tasks struct {
	Section
	Phases []Phase
}

type Phase struct {
	Number string
	Name   string
	Items  []TaskItem

	Notes []string

	Markers map[string]string
}

type TaskItem struct {
	ID         string
	Text       string
	Done       bool
	Kind       TaskKind
	Tags       []string
	InlineRefs []string

	Fields map[string][]string

	DependsOn []string
}

type Warning struct {
	File string
	Line int
	Msg  string
}

type EdgeKind string

const (
	EdgeContains    EdgeKind = "contains"
	EdgeSpecifiedBy EdgeKind = "specified_by"
	EdgeVerifiedBy  EdgeKind = "verified_by"
)

type Edge struct {
	Kind EdgeKind
	From string
	To   string
}

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
