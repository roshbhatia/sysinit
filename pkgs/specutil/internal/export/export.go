// Package export projects a change into the vocabulary an external tracker
// uses. It is the boundary where spec-framework convention stops: phase
// numbers, task identifiers like "1.2", sibling keys like "1a", and spec delta
// keywords never cross it. Requirements and scenarios are translated into
// acceptance criteria that a reader outside the repository can act on.
//
// Everything here is pure: identical input yields byte-identical output.
package export

import (
	"regexp"
	"strings"
	"unicode"

	"github.com/roshbhatia/specutil/internal/ir"
)

// Change is one workstream in tracker vocabulary. It carries no phase numbers
// and no task identifiers.
type Change struct {
	// Name is the repository-local slug. It is a correlation key, not a label
	// to show an external reader.
	Name string
	// Title is the reader-facing name derived from Name.
	Title string
	// Summary is the one-paragraph motivation (the proposal's Why).
	Summary string
	// Scope lists what the change delivers, one bullet per line.
	Scope []string
	// Criteria are the acceptance criteria translated from the change's specs.
	Criteria []Criterion
	// Milestones are the ordered delivery stages. Tickets inside one milestone
	// can be worked in parallel; a milestone depends on the one before it.
	Milestones []Milestone
}

// Milestone is a delivery stage. Name never carries a leading number.
type Milestone struct {
	Name     string
	Position int
	Tickets  []Ticket
}

// Ticket is one unit of work to create in a tracker.
type Ticket struct {
	// Title is a single outcome sentence with no identifier prefix.
	Title string
	// Kind classifies the step so a tracker can label it. It is empty for a
	// plain task.
	Kind string
	// Done reports whether the local source marks the work complete.
	Done bool
	// Position is the 1-based order across the whole change. Trackers sort on
	// it; readers never see it as text.
	Position int
	// Milestone is the name of the stage this ticket belongs to.
	Milestone string
	// Labels are tracker labels derived from the milestone, the kind, and any
	// bracket tags the author wrote.
	Labels []string
	// Refs are ticket or pull-request identifiers the author already wrote into
	// the task text (INF-2345, #219).
	Refs []string
	// SourceText and SourceGroup are the raw task text and the raw phase
	// heading from the input artifact. They exist only so a caller can compute
	// a lock identity that survives retitling. No renderer shows them.
	SourceText  string
	SourceGroup string
}

// Criterion is one acceptance criterion translated from a spec scenario.
type Criterion struct {
	// Capability is the reader-facing name of the capability under test.
	Capability string
	// Requirement is the reader-facing name of the requirement.
	Requirement string
	// Name is the reader-facing scenario name.
	Name string
	// Given, When, and Then hold the translated steps. Steps written with a
	// continuation keyword (and, but) join the bucket they continue.
	Given []string
	When  []string
	Then  []string
	// Steps holds any step that carried no Given/When/Then keyword, so nothing
	// the author wrote is dropped.
	Steps []string
	// Negative reports that the criterion describes a rejection or failure path
	// rather than a success path. It is read from the scenario's declared
	// polarity marker when the repository extracts one, and inferred from the
	// scenario name otherwise. Trackers group on it so a reviewer can see at a
	// glance whether the error cases were specified.
	Negative bool
}

// stepKeywordRe matches a leading Gherkin keyword, tolerating the bold-caps
// spelling OpenSpec specs commonly use (`- **WHEN** …`).
var stepKeywordRe = regexp.MustCompile(`(?i)^[*_\s]*(given|when|then|and|but)\b[*_]*:?\s*`)

// slugSepRe matches the separators used in capability, requirement, and change
// slugs.
var slugSepRe = regexp.MustCompile(`[-_]+`)

// labelCleanRe reduces a name to a tracker-safe label segment.
var labelCleanRe = regexp.MustCompile(`[^a-z0-9]+`)

// leadingNumberRe matches a phase number prefix that survived parsing.
var leadingNumberRe = regexp.MustCompile(`^\d+[.)]?\s*`)

// kindPrefixRe matches the verify/apply/confirm discipline keyword that opens a
// task. The keyword becomes a label, so it is stripped from the title.
var kindPrefixRe = regexp.MustCompile(`(?i)^(verify|apply|confirm)\s*:?\s+`)

// BuildChange projects an IR change into tracker vocabulary. A nil change
// yields the zero value.
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
				// The phase number joins the raw heading so number-only headings
				// ("## 1." and "## 2.") do not collapse to the same identity.
				SourceText:  it.Text,
				SourceGroup: p.Number + " " + p.Name,
			})
		}
		out.Milestones = append(out.Milestones, ms)
	}
	return out
}

// milestoneName returns a reader-facing stage name. An unnamed phase falls back
// to an ordinal rather than leaking the source numbering.
func milestoneName(p ir.Phase, index int) string {
	name := strings.TrimSpace(leadingNumberRe.ReplaceAllString(p.Name, ""))
	if name == "" {
		return "Stage " + ordinalWord(index)
	}
	return capitalize(name)
}

// ordinalWord spells small ordinals so a fallback stage name reads as prose
// rather than as an index.
func ordinalWord(index int) string {
	words := []string{"one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"}
	if index >= 0 && index < len(words) {
		return words[index]
	}
	return "later"
}

// ticketKind maps the IR discipline classification to a tracker label segment.
// A plain task carries no kind.
func ticketKind(k ir.TaskKind) string {
	if k == "" || k == ir.KindPlain {
		return ""
	}
	return string(k)
}

// labelsFor derives tracker labels from the milestone, the discipline keyword,
// and any bracket tags the author wrote.
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

// labelSegment normalizes a name into a lowercase, hyphenated label segment.
func labelSegment(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	s = labelCleanRe.ReplaceAllString(s, "-")
	return strings.Trim(s, "-")
}

// TicketTitle turns raw task text into an outcome sentence: the discipline
// keyword and any trailing period are removed, and a lowercase opening word is
// capitalized. Text opening with code or an identifier is left alone.
func TicketTitle(text string) string {
	t := strings.TrimSpace(text)
	t = kindPrefixRe.ReplaceAllString(t, "")
	t = strings.TrimSpace(t)
	t = strings.TrimSuffix(t, ".")
	return capitalize(t)
}

// capitalize uppercases a leading lowercase letter and leaves anything else
// (backticks, digits, already-capitalized words) untouched.
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

// Humanize turns a slug into a reader-facing name: separators become spaces and
// the first word is capitalized. "add-auth-layer" becomes "Add auth layer".
func Humanize(slug string) string {
	s := strings.TrimSpace(slugSepRe.ReplaceAllString(slug, " "))
	return capitalize(s)
}

// bulletLines extracts the bullet text from a markdown block, falling back to
// the block's non-empty lines when it contains no bullets.
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

// buildCriteria translates every scenario in every spec into an acceptance
// criterion. Order follows the source document so output stays deterministic.
func buildCriteria(specs []*ir.Spec) []Criterion {
	out := []Criterion{}
	for _, s := range specs {
		if s == nil {
			continue
		}
		for _, r := range s.Requirements {
			// A removed or renamed requirement carries migration prose, not
			// behavior, so it has nothing to verify.
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

// buildCriterion translates one scenario. A continuation keyword (and, but)
// appends to the bucket the previous step opened.
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

// negativeNameRe matches scenario names that describe a rejection or failure
// path. It is the fallback for a repository that declares no polarity marker.
var negativeNameRe = regexp.MustCompile(`(?i)\b(invalid|missing|expired|malformed|unauthori[sz]ed|forbidden|reject|refus|denied|fail|error|absent|unknown|conflict|duplicate|not found|empty|bad|timeout|corrupt)`)

// isNegative reports whether a scenario describes a failure path. A declared
// polarity marker is authoritative; without one the scenario name is the only
// signal available, so it is read as a hint rather than treated as a fact.
func isNegative(sc ir.Scenario) bool {
	if p, ok := sc.Markers["polarity"]; ok {
		return strings.EqualFold(strings.TrimSpace(p), "negative")
	}
	return negativeNameRe.MatchString(sc.Name)
}

// splitStep separates a step's leading Gherkin keyword from its body. A step
// with no keyword returns an empty keyword and the whole step.
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

// Tickets flattens every milestone's tickets in position order.
func (c Change) Tickets() []Ticket {
	var out []Ticket
	for _, m := range c.Milestones {
		out = append(out, m.Tickets...)
	}
	return out
}

// CriteriaByRequirement groups criteria under their requirement, preserving
// source order, so a renderer can emit one heading per requirement.
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

// RequirementGroup is the criteria belonging to one requirement.
type RequirementGroup struct {
	Capability  string
	Requirement string
	Criteria    []Criterion
}

// Negatives counts the criteria in the group that describe a failure path.
func (g RequirementGroup) Negatives() int {
	n := 0
	for _, c := range g.Criteria {
		if c.Negative {
			n++
		}
	}
	return n
}

// SuccessOnly reports that the group specifies no failure path. A reviewer
// reads it as an open question: what happens when this goes wrong?
func (g RequirementGroup) SuccessOnly() bool {
	return len(g.Criteria) > 0 && g.Negatives() == 0
}
