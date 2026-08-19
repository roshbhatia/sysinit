package export

import (
	"regexp"
	"strings"
	"unicode"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/ir"
)

type Change struct {
	Name string

	Title string

	Summary string

	Scope []string

	Criteria []Criterion

	Milestones []Milestone
}

type Milestone struct {
	Name     string
	Position int
	Tickets  []Ticket
}

type Ticket struct {
	Title string

	Kind string

	Done bool

	Position int

	Milestone string

	Labels []string

	Refs []string

	SourceText  string
	SourceGroup string
}

type Criterion struct {
	Capability string

	Requirement string

	Name string

	Given []string
	When  []string
	Then  []string

	Steps []string

	Negative bool
}

var stepKeywordRe = regexp.MustCompile(`(?i)^[*_\s]*(given|when|then|and|but)\b[*_]*:?\s*`)

var slugSepRe = regexp.MustCompile(`[-_]+`)

var labelCleanRe = regexp.MustCompile(`[^a-z0-9]+`)

var leadingNumberRe = regexp.MustCompile(`^\d+[.)]?\s*`)

var kindPrefixRe = regexp.MustCompile(`(?i)^(verify|apply|confirm)\s*:?\s+`)

func BuildChange(c *ir.Change) Change {
	if c == nil {
		return Change{}
	}
	out := Change{
		Name:       c.Name,
		Title:      Humanize(c.Name),
		Milestones: []Milestone{},
		Criteria:   []Criterion{},
	}
	if c.Proposal != nil {
		out.Summary = strings.TrimSpace(c.Proposal.Why)
		out.Scope = bulletLines(c.Proposal.WhatChanges)
	}
	out.Criteria = buildCriteria(c.Specs)

	if c.Tasks == nil {
		return out
	}
	position := 0
	for pi, p := range c.Tasks.Phases {
		name := milestoneName(p, pi)
		ms := Milestone{Name: name, Position: pi + 1, Tickets: []Ticket{}}
		for _, it := range p.Items {
			position++
			ms.Tickets = append(ms.Tickets, Ticket{
				Title:     TicketTitle(it.Text),
				Kind:      ticketKind(it.Kind),
				Done:      it.Done,
				Position:  position,
				Milestone: name,
				Labels:    labelsFor(name, it),
				Refs:      it.InlineRefs,

				SourceText:  it.Text,
				SourceGroup: p.Number + " " + p.Name,
			})
		}
		out.Milestones = append(out.Milestones, ms)
	}
	return out
}

func milestoneName(p ir.Phase, index int) string {
	name := strings.TrimSpace(leadingNumberRe.ReplaceAllString(p.Name, ""))
	if name == "" {
		return "Stage " + ordinalWord(index)
	}
	return capitalize(name)
}

func ordinalWord(index int) string {
	words := []string{"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
	if index >= 0 && index < len(words) {
		return words[index]
	}
	return "later"
}

func ticketKind(k ir.TaskKind) string {
	if k == "" || k == ir.KindPlain {
		return ""
	}
	return string(k)
}

func labelsFor(milestone string, it ir.TaskItem) []string {
	var labels []string
	if seg := labelSegment(milestone); seg != "" {
		labels = append(labels, "stage:"+seg)
	}
	if k := ticketKind(it.Kind); k != "" {
		labels = append(labels, "kind:"+k)
	}
	for _, tag := range it.Tags {
		if seg := labelSegment(tag); seg != "" {
			labels = append(labels, seg)
		}
	}
	return labels
}

func labelSegment(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = labelCleanRe.ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}

func TicketTitle(text string) string {
	t := strings.TrimSpace(text)
	t = kindPrefixRe.ReplaceAllString(t, "")
	t = strings.TrimSpace(t)
	t = strings.TrimSuffix(t, ".")
	return capitalize(t)
}

func capitalize(s string) string {
	if s == "" {
		return s
	}
	r := []rune(s)
	if !unicode.IsLower(r[0]) {
		return s
	}
	r[0] = unicode.ToUpper(r[0])
	return string(r)
}

func Humanize(slug string) string {
	s := strings.TrimSpace(slugSepRe.ReplaceAllString(slug, " "))
	return capitalize(s)
}

func bulletLines(src string) []string {
	var out []string
	var plain []string
	for _, raw := range strings.Split(src, "\n") {
		line := strings.TrimSpace(raw)
		if line == "" {
			continue
		}
		if rest, ok := strings.CutPrefix(line, "- "); ok {
			out = append(out, strings.TrimSpace(rest))
			continue
		}
		if rest, ok := strings.CutPrefix(line, "* "); ok {
			out = append(out, strings.TrimSpace(rest))
			continue
		}
		plain = append(plain, line)
	}
	if len(out) == 0 {
		return plain
	}
	return out
}

func buildCriteria(specs []*ir.Spec) []Criterion {
	out := []Criterion{}
	for _, s := range specs {
		if s == nil {
			continue
		}
		for _, r := range s.Requirements {
			if r.Delta == ir.DeltaRemoved || r.Delta == ir.DeltaRenamed {
				continue
			}
			for _, sc := range r.Scenarios {
				out = append(out, buildCriterion(s.Capability, r.Name, sc))
			}
		}
	}
	return out
}

func buildCriterion(capability, requirement string, sc ir.Scenario) Criterion {
	c := Criterion{
		Capability:  Humanize(capability),
		Requirement: Humanize(requirement),
		Name:        capitalize(strings.TrimSpace(sc.Name)),
		Negative:    isNegative(sc),
	}
	last := ""
	for _, step := range sc.Steps {
		keyword, body := splitStep(step)
		if body == "" {
			continue
		}
		switch keyword {
		case "given", "when", "then":
			last = keyword
		case "and", "but":
			if last == "" {
				c.Steps = append(c.Steps, body)
				continue
			}
			keyword = last
		default:
			c.Steps = append(c.Steps, body)
			continue
		}
		switch keyword {
		case "given":
			c.Given = append(c.Given, body)
		case "when":
			c.When = append(c.When, body)
		case "then":
			c.Then = append(c.Then, body)
		}
	}
	return c
}

var negativeNameRe = regexp.MustCompile(`(?i)\b(invalid|missing|expired|malformed|unauthori[sz]ed|forbidden|reject|refus|denied|fail|error|absent|unknown|conflict|duplicate|not found|empty|bad|timeout|corrupt)`)

func isNegative(sc ir.Scenario) bool {
	if p, ok := sc.Markers["polarity"]; ok {
		return strings.EqualFold(strings.TrimSpace(p), "negative")
	}
	return negativeNameRe.MatchString(sc.Name)
}

func splitStep(step string) (keyword, body string) {
	s := strings.TrimSpace(step)
	m := stepKeywordRe.FindStringSubmatchIndex(s)
	if m == nil {
		return "", s
	}
	keyword = strings.ToLower(s[m[2]:m[3]])
	body = strings.TrimSpace(s[m[1]:])
	return keyword, body
}

func (c Change) Tickets() []Ticket {
	var out []Ticket
	for _, m := range c.Milestones {
		out = append(out, m.Tickets...)
	}
	return out
}

func (c Change) CriteriaByRequirement() []RequirementGroup {
	var out []RequirementGroup
	index := map[string]int{}
	for _, cr := range c.Criteria {
		key := cr.Capability + "\x00" + cr.Requirement
		i, ok := index[key]
		if !ok {
			index[key] = len(out)
			out = append(out, RequirementGroup{Capability: cr.Capability, Requirement: cr.Requirement})
			i = len(out) - 1
		}
		out[i].Criteria = append(out[i].Criteria, cr)
	}
	return out
}

type RequirementGroup struct {
	Capability  string
	Requirement string
	Criteria    []Criterion
}

func (g RequirementGroup) Negatives() int {
	n := 0
	for _, c := range g.Criteria {
		if c.Negative {
			n++
		}
	}
	return n
}

func (g RequirementGroup) SuccessOnly() bool {
	return len(g.Criteria) > 0 && g.Negatives() == 0
}
