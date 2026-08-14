package export

import (
	"reflect"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func TestHumanize(t *testing.T) {
	cases := map[string]string{
		"add-auth-layer": "Add auth layer",
		"token_issuance": "Token issuance",
		"":               "",
		"API-gateway":    "API gateway",
	}
	for in, want := range cases {
		if got := Humanize(in); got != want {
			t.Errorf("Humanize(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestTicketTitleDropsDisciplineKeyword(t *testing.T) {
	cases := map[string]string{
		"verify: build succeeds":         "Build succeeds",
		"apply: deploy to production.":   "Deploy to production",
		"confirm CI is green":            "CI is green",
		"add the endpoint":               "Add the endpoint",
		"`go test ./...` passes":         "`go test ./...` passes",
		"Verify: staging suite is green": "Staging suite is green",
	}
	for in, want := range cases {
		if got := TicketTitle(in); got != want {
			t.Errorf("TicketTitle(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestBuildChangeCarriesNoSourceNumbering(t *testing.T) {
	c := &ir.Change{
		Name: "add-auth-layer",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "Foundation", Items: []ir.TaskItem{
				{ID: "1.1", Text: "add the module"},
				{ID: "1.2", Text: "verify: tests pass", Kind: ir.KindVerify},
			}},
			{Number: "2", Name: "Rollout", Items: []ir.TaskItem{
				{ID: "2.1", Text: "ship it"},
			}},
		}},
	}
	got := BuildChange(c)

	if got.Title != "Add auth layer" {
		t.Errorf("Title = %q", got.Title)
	}
	if len(got.Milestones) != 2 {
		t.Fatalf("expected 2 milestones, got %d", len(got.Milestones))
	}
	if got.Milestones[0].Name != "Foundation" || got.Milestones[1].Name != "Rollout" {
		t.Errorf("milestone names = %q, %q", got.Milestones[0].Name, got.Milestones[1].Name)
	}

	tickets := got.Tickets()
	if len(tickets) != 3 {
		t.Fatalf("expected 3 tickets, got %d", len(tickets))
	}
	for i, want := range []int{1, 2, 3} {
		if tickets[i].Position != want {
			t.Errorf("ticket %d position = %d, want %d", i, tickets[i].Position, want)
		}
	}
	for _, tk := range tickets {
		if strings.ContainsAny(tk.Title, "0123456789") {
			t.Errorf("ticket title carries a digit from the source numbering: %q", tk.Title)
		}
	}
	if want := []string{"stage:foundation", "kind:verify"}; !reflect.DeepEqual(tickets[1].Labels, want) {
		t.Errorf("labels = %v, want %v", tickets[1].Labels, want)
	}
}

func TestUnnamedPhaseGetsSpelledStageName(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "", Items: []ir.TaskItem{{Text: "do it"}}},
		}},
	}
	got := BuildChange(c)
	if got.Milestones[0].Name != "Stage one" {
		t.Errorf("unnamed phase = %q, want %q", got.Milestones[0].Name, "Stage one")
	}
}

func TestCriteriaTranslateGherkinSteps(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Specs: []*ir.Spec{{
			Capability: "auth-service",
			Requirements: []ir.Requirement{{
				Name:  "token-issuance",
				Delta: ir.DeltaAdded,
				Scenarios: []ir.Scenario{{
					Name: "valid credentials",
					Steps: []string{
						"**GIVEN** a valid password",
						"**WHEN** the caller posts it",
						"**THEN** a token is returned",
						"**AND** the expiry is set",
						"the response is logged",
					},
				}},
			}},
		}},
	}
	criteria := BuildChange(c).Criteria
	if len(criteria) != 1 {
		t.Fatalf("expected 1 criterion, got %d", len(criteria))
	}
	cr := criteria[0]
	if cr.Capability != "Auth service" || cr.Requirement != "Token issuance" {
		t.Errorf("capability/requirement = %q / %q", cr.Capability, cr.Requirement)
	}
	if cr.Name != "Valid credentials" {
		t.Errorf("scenario name = %q", cr.Name)
	}
	if !reflect.DeepEqual(cr.Given, []string{"a valid password"}) {
		t.Errorf("Given = %v", cr.Given)
	}
	if !reflect.DeepEqual(cr.When, []string{"the caller posts it"}) {
		t.Errorf("When = %v", cr.When)
	}

	if !reflect.DeepEqual(cr.Then, []string{"a token is returned", "the expiry is set"}) {
		t.Errorf("Then = %v", cr.Then)
	}

	if !reflect.DeepEqual(cr.Steps, []string{"the response is logged"}) {
		t.Errorf("Steps = %v", cr.Steps)
	}
}

func TestRemovedRequirementsProduceNoCriteria(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Specs: []*ir.Spec{{
			Capability: "auth-service",
			Requirements: []ir.Requirement{
				{Name: "gone", Delta: ir.DeltaRemoved, Scenarios: []ir.Scenario{{Name: "x", Steps: []string{"When y"}}}},
				{Name: "renamed", Delta: ir.DeltaRenamed, Scenarios: []ir.Scenario{{Name: "z", Steps: []string{"When w"}}}},
			},
		}},
	}
	if got := BuildChange(c).Criteria; len(got) != 0 {
		t.Errorf("removed and renamed requirements describe no behavior, got %v", got)
	}
}

func TestCriteriaByRequirementPreservesSourceOrder(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Specs: []*ir.Spec{{
			Capability: "cap",
			Requirements: []ir.Requirement{
				{Name: "second-thing", Delta: ir.DeltaAdded, Scenarios: []ir.Scenario{{Name: "a"}, {Name: "b"}}},
				{Name: "first-thing", Delta: ir.DeltaAdded, Scenarios: []ir.Scenario{{Name: "c"}}},
			},
		}},
	}
	groups := BuildChange(c).CriteriaByRequirement()
	if len(groups) != 2 {
		t.Fatalf("expected 2 groups, got %d", len(groups))
	}
	if groups[0].Requirement != "Second thing" || len(groups[0].Criteria) != 2 {
		t.Errorf("group 0 = %+v", groups[0])
	}
	if groups[1].Requirement != "First thing" {
		t.Errorf("group 1 = %+v", groups[1])
	}
}

func TestBuildChangeNilIsZero(t *testing.T) {
	if got := BuildChange(nil); got.Name != "" || got.Milestones != nil {
		t.Errorf("nil change should yield the zero value, got %+v", got)
	}
}
