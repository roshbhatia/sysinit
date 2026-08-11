// Package render projects a change's IR into target artifacts (rfc, design,
// tickets). Rendering is two-layer: a declarative semantic mapping routes IR
// sections into named target sections, then a Go text/template lays them out.
// The mapping (what content goes where) is separable from the template (layout
// and ordering), so a target can be retargeted without rewriting the skeleton.
package render

import (
	"sort"
	"strings"

	"github.com/roshbhatia/specutil/internal/export"
	"github.com/roshbhatia/specutil/internal/ir"
)

// Field is one routed target section: a stable Key the template references and
// a Source that extracts its content from the change's IR.
type Field struct {
	// Key is the section identifier used in the template (e.g. "summary").
	Key string
	// Source extracts the markdown body for this section from the change.
	Source func(*ir.Change) string
}

// Mapping is a target's ordered list of section routings.
type Mapping struct {
	Target string
	Fields []Field
}

// mappings is the registry of supported render targets. Adding a target is a
// matter of declaring its section routing here and shipping a matching template.
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
		// Tickets are projected by iterating the export projection directly in
		// the template; the mapping carries only the lead-in summary.
		Fields: []Field{
			{"summary", proposalWhy},
		},
	},
}

// SupportedTargets returns the sorted list of render targets.
func SupportedTargets() []string {
	out := make([]string, 0, len(mappings))
	for k := range mappings {
		out = append(out, k)
	}
	sort.Strings(out)
	return out
}

// --- IR section source extractors ---

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

// guideLevel composes a guide-level explanation from the proposal's capability
// declarations and the design context.
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

// specsMarkdown renders the requirements and their scenarios as the
// reference-level explanation. It goes through the export projection, so the
// output carries no spec delta keywords and no slugs: a reader outside the
// repository sees requirement names and Given/When/Then acceptance criteria.
// Output is deterministic, sorted by capability then document order.
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

// writeSteps emits one indented bullet per step, prefixed by the Gherkin
// keyword. An empty keyword emits the step verbatim.
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

// requirementText finds the prose body of the requirement whose humanized name
// matches want, so the projection can pair a requirement heading with its
// description.
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
