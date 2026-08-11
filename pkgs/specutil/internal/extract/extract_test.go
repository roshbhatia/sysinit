package extract

import (
	"reflect"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func roshConfig(t *testing.T) Config {
	t.Helper()
	cfg, err := Resolve(Config{Preset: "spec-driven"})
	if err != nil {
		t.Fatalf("Resolve: %v", err)
	}
	return cfg
}

func TestResolveRejectsUnknownPreset(t *testing.T) {
	_, err := Resolve(Config{Preset: "nope"})
	if err == nil {
		t.Fatal("expected an error naming the available presets")
	}
	if !strings.Contains(err.Error(), "spec-driven") {
		t.Errorf("error should list available presets, got %q", err)
	}
}

func TestResolveRejectsBadDeclarations(t *testing.T) {
	cases := map[string]Config{
		"marker without bullet": {Markers: []Marker{{Key: "x", Scope: ScopePhase}}},
		"marker bad scope":      {Markers: []Marker{{Key: "x", Scope: "nope", Bullet: "X"}}},
		"field without label":   {Fields: []Field{{Key: "x"}}},
		"field bad type":        {Fields: []Field{{Key: "x", Label: "x", Type: "nope"}}},
		"field bad scope":       {Fields: []Field{{Key: "x", Label: "x", Scope: ScopePhase}}},
	}
	for name, cfg := range cases {
		if _, err := Resolve(cfg); err == nil {
			t.Errorf("%s: expected an error", name)
		}
	}
}

func TestResolveLetsLocalDeclarationOverridePreset(t *testing.T) {
	cfg, err := Resolve(Config{
		Preset:  "spec-driven",
		Markers: []Marker{{Key: "polarity", Scope: ScopeScenario, Bullet: "KIND"}},
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, m := range cfg.Markers {
		if m.Key == "polarity" && m.Scope == ScopeScenario {
			if m.Bullet != "KIND" {
				t.Errorf("local declaration should win, got bullet %q", m.Bullet)
			}
			return
		}
	}
	t.Fatal("polarity marker missing after resolve")
}

func TestApplyIsNoOpForEmptyConfig(t *testing.T) {
	c := &ir.Change{
		Name:  "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{Number: "1", Name: "Build", Notes: []string{"**SHAPE** graph"}}}},
	}
	if w := Apply(Config{}, c); w != nil {
		t.Errorf("empty config must extract nothing, got %v", w)
	}
	if c.Tasks.Phases[0].Markers != nil {
		t.Error("empty config must not populate markers")
	}
}

func TestApplyLiftsPhaseMarkers(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "2", Name: "Harden",
			Notes: []string{
				"**SHAPE** loop",
				"**STOP** all fixtures pass",
				"**MAX-ITERS** 3",
				"a plain note that is not a marker",
			},
			Items: []ir.TaskItem{{ID: "2.1", Text: "do it"}},
		}}},
	}
	Apply(roshConfig(t), c)

	p := c.Tasks.Phases[0]
	want := map[string]string{"shape": "loop", "stop": "all fixtures pass", "maxIters": "3"}
	if !reflect.DeepEqual(p.Markers, want) {
		t.Errorf("markers = %v, want %v", p.Markers, want)
	}
	// A bullet nobody declared belongs to the prose and must survive.
	if !reflect.DeepEqual(p.Notes, []string{"a plain note that is not a marker"}) {
		t.Errorf("undeclared notes should be retained, got %v", p.Notes)
	}
}

func TestApplyLiftsScenarioPolarity(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Specs: []*ir.Spec{{
			Capability: "thing",
			Requirements: []ir.Requirement{{
				Name:  "works",
				Delta: ir.DeltaAdded,
				Scenarios: []ir.Scenario{{
					Name: "bad input",
					Steps: []string{
						"**POLARITY** negative",
						"**WHEN** the input is malformed",
						"**THEN** it is rejected",
					},
				}},
			}},
		}},
	}
	Apply(roshConfig(t), c)

	sc := c.Specs[0].Requirements[0].Scenarios[0]
	if sc.Markers["polarity"] != "negative" {
		t.Errorf("polarity = %q, want negative", sc.Markers["polarity"])
	}
	// The marker must not remain as a step, or it reaches a tracker as prose.
	want := []string{"**WHEN** the input is malformed", "**THEN** it is rejected"}
	if !reflect.DeepEqual(sc.Steps, want) {
		t.Errorf("steps = %v, want %v", sc.Steps, want)
	}
}

func TestApplyLiftsTaskDependencies(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "Create the module `deps:` none"},
				{ID: "1.2", Text: "Wire it up `deps:` 1.1"},
				{ID: "1.3", Text: "Document it `deps:` 1.1, 1.2"},
			},
		}}},
	}
	if w := Apply(roshConfig(t), c); len(w) != 0 {
		t.Fatalf("unexpected warnings: %v", w)
	}

	items := c.Tasks.Phases[0].Items
	for i, wantText := range []string{"Create the module", "Wire it up", "Document it"} {
		if items[i].Text != wantText {
			t.Errorf("item %d text = %q, want %q", i, items[i].Text, wantText)
		}
	}
	if items[0].DependsOn != nil {
		t.Errorf("`none` declares no dependency, got %v", items[0].DependsOn)
	}
	if !reflect.DeepEqual(items[1].DependsOn, []string{"1.1"}) {
		t.Errorf("1.2 deps = %v", items[1].DependsOn)
	}
	if !reflect.DeepEqual(items[2].DependsOn, []string{"1.1", "1.2"}) {
		t.Errorf("1.3 deps = %v", items[2].DependsOn)
	}
	if !reflect.DeepEqual(items[0].Fields["deps"], []string(nil)) && len(items[0].Fields["deps"]) != 0 {
		t.Errorf("`none` should record an empty value, got %v", items[0].Fields["deps"])
	}
}

func TestApplyKeepsProseAfterAFieldValue(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "Set up"},
				{ID: "1.2", Text: "Wire it `deps:` 1.1 then run the suite"},
			},
		}}},
	}
	Apply(roshConfig(t), c)
	got := c.Tasks.Phases[0].Items[1]
	if got.Text != "Wire it then run the suite" {
		t.Errorf("text = %q, want the prose after the value retained", got.Text)
	}
	if !reflect.DeepEqual(got.DependsOn, []string{"1.1"}) {
		t.Errorf("deps = %v", got.DependsOn)
	}
}

func TestApplyWarnsOnDanglingAndSelfDependencies(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "Ghost dep `deps:` 9.9"},
				{ID: "1.2", Text: "Self dep `deps:` 1.2"},
			},
		}}},
	}
	warns := Apply(roshConfig(t), c)
	if len(warns) != 2 {
		t.Fatalf("expected 2 warnings, got %d: %v", len(warns), warns)
	}
	if !strings.Contains(warns[0].Msg, "9.9") {
		t.Errorf("first warning should name the dangling ref: %q", warns[0].Msg)
	}
	if !strings.Contains(warns[1].Msg, "itself") {
		t.Errorf("second warning should name the self dependency: %q", warns[1].Msg)
	}
	for _, it := range c.Tasks.Phases[0].Items {
		if len(it.DependsOn) != 0 {
			t.Errorf("an unresolvable reference must not become an edge, got %v", it.DependsOn)
		}
	}
}

func TestApplyIsIdempotent(t *testing.T) {
	build := func() *ir.Change {
		return &ir.Change{
			Name: "demo",
			Tasks: &ir.Tasks{Phases: []ir.Phase{{
				Number: "1", Name: "Build",
				Notes: []string{"**SHAPE** graph"},
				Items: []ir.TaskItem{
					{ID: "1.1", Text: "Set up `deps:` none"},
					{ID: "1.2", Text: "Wire it `deps:` 1.1"},
				},
			}}},
		}
	}
	cfg := roshConfig(t)
	once, twice := build(), build()
	Apply(cfg, once)
	Apply(cfg, twice)
	Apply(cfg, twice)
	if !reflect.DeepEqual(once.Tasks, twice.Tasks) {
		t.Errorf("second pass changed the IR:\n%+v\n%+v", once.Tasks, twice.Tasks)
	}
}

func TestApplyIgnoresUndeclaredMarkers(t *testing.T) {
	cfg, err := Resolve(Config{Markers: []Marker{{Key: "shape", Scope: ScopePhase, Bullet: "SHAPE"}}})
	if err != nil {
		t.Fatal(err)
	}
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Notes: []string{"**SHAPE** loop", "**STOP** never"},
			Items: []ir.TaskItem{{ID: "1.1", Text: "x"}},
		}}},
	}
	Apply(cfg, c)
	p := c.Tasks.Phases[0]
	if p.Markers["shape"] != "loop" {
		t.Errorf("declared marker not lifted: %v", p.Markers)
	}
	if !reflect.DeepEqual(p.Notes, []string{"**STOP** never"}) {
		t.Errorf("undeclared marker must stay in the prose, got %v", p.Notes)
	}
}
