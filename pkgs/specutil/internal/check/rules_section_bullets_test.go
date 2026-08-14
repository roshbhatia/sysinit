package check

import (
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func proposalChange(raw string) *ir.Change {
	return &ir.Change{
		Name:     "c",
		Proposal: &ir.Proposal{Section: ir.Section{Raw: raw}},
	}
}

func behaviorRubric() Config {
	return Config{Rules: []RuleConfig{{
		ID: "section-min-bullets",
		Params: map[string]any{
			"artifact": "proposal",
			"section":  "## Behavior",
			"min":      1,
		},
	}}}
}

func TestSectionMinBulletsFlagsAnEmptySection(t *testing.T) {
	rep, err := Run(behaviorRubric(), []*ir.Change{proposalChange(
		"## Why\n\n- a reason\n\n## Behavior\n\n## Impact\n\n- a file\n")})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("a Behavior heading with no bullets under it states no criteria and must be flagged")
	}
	if !strings.Contains(rep.Findings[0].Msg, "## Behavior") {
		t.Errorf("the finding should name the section: %s", rep.Findings[0].Msg)
	}
}

func TestSectionMinBulletsCountsNestedBulletsAndSubsections(t *testing.T) {
	rep, err := Run(behaviorRubric(), []*ir.Change{proposalChange(
		"## Behavior\n\nMust do:\n\n### Group\n\n- outer\n  - inner\n\n## Impact\n")})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Fatalf("bullets under an h3 inside the section should count: %v", rep.Findings)
	}
}

func TestSectionMinBulletsIgnoresBulletsOutsideTheSection(t *testing.T) {
	rep, err := Run(behaviorRubric(), []*ir.Change{proposalChange(
		"## Behavior\n\n## Impact\n\n- a file\n")})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("a bullet after the next h2 belongs to that section, not this one")
	}
}

func TestSectionMinBulletsStaysSilentWhenTheSectionIsAbsent(t *testing.T) {
	rep, err := Run(behaviorRubric(), []*ir.Change{proposalChange("## Why\n\n- a reason\n")})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Fatalf("an absent section is required-sections' finding to report: %v", rep.Findings)
	}
}
