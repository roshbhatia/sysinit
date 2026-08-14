package render

import (
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/export"
	"github.com/roshbhatia/specutil/internal/ir"
)

type Field struct {
	Key string

	Source func(*ir.Change) string
}

type Mapping struct {
	Target string
	Fields []Field
}

var mappings = map[string]Mapping{
	"rfc": {
		Target: "rfc",
		Fields: []Field{
			{"summary", proposalWhy},
			{"motivation", proposalWhatChanges},
			{"guide", guideLevel},
			{"reference", specsMarkdown},
			{"drawbacks", designRisks},
			{"alternatives", designDecisions},
			{"unresolved", designOpenQuestions},
			{"future", proposalNonGoals},
		},
	},
	"design": {
		Target: "design",
		Fields: []Field{
			{"context", designContext},
			{"goals", designGoals},
			{"decisions", designDecisions},
			{"risks", designRisks},
			{"migration", designMigration},
			{"openquestions", designOpenQuestions},
			{"proposal", proposalWhatChanges},
		},
	},
	"tickets": {
		Target: "tickets",

		Fields: []Field{
			{"summary", proposalWhy},
		},
	},
}

func SupportedTargets() []string {
	out := make([]string, 0, len(mappings))
	for k := range mappings {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

func proposalWhy(c *ir.Change) string {
	if c.Proposal == nil {
		return ""
	}
	return c.Proposal.Why
}

func proposalWhatChanges(c *ir.Change) string {
	if c.Proposal == nil {
		return ""
	}
	return c.Proposal.WhatChanges
}

func proposalNonGoals(c *ir.Change) string {
	if c.Proposal == nil {
		return ""
	}
	return c.Proposal.NonGoals
}

func designContext(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.Context
}

func designGoals(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.Goals
}

func designDecisions(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.Decisions
}

func designRisks(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.Risks
}

func designMigration(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.Migration
}

func designOpenQuestions(c *ir.Change) string {
	if c.Design == nil {
		return ""
	}
	return c.Design.OpenQuestions
}

func guideLevel(c *ir.Change) string {
	var b strings.Builder
	if c.Proposal != nil {
		caps := append(append([]ir.Capability{}, c.Proposal.Capabilities.New...), c.Proposal.Capabilities.Modified...)
		for _, cap := range caps {
			b.WriteString("- **")
			b.WriteString(cap.Name)
			b.WriteString("**")
			if cap.Description != "" {
				b.WriteString(" — ")
				b.WriteString(cap.Description)
			}
			b.WriteString("\n")
		}
	}
	if c.Design != nil && c.Design.Context != "" {
		if b.Len() > 0 {
			b.WriteString("\n")
		}
		b.WriteString(c.Design.Context)
	}
	return strings.TrimRight(b.String(), "\n")
}

func specsMarkdown(c *ir.Change) string {
	specs := append([]*ir.Spec{}, c.Specs...)
	sort.SliceStable(specs, func(i, j int) bool { return specs[i].Capability < specs[j].Capability })
	sorted := &ir.Change{Name: c.Name, Specs: specs}

	var b strings.Builder
	for _, group := range export.BuildChange(sorted).CriteriaByRequirement() {
		b.WriteString("#### ")
		b.WriteString(group.Requirement)
		b.WriteString("\n\n")
		if text := requirementText(specs, group.Requirement); text != "" {
			b.WriteString(text)
			b.WriteString("\n\n")
		}
		for _, cr := range group.Criteria {
			b.WriteString("- **")
			b.WriteString(cr.Name)
			b.WriteString("**\n")
			writeSteps(&b, "Given", cr.Given)
			writeSteps(&b, "When", cr.When)
			writeSteps(&b, "Then", cr.Then)
			writeSteps(&b, "", cr.Steps)
		}
		b.WriteString("\n")
	}
	return strings.TrimRight(b.String(), "\n")
}

func writeSteps(b *strings.Builder, keyword string, steps []string) {
	for _, s := range steps {
		b.WriteString("  - ")
		if keyword != "" {
			b.WriteString(keyword)
			b.WriteString(" ")
		}
		b.WriteString(s)
		b.WriteString("\n")
	}
}

func requirementText(specs []*ir.Spec, want string) string {
	for _, s := range specs {
		for _, r := range s.Requirements {
			if export.Humanize(r.Name) == want {
				return r.Text
			}
		}
	}
	return ""
}
