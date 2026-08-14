package check

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/review"
)

func good() *ir.Change {
	return &ir.Change{
		Name: "demo",
		Proposal: &ir.Proposal{
			Section: ir.Section{Raw: "## Why\n\nA reason.\n\n## What Changes\n\n- Do the thing\n\n### Non-goals\n\n- Not this\n\n## Behavior\n\nMust do:\n\n- The thing happens, decided by `run it`\n"},
		},
		Design: &ir.Design{
			Section: ir.Section{Raw: "## Decisions\n\n- Decision: use X\n  - Alternative rejected: Y\n\n## Rollout & Gating\n\nBuild, then switch.\n\n## Adversarial Review\n\nPer the skill.\n"},
		},
		Specs: []*ir.Spec{{
			Section:    ir.Section{Raw: "## ADDED Requirements\n\n### Requirement: It works\n"},
			Capability: "cap",
			Requirements: []ir.Requirement{{
				Name:  "It works",
				Delta: ir.DeltaAdded,
				Scenarios: []ir.Scenario{
					{Name: "happy", Markers: map[string]string{"polarity": "positive"}},
					{Name: "sad", Markers: map[string]string{"polarity": "negative"}},
				},
			}},
		}},
		Tasks: &ir.Tasks{
			Section: ir.Section{Raw: "## 1. Build\n\n- [ ] 1.1 Do it\n- [ ] 1.2 Adversarial review\n"},
			Phases: []ir.Phase{
				{
					Number: "1", Name: "Build",
					Markers: map[string]string{"shape": "graph"},
					Items: []ir.TaskItem{
						{ID: "1.1", Text: "Do it"},

						{ID: "1.2", Text: "Adversarial review (skill)", DependsOn: []string{"1.1"}},
					},
				},
				{
					Number: "2", Name: "Rollout",
					Items: []ir.TaskItem{{ID: "2.1", Text: "Apply: switch"}},
				},
			},
		},
	}
}

func roshRun(t *testing.T, c *ir.Change) *Report {
	t.Helper()
	approve(t, c)
	rep, err := Run(Config{Preset: "spec-driven"}, []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	return rep
}

func approve(t *testing.T, c *ir.Change) {
	t.Helper()
	repo := t.TempDir()
	c.Root = filepath.Join(repo, "openspec", "changes", c.Name)
	if err := os.MkdirAll(c.Root, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", c.Root, err)
	}
	rec := review.Apply(c, &review.Feedback{
		Schema: review.Schema, Change: c.Name, Decision: review.DecisionApproved,
	})
	if err := rec.Save(repo, c.Name); err != nil {
		t.Fatalf("writing the review record: %v", err)
	}
}

func firedRules(r *Report) map[string]bool {
	out := map[string]bool{}
	for _, f := range r.Findings {
		out[f.Rule] = true
	}
	return out
}

func TestPresetPassesAWellFormedChange(t *testing.T) {
	rep := roshRun(t, good())
	if !rep.OK() {
		t.Fatalf("expected a clean pass, got: %+v", rep.Findings)
	}
}

func TestMissingNonGoalsFails(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "### Non-goals\n\n- Not this\n", "", 1)
	if !firedRules(roshRun(t, c))["proposal-sections"] {
		t.Error("expected proposal-sections to fire")
	}
}

func TestMissingDesignSectionFails(t *testing.T) {
	c := good()
	c.Design.Raw = strings.Replace(c.Design.Raw, "## Adversarial Review", "## Something Else", 1)
	if !firedRules(roshRun(t, c))["design-sections"] {
		t.Error("expected design-sections to fire")
	}
}

func TestDecisionWithoutRejectedAlternativeFails(t *testing.T) {
	c := good()
	c.Design.Raw = strings.Replace(c.Design.Raw, "  - Alternative rejected: Y\n", "", 1)
	if !firedRules(roshRun(t, c))["paired-bullet"] {
		t.Error("expected paired-bullet to fire")
	}
}

func TestPairedBulletCountsPerBlockNotInAggregate(t *testing.T) {
	c := good()
	c.Design.Raw = "## Decisions\n\n" +
		"- Decision: A\n  - Alternative rejected: a1\n  - Alternative rejected: a2\n" +
		"- Decision: B\n" +
		"\n## Rollout & Gating\n\nx\n\n## Adversarial Review\n\ny\n"
	if !firedRules(roshRun(t, c))["paired-bullet"] {
		t.Error("a bare second decision must fail even when the first has two alternatives")
	}
}

func scenarioRun(t *testing.T, c *ir.Change) *Report {
	t.Helper()
	rep, err := Run(Config{Rules: []RuleConfig{{
		ID:     "scenario-marker-coverage",
		Params: map[string]any{"marker": "polarity", "value": "negative"},
	}}}, []*ir.Change{c})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	return rep
}

func TestRequirementWithoutNegativeScenarioFails(t *testing.T) {
	c := good()
	c.Specs[0].Requirements[0].Scenarios[1].Markers = map[string]string{"polarity": "positive"}
	if !firedRules(scenarioRun(t, c))["scenario-marker-coverage"] {
		t.Error("expected scenario-marker-coverage to fire")
	}
}

func TestRemovedRequirementNeedsNoNegativeScenario(t *testing.T) {
	c := good()
	c.Specs[0].Requirements = append(c.Specs[0].Requirements, ir.Requirement{
		Name: "Gone", Delta: ir.DeltaRemoved,
	})
	if !scenarioRun(t, c).OK() {
		t.Error("a removed requirement carries migration prose, not behavior, so it needs no scenario")
	}
}

func TestPhaseWithoutShapeFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Markers = nil
	if !firedRules(roshRun(t, c))["phase-marker-required"] {
		t.Error("expected phase-marker-required to fire")
	}
}

func TestPhaseWithDisallowedShapeFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Markers = map[string]string{"shape": "linear"}
	rep := roshRun(t, c)
	if !firedRules(rep)["phase-marker-required"] {
		t.Fatal("a shape the framework does not define must not pass as declared")
	}
	var joined string
	for _, f := range rep.Findings {
		joined += f.Msg
	}
	for _, want := range []string{"linear", "loop", "graph"} {
		if !strings.Contains(joined, want) {
			t.Errorf("the finding should name %q, got: %s", want, joined)
		}
	}
}

func TestPhaseShapeIsCaseInsensitive(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Markers = map[string]string{"shape": "GRAPH"}
	if firedRules(roshRun(t, c))["phase-marker-required"] {
		t.Error("a marker value should match its allowed value regardless of case")
	}
}

func TestTaskWithoutIdentifierFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items[0].ID = ""
	if !firedRules(roshRun(t, c))["task-id-required"] {
		t.Error("a task with no N.M identifier drops out of the graph and must fail")
	}
}

func TestRolloutPhaseIsExemptFromShape(t *testing.T) {
	if !roshRun(t, good()).OK() {
		t.Error("a rollout phase must not be required to declare a shape")
	}
}

func TestLoopPhaseWithoutStopAndCapFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Markers = map[string]string{"shape": "loop"}
	rep := roshRun(t, c)
	if !firedRules(rep)["phase-marker-conditional"] {
		t.Fatal("expected phase-marker-conditional to fire")
	}
	var msgs []string
	for _, f := range rep.Findings {
		msgs = append(msgs, f.Msg)
	}
	joined := strings.Join(msgs, "\n")
	for _, want := range []string{"stop", "maxIters"} {
		if !strings.Contains(joined, want) {
			t.Errorf("expected a finding naming %q, got:\n%s", want, joined)
		}
	}
}

func TestLoopStopMustNameACommand(t *testing.T) {
	prose := good()
	prose.Tasks.Phases[0].Markers = map[string]string{
		"shape": "loop", "stop": "the settings are coherent", "maxIters": "3",
	}
	if !firedRules(roshRun(t, prose))["stop-is-a-command"] {
		t.Error("a STOP nothing can evaluate must be reported")
	}

	cmd := good()
	cmd.Tasks.Phases[0].Markers = map[string]string{
		"shape": "loop", "stop": "`nix flake check` exits 0", "maxIters": "3",
	}
	if firedRules(roshRun(t, cmd))["stop-is-a-command"] {
		t.Error("a STOP naming a command in backticks must pass")
	}
}

func TestGraphPhaseIsExemptFromStopPattern(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Markers = map[string]string{"shape": "graph", "stop": "prose"}
	if firedRules(roshRun(t, c))["stop-is-a-command"] {
		t.Error("stop-is-a-command must only apply to loop phases")
	}
}

func TestPhaseWithoutAdversarialReviewTaskFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items = c.Tasks.Phases[0].Items[:1]
	if !firedRules(roshRun(t, c))["phase-task-pattern"] {
		t.Error("expected phase-task-pattern to fire")
	}
}

func TestPhaseTitleDoesNotSatisfyTaskPattern(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Name = "Adversarial review"
	c.Tasks.Phases[0].Items = []ir.TaskItem{{ID: "1.1", Text: "Do it"}}
	if !firedRules(roshRun(t, c))["phase-task-pattern"] {
		t.Error("a phase heading must not self-satisfy the review gate")
	}
}

func TestDanglingTaskDependencyFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items[0].Fields = map[string][]string{"deps": {"9.9"}}
	if !firedRules(roshRun(t, c))["task-deps-resolve"] {
		t.Error("expected task-deps-resolve to fire")
	}
}

func TestCyclicTaskDependenciesFail(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items[0].Fields = map[string][]string{"deps": {"1.2"}}
	c.Tasks.Phases[0].Items[1].Fields = map[string][]string{"deps": {"1.1"}}
	rep := roshRun(t, c)
	if !firedRules(rep)["task-deps-acyclic"] {
		t.Fatal("expected task-deps-acyclic to fire")
	}
	var joined string
	for _, f := range rep.Findings {
		joined += f.Msg + "\n"
	}
	for _, want := range []string{"1.1", "1.2", "->"} {
		if !strings.Contains(joined, want) {
			t.Errorf("expected the cycle path to name %q, got:\n%s", want, joined)
		}
	}
}

func TestSelfTaskDependencyFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items[0].Fields = map[string][]string{"deps": {"1.1"}}
	if !firedRules(roshRun(t, c))["task-deps-acyclic"] {
		t.Error("a task depending on itself is a cycle")
	}
}

func TestDanglingDependencyDoesNotFireAcyclic(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items[0].Fields = map[string][]string{"deps": {"9.9"}}
	if firedRules(roshRun(t, c))["task-deps-acyclic"] {
		t.Error("task-deps-acyclic must not fire on an unresolved dependency")
	}
}

func TestDiamondTaskDependenciesPass(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items = []ir.TaskItem{
		{ID: "1.1", Text: "Root"},
		{ID: "1.2", Text: "Left", Fields: map[string][]string{"deps": {"1.1"}}},
		{ID: "1.3", Text: "Right", Fields: map[string][]string{"deps": {"1.1"}}},
		{ID: "1.4", Text: "Adversarial review (skill)", Fields: map[string][]string{"deps": {"1.2", "1.3"}}},
	}
	if firedRules(roshRun(t, c))["task-deps-acyclic"] {
		t.Error("a diamond dependency graph is acyclic and must pass")
	}
}

func TestEmDashFails(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "A reason.", "A reason — long.", 1)
	rep := roshRun(t, c)
	if !firedRules(rep)["no-em-dash"] {
		t.Fatal("expected no-em-dash to fire")
	}
	for _, f := range rep.Findings {
		if f.Rule == "no-em-dash" && f.Line == 0 {
			t.Error("an em-dash finding should carry the line it was found on")
		}
	}
}

func TestEmDashInCodePasses(t *testing.T) {
	cases := map[string]string{
		"inline span":  "A reason. Captured: `finished its turn — sysinit`.",
		"fenced block": "A reason.\n\n```\nfinished its turn — sysinit\n```\n",
	}
	for name, replacement := range cases {
		t.Run(name, func(t *testing.T) {
			c := good()
			c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "A reason.", replacement, 1)
			if firedRules(roshRun(t, c))["no-em-dash"] {
				t.Error("an em-dash inside code is captured evidence, not prose")
			}
		})
	}
}

func TestBoldedBulletLeadFails(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "- Do the thing", "- **Thing** does it", 1)
	if !firedRules(roshRun(t, c))["bolded-bullet-lead"] {
		t.Error("expected bolded-bullet-lead to fire")
	}
}

func TestAllowedBoldedBulletLeadsPass(t *testing.T) {
	c := good()
	c.Specs[0].Raw = "### Requirement: x\n\n#### Scenario: y\n" +
		"- **POLARITY** negative\n- **WHEN** a thing\n- **THEN** another\n"
	c.Tasks.Raw = "## 1. Build\n\n- **SHAPE** loop\n- **STOP** green\n- **MAX-ITERS** 3\n"
	if !roshRun(t, c).OK() {
		t.Errorf("the format keywords must be allowed as bolded leads: %+v", roshRun(t, c).Findings)
	}
}

func TestResolveRejectsUnknownPresetRuleAndSeverity(t *testing.T) {
	cases := map[string]Config{
		"unknown preset":   {Preset: "nope"},
		"unknown rule":     {Rules: []RuleConfig{{ID: "nope"}}},
		"missing id":       {Rules: []RuleConfig{{Severity: SeverityWarn}}},
		"unknown severity": {Rules: []RuleConfig{{ID: "no-em-dash", Severity: "loud"}}},
		"disable unknown":  {Preset: "spec-driven", Disable: []string{"nope"}},
	}
	for name, cfg := range cases {
		if _, err := Resolve(cfg); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
}

func TestDisableRemovesARule(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "A reason.", "A reason — long.", 1)
	approve(t, c)
	rep, err := Run(Config{Preset: "spec-driven", Disable: []string{"no-em-dash"}}, []*ir.Change{c})
	if err != nil {
		t.Fatal(err)
	}
	if !rep.OK() {
		t.Errorf("disabling no-em-dash should clear the only violation, got %+v", rep.Findings)
	}
}

func TestSeverityOverrideDowngradesToWarning(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "A reason.", "A reason — long.", 1)
	approve(t, c)
	rep, err := Run(Config{
		Preset: "spec-driven",
		Rules:  []RuleConfig{{ID: "no-em-dash", Severity: SeverityWarn}},
	}, []*ir.Change{c})
	if err != nil {
		t.Fatal(err)
	}
	if !rep.OK() {
		t.Error("a warning must not fail the run")
	}
	if rep.Warnings() != 1 {
		t.Errorf("expected 1 warning, got %d", rep.Warnings())
	}
}

func TestLocalRuleOverridesPresetByName(t *testing.T) {
	c := good()
	c.Proposal.Raw = strings.Replace(c.Proposal.Raw, "- Do the thing", "- **Thing** does it", 1)
	approve(t, c)
	rep, err := Run(Config{
		Preset: "spec-driven",
		Rules: []RuleConfig{{
			ID:     "bolded-bullet-lead",
			Params: map[string]any{"allow": []string{"Thing", "WHEN", "THEN", "POLARITY", "SHAPE", "STOP", "MAX-ITERS"}},
		}},
	}, []*ir.Change{c})
	if err != nil {
		t.Fatal(err)
	}
	if !rep.OK() {
		t.Errorf("a local allow list should replace the preset's, got %+v", rep.Findings)
	}
}

func TestEmptyConfigChecksNothing(t *testing.T) {
	var zero Config
	if !zero.IsZero() {
		t.Error("the zero config must report itself as empty")
	}
	rep, err := Run(Config{}, []*ir.Change{good()})
	if err != nil {
		t.Fatal(err)
	}
	if len(rep.Findings) != 0 {
		t.Errorf("no rubric means no findings, got %+v", rep.Findings)
	}
}

func TestReportOrderIsStable(t *testing.T) {
	c := good()
	c.Proposal.Raw = "- **A** x\n- **B** y\n"
	c.Design.Raw = ""
	first, err := Run(Config{Preset: "spec-driven"}, []*ir.Change{c})
	if err != nil {
		t.Fatal(err)
	}
	for i := 0; i < 5; i++ {
		again, _ := Run(Config{Preset: "spec-driven"}, []*ir.Change{c})
		if len(again.Findings) != len(first.Findings) {
			t.Fatalf("finding count unstable: %d vs %d", len(again.Findings), len(first.Findings))
		}
		for j := range first.Findings {
			if again.Findings[j] != first.Findings[j] {
				t.Fatalf("finding %d unstable:\n%+v\n%+v", j, again.Findings[j], first.Findings[j])
			}
		}
	}
}

func TestAbsentOptionalArtifactIsNotAViolation(t *testing.T) {
	c := good()
	c.Design = nil
	rep := roshRun(t, c)
	if fired := firedRules(rep); fired["design-sections"] || fired["paired-bullet"] {
		t.Errorf("absent design.md should not fire design rules, got %+v", rep.Findings)
	}
}

func TestChangeWithNoArtifactsFails(t *testing.T) {
	rep, err := Run(Config{Preset: "spec-driven"}, []*ir.Change{{Name: "empty"}})
	if err != nil {
		t.Fatal(err)
	}
	if rep.OK() {
		t.Fatal("an artifact-less change must not pass the rubric")
	}
	if got := rep.Findings[0].Rule; got != "change-has-artifacts" {
		t.Errorf("rule = %q, want change-has-artifacts", got)
	}
}

func TestChangeWithOnlyOneArtifactIsChecked(t *testing.T) {
	c := &ir.Change{Name: "minimal", Proposal: &ir.Proposal{
		Section: ir.Section{Raw: "## Why\n\nA reason.\n"},
	}}
	rep, err := Run(Config{Preset: "spec-driven"}, []*ir.Change{c})
	if err != nil {
		t.Fatal(err)
	}
	for _, f := range rep.Findings {
		if f.Rule == "change-has-artifacts" {
			t.Error("a change with a proposal must be checked, not rejected as empty")
		}
	}

	if rep.OK() {
		t.Error("expected the proposal-sections rule to fire")
	}
}

func TestGraphPhaseWithoutEdgesWarns(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items = []ir.TaskItem{
		{ID: "1.1", Text: "Do it"},
		{ID: "1.2", Text: "Adversarial review (skill)"},
	}
	if !firedRules(roshRun(t, c))["phase-edges-declared"] {
		t.Error("a multi-subtask graph phase with no dependency must be reported")
	}
}

func TestSingleSubtaskGraphPhaseIsExempt(t *testing.T) {
	c := good()
	c.Tasks.Phases[0].Items = []ir.TaskItem{{ID: "1.1", Text: "Adversarial review (skill)"}}
	if firedRules(roshRun(t, c))["phase-edges-declared"] {
		t.Error("a one-subtask phase must not be asked to declare an order")
	}
}

func TestTaskNumberedForAnotherPhaseFails(t *testing.T) {
	c := good()
	c.Tasks.Phases[1].Items = []ir.TaskItem{{ID: "1.9", Text: "Apply: switch"}}
	if !firedRules(roshRun(t, c))["task-id-matches-phase"] {
		t.Error("a task carrying another phase's number must be reported")
	}
}
