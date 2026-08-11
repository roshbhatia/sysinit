package parse

import (
	"regexp"
	"strings"

	"github.com/roshbhatia/specutil/internal/ir"
)

// Regexes for the lenient structural recovery. None are anchored to exact
// whitespace so minor authoring drift still parses.
var (
	taskLineRe    = regexp.MustCompile(`^(\d+(?:\.\d+)*)\s+(.*)$`)
	deltaTitleRe  = regexp.MustCompile(`(?i)^(ADDED|MODIFIED|REMOVED|RENAMED)\s+Requirements?$`)
	capNameRe     = regexp.MustCompile("^[*`]*\\s*([^*`:]+?)\\s*[*`]*\\s*:\\s*(.*)$")
	phaseNumberRe = regexp.MustCompile(`^(\d+)\.?\s*`)
	bracketTagRe  = regexp.MustCompile(`^\[([^\]]+)\]\s*`)
	// ticketRefRe matches Jira/Linear-style IDs (INF-2345, PR-123, etc.)
	ticketRefRe = regexp.MustCompile(`\b([A-Z]{2,10}-\d+)\b`)
	// prRefRe matches GitHub PR/issue refs (#219); no leading \b since # is non-word
	prRefRe = regexp.MustCompile(`#(\d+)\b`)
)

// extractBracketTags peels leading [TAG] tokens from text, returning the tags
// and the cleaned text with those tokens removed.
func extractBracketTags(text string) ([]string, string) {
	text = strings.TrimSpace(text)
	var tags []string
	for {
		m := bracketTagRe.FindStringSubmatchIndex(text)
		if m == nil {
			break
		}
		tags = append(tags, text[m[2]:m[3]])
		text = text[m[1]:]
	}
	return tags, strings.TrimSpace(text)
}

// extractInlineRefs finds ticket/PR identifiers embedded in text, deduped and
// in order of first appearance.
func extractInlineRefs(text string) []string {
	seen := make(map[string]bool)
	var out []string
	for _, m := range ticketRefRe.FindAllString(text, -1) {
		if !seen[m] {
			seen[m] = true
			out = append(out, m)
		}
	}
	for _, m := range prRefRe.FindAllString(text, -1) {
		if !seen[m] {
			seen[m] = true
			out = append(out, m)
		}
	}
	if len(out) == 0 {
		return nil
	}
	return out
}

// ParseProposal maps a proposal.md section forest into ir.Proposal.
func ParseProposal(file, src string) (*ir.Proposal, []ir.Warning) {
	var warns []ir.Warning
	_, roots := SplitSections(src)
	p := &ir.Proposal{Section: ir.Section{Raw: src}}

	if n := findRoot(roots, "Why"); n != nil {
		p.Why = strings.TrimSpace(n.Body)
	} else {
		warns = append(warns, ir.Warning{File: file, Msg: "proposal missing '## Why' section"})
	}

	if n := findRoot(roots, "What Changes"); n != nil {
		p.WhatChanges = strings.TrimSpace(n.Body)
		if ng := findChild(n, "Non-goals"); ng != nil {
			p.NonGoals = strings.TrimSpace(ng.Body)
		}
	} else {
		warns = append(warns, ir.Warning{File: file, Msg: "proposal missing '## What Changes' section"})
	}

	if n := findRoot(roots, "Capabilities"); n != nil {
		p.Capabilities.New = parseCapabilityChild(n, "New Capabilities")
		p.Capabilities.Modified = parseCapabilityChild(n, "Modified Capabilities")
	}

	if n := findRoot(roots, "Impact"); n != nil {
		p.Impact = strings.TrimSpace(n.Body)
	}

	return p, warns
}

// parseCapabilityChild extracts capability bullets from a named child section.
func parseCapabilityChild(parent *Node, title string) []ir.Capability {
	child := findChild(parent, title)
	if child == nil {
		return nil
	}
	var caps []ir.Capability
	for _, it := range extractListItems(child.Body) {
		if m := capNameRe.FindStringSubmatch(it.text); m != nil {
			caps = append(caps, ir.Capability{Name: strings.TrimSpace(m[1]), Description: strings.TrimSpace(m[2])})
		} else if t := strings.TrimSpace(it.text); t != "" {
			caps = append(caps, ir.Capability{Name: t})
		}
	}
	return caps
}

// ParseSpec maps a specs/<capability>/spec.md into ir.Spec. capability is the
// directory name the spec was discovered under.
func ParseSpec(file, capability, src string) (*ir.Spec, []ir.Warning) {
	var warns []ir.Warning
	_, roots := SplitSections(src)
	spec := &ir.Spec{Section: ir.Section{Raw: src}, Capability: capability}

	for _, deltaSection := range roots {
		m := deltaTitleRe.FindStringSubmatch(strings.TrimSpace(deltaSection.Title))
		if m == nil {
			continue
		}
		delta := ir.DeltaOp(strings.ToUpper(m[1]))
		for _, child := range deltaSection.Children {
			title := strings.TrimSpace(child.Title)
			// Lenient recovery: a `### Scenario:` authored at requirement depth
			// becomes a sibling of the requirement. Attach it to the preceding
			// requirement instead of treating it as a bogus requirement.
			if scName, isScenario := strings.CutPrefix(title, "Scenario:"); isScenario {
				warns = append(warns, ir.Warning{
					File: file, Line: child.StartLine,
					Msg: "scenario '" + strings.TrimSpace(scName) + "' is at heading level " +
						itoa(child.Level) + ", expected 4 (####); attaching to preceding requirement",
				})
				if n := len(spec.Requirements); n > 0 {
					spec.Requirements[n-1].Scenarios = append(spec.Requirements[n-1].Scenarios, scenarioFromNode(child, scName))
				} else {
					warns = append(warns, ir.Warning{File: file, Line: child.StartLine, Msg: "stray scenario with no preceding requirement"})
				}
				continue
			}

			name, ok := strings.CutPrefix(title, "Requirement:")
			if !ok {
				warns = append(warns, ir.Warning{
					File: file, Line: child.StartLine,
					Msg: "expected '### Requirement: <name>', got '" + child.Title + "'",
				})
				name = child.Title
			}
			req := ir.Requirement{
				Section: ir.Section{Raw: child.Raw},
				Name:    strings.TrimSpace(name),
				Delta:   delta,
				Text:    strings.TrimSpace(child.Body),
			}
			req.Scenarios, warns = parseScenarios(file, child, warns)
			spec.Requirements = append(spec.Requirements, req)
		}
	}

	for _, r := range spec.Requirements {
		// Only ADDED/MODIFIED requirements describe behavior via scenarios.
		// REMOVED and RENAMED blocks carry Reason/Migration prose instead, so
		// absent scenarios there are expected, not malformed.
		if len(r.Scenarios) == 0 && (r.Delta == ir.DeltaAdded || r.Delta == ir.DeltaModified) {
			warns = append(warns, ir.Warning{File: file, Msg: "requirement '" + r.Name + "' has no scenarios"})
		}
	}

	if len(spec.Requirements) == 0 {
		warns = append(warns, ir.Warning{File: file, Msg: "spec has no delta requirement sections (## ADDED/MODIFIED/REMOVED/RENAMED Requirements)"})
	}
	return spec, warns
}

// parseScenarios recovers scenarios from a requirement node. OpenSpec mandates
// 4-hashtag scenarios (children of the 3-hashtag requirement); we also recover
// scenarios authored at the wrong depth, warning loudly.
func parseScenarios(file string, reqNode *Node, warns []ir.Warning) ([]ir.Scenario, []ir.Warning) {
	var scenarios []ir.Scenario
	for _, child := range reqNode.Children {
		name, ok := strings.CutPrefix(strings.TrimSpace(child.Title), "Scenario:")
		if !ok {
			continue
		}
		if child.Level != 4 {
			warns = append(warns, ir.Warning{
				File: file, Line: child.StartLine,
				Msg: "scenario '" + strings.TrimSpace(name) + "' is at heading level " +
					itoa(child.Level) + ", expected 4 (####)",
			})
		}
		scenarios = append(scenarios, scenarioFromNode(child, name))
	}
	return scenarios, warns
}

// scenarioFromNode builds an ir.Scenario from a heading node, extracting its
// WHEN/THEN bullet steps.
func scenarioFromNode(child *Node, name string) ir.Scenario {
	sc := ir.Scenario{Section: ir.Section{Raw: child.Raw}, Name: strings.TrimSpace(name)}
	for _, it := range extractListItems(child.Body) {
		if t := strings.TrimSpace(it.text); t != "" {
			sc.Steps = append(sc.Steps, t)
		}
	}
	return sc
}

// ParseDesign maps design.md into ir.Design. Section titles tolerate the common
// "Goals / Non-Goals" and "Risks / Trade-offs" combined headings.
func ParseDesign(file, src string) (*ir.Design, []ir.Warning) {
	_, roots := SplitSections(src)
	d := &ir.Design{Section: ir.Section{Raw: src}}
	for _, n := range roots {
		title := strings.ToLower(strings.TrimSpace(n.Title))
		body := strings.TrimSpace(n.Body)
		switch {
		case strings.HasPrefix(title, "context"):
			d.Context = body
		case strings.Contains(title, "non-goal"):
			d.NonGoals = body
		case strings.Contains(title, "goal"):
			d.Goals = body
		case strings.HasPrefix(title, "decision"):
			d.Decisions = body
		case strings.Contains(title, "risk") || strings.Contains(title, "trade-off"):
			d.Risks = body
		case strings.Contains(title, "rollout"):
			d.Rollout = body
		case strings.Contains(title, "migration"):
			d.Migration = body
		case strings.Contains(title, "open question"):
			d.OpenQuestions = body
		}
	}
	return d, nil
}

// ParseTasks maps tasks.md into ir.Tasks, classifying each item's kind and
// preserving phase grouping.
func ParseTasks(file, src string) (*ir.Tasks, []ir.Warning) {
	var warns []ir.Warning
	_, roots := SplitSections(src)
	t := &ir.Tasks{Section: ir.Section{Raw: src}}

	for _, phaseNode := range roots {
		phase := ir.Phase{Name: strings.TrimSpace(phaseNode.Title)}
		if m := phaseNumberRe.FindStringSubmatch(phase.Name); m != nil {
			phase.Number = m[1]
			phase.Name = strings.TrimSpace(phaseNumberRe.ReplaceAllString(phase.Name, ""))
		}
		for _, it := range extractListItems(phaseNode.Body) {
			if !it.hasBox {
				// Retain the bullet verbatim. A spec framework may state a fact
				// about the phase here (its shape, a loop bound); the extract
				// pass decides, not the parser.
				if t := strings.TrimSpace(it.text); t != "" {
					phase.Notes = append(phase.Notes, t)
				}
				continue
			}
			item := ir.TaskItem{Done: it.checked, Kind: ir.KindPlain}
			if m := taskLineRe.FindStringSubmatch(it.text); m != nil {
				item.ID = m[1]
				item.Text = strings.TrimSpace(m[2])
			} else {
				item.Text = it.text
				warns = append(warns, ir.Warning{File: file, Msg: "task item missing N.M identifier: " + it.text})
			}
			item.Tags, item.Text = extractBracketTags(item.Text)
			item.InlineRefs = extractInlineRefs(item.Text)
			item.Kind = classifyTask(item.Text)
			phase.Items = append(phase.Items, item)
		}
		if len(phase.Items) > 0 {
			t.Phases = append(t.Phases, phase)
		}
	}
	if len(t.Phases) == 0 {
		warns = append(warns, ir.Warning{File: file, Msg: "tasks.md has no '## N. Phase' sections with checkbox items"})
	}
	return t, warns
}

// classifyTask tags a task by its leading keyword per the verify/apply/confirm
// discipline.
func classifyTask(text string) ir.TaskKind {
	lower := strings.ToLower(text)
	switch {
	case strings.HasPrefix(lower, "verify:") || strings.HasPrefix(lower, "verify "):
		return ir.KindVerify
	case strings.HasPrefix(lower, "apply:") || strings.HasPrefix(lower, "apply "):
		return ir.KindApply
	case strings.HasPrefix(lower, "confirm:") || strings.HasPrefix(lower, "confirm "):
		return ir.KindConfirm
	}
	return ir.KindPlain
}

// itoa is a tiny helper to avoid importing strconv just for warning messages.
func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [4]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	return string(b[i:])
}
