package detail

import (
	"bytes"
	"reflect"
	"testing"
	"time"

	"github.com/roshbhatia/specutil/internal/ir"
	"github.com/roshbhatia/specutil/internal/lifecycle"
)

func mkChange(name string, done, total int) *ir.Change {
	items := make([]ir.TaskItem, total)
	for i := range items {
		items[i] = ir.TaskItem{Text: "task", Done: i < done}
	}
	return &ir.Change{
		Name:     name,
		Proposal: &ir.Proposal{Why: "because", WhatChanges: "stuff"},
		Tasks:    &ir.Tasks{Phases: []ir.Phase{{Number: "1", Name: "P", Items: items}}},
	}
}

func TestBuildIsDeterministic(t *testing.T) {
	// Input order is intentionally unsorted to prove output is stable regardless.
	changes := []*ir.Change{mkChange("gamma", 2, 2), mkChange("alpha", 0, 3), mkChange("beta", 1, 2)}

	a, err := Build(changes).JSON()
	if err != nil {
		t.Fatalf("JSON: %v", err)
	}
	b, err := Build(changes).JSON()
	if err != nil {
		t.Fatalf("JSON: %v", err)
	}
	if !bytes.Equal(a, b) {
		t.Fatalf("detail feed not byte-identical on repeat:\n%s\n---\n%s", a, b)
	}

	// And the entries are sorted by name regardless of input order.
	f := Build(changes)
	if f.Changes[0].Name != "alpha" || f.Changes[1].Name != "beta" || f.Changes[2].Name != "gamma" {
		t.Errorf("changes not sorted by name: %v", []string{f.Changes[0].Name, f.Changes[1].Name, f.Changes[2].Name})
	}
}

func TestLifecycleParityWithSharedClassifier(t *testing.T) {
	// The detail feed must report the same lifecycle/progress the shared
	// classifier produces — the guarantee both surfaces rely on.
	cases := []*ir.Change{mkChange("p", 0, 2), mkChange("a", 1, 2), mkChange("d", 3, 3)}
	feed := Build(cases)
	byName := map[string]Change{}
	for _, c := range feed.Changes {
		byName[c.Name] = c
	}
	for _, c := range cases {
		want := string(lifecycle.Classify(c))
		wd, wt := lifecycle.Progress(c)
		got := byName[c.Name]
		if got.Lifecycle != want {
			t.Errorf("%s: lifecycle = %q, want %q", c.Name, got.Lifecycle, want)
		}
		if got.Done != wd || got.Total != wt {
			t.Errorf("%s: progress = %d/%d, want %d/%d", c.Name, got.Done, got.Total, wd, wt)
		}
	}
}

func TestItemLevelKeyTracksPhaseAndSibling(t *testing.T) {
	// Two phases: phase 1 (level 0) has two parallel items, phase 2 (level 1) one.
	c := &ir.Change{
		Name: "x",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "first", Items: []ir.TaskItem{{Text: "a"}, {Text: "b"}}},
			{Number: "2", Name: "second", Items: []ir.TaskItem{{Text: "c"}}},
		}},
	}
	f := Build([]*ir.Change{c})
	ph := f.Changes[0].Phases
	if ph[0].Items[0].Level != 0 || ph[0].Items[0].Key != "0a" {
		t.Errorf("phase 1 item 1 = level %d key %q, want 0/0a", ph[0].Items[0].Level, ph[0].Items[0].Key)
	}
	if ph[0].Items[1].Level != 0 || ph[0].Items[1].Key != "0b" {
		t.Errorf("phase 1 item 2 = level %d key %q, want 0/0b", ph[0].Items[1].Level, ph[0].Items[1].Key)
	}
	if ph[1].Items[0].Level != 1 || ph[1].Items[0].Key != "1a" {
		t.Errorf("phase 2 item 1 = level %d key %q, want 1/1a", ph[1].Items[0].Level, ph[1].Items[0].Key)
	}
}

func TestBuildCarriesTaskContent(t *testing.T) {
	f := Build([]*ir.Change{mkChange("x", 1, 2)})
	c := f.Changes[0]
	if c.Why != "because" || c.WhatChanges != "stuff" {
		t.Errorf("proposal content not carried: %+v", c)
	}
	if len(c.Phases) != 1 || len(c.Phases[0].Items) != 2 {
		t.Fatalf("phases/items not carried: %+v", c.Phases)
	}
	if !c.Phases[0].Items[0].Done || c.Phases[0].Items[1].Done {
		t.Errorf("done state wrong: %+v", c.Phases[0].Items)
	}
}

func TestTaskLevelsFallBackToPhaseOrdinal(t *testing.T) {
	// No task declares a dependency, so every task's level is just its phase's
	// ordinal — the pre-existing behavior a repo with no extraction still gets.
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "A", Items: []ir.TaskItem{{Text: "a1"}, {Text: "a2"}}},
			{Number: "2", Name: "B", Items: []ir.TaskItem{{Text: "b1"}}},
		}},
	}
	f := Build([]*ir.Change{c})
	items := f.Changes[0].Phases
	for _, it := range items[0].Items {
		if it.Level != 0 {
			t.Errorf("phase 0 item level = %d, want 0", it.Level)
		}
	}
	if items[1].Items[0].Level != 1 {
		t.Errorf("phase 1 item level = %d, want 1", items[1].Items[0].Level)
	}
}

func TestTaskLevelsFollowDeclaredDependencies(t *testing.T) {
	// A single phase with a real DAG: 1.1 has no deps, 1.2 and 1.3 both wait on
	// 1.1 (so they share a level and can run in parallel), and 1.4 waits on both.
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "root"},
				{ID: "1.2", Text: "left", DependsOn: []string{"1.1"}},
				{ID: "1.3", Text: "right", DependsOn: []string{"1.1"}},
				{ID: "1.4", Text: "join", DependsOn: []string{"1.2", "1.3"}},
			},
		}}},
	}
	items := Build([]*ir.Change{c}).Changes[0].Phases[0].Items
	levels := map[string]int{}
	for _, it := range items {
		levels[it.ID] = it.Level
	}
	if levels["1.1"] != 0 {
		t.Errorf("1.1 level = %d, want 0", levels["1.1"])
	}
	if levels["1.2"] != 1 || levels["1.3"] != 1 {
		t.Errorf("1.2/1.3 levels = %d/%d, want 1/1 (parallel siblings)", levels["1.2"], levels["1.3"])
	}
	if levels["1.4"] != 2 {
		t.Errorf("1.4 level = %d, want 2 (waits on both parallel siblings)", levels["1.4"])
	}
}

func TestTaskLevelsCombineSequentialPhasesAndDeclaredDeps(t *testing.T) {
	// Phase 1 has an internal chain (1.2 waits on 1.1), so phase 1's deepest task sits at
	// level 1.
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "A", Items: []ir.TaskItem{
				{ID: "1.1", Text: "a1"},
				{ID: "1.2", Text: "a2", DependsOn: []string{"1.1"}},
			}},
			{Number: "2", Name: "B", Items: []ir.TaskItem{{ID: "2.1", Text: "b1", DependsOn: []string{"1.1"}}}},
		}},
	}
	phases := Build([]*ir.Change{c}).Changes[0].Phases
	if got := phases[1].Items[0].Level; got != 2 {
		t.Errorf("2.1 level = %d, want 2 (bounded by all of phase 1, deeper than its own declared dep)", got)
	}
}

func TestTaskLevelsIgnoreCycles(t *testing.T) {
	// A cycle must not hang the walk or produce an unbounded level; it simply
	// stops descending when it meets a node already being visited.
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "a", DependsOn: []string{"1.2"}},
				{ID: "1.2", Text: "b", DependsOn: []string{"1.1"}},
			},
		}}},
	}
	done := make(chan struct{})
	var items []Item
	go func() {
		items = Build([]*ir.Change{c}).Changes[0].Phases[0].Items
		close(done)
	}()
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("cycle caused the level computation to hang")
	}
	for _, it := range items {
		if it.Level < 0 {
			t.Errorf("negative level for %s: %d", it.ID, it.Level)
		}
	}
}

func TestPhaseMarkersCarriedToDetailFeed(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Harden",
			Markers: map[string]string{"shape": "loop", "stop": "green", "maxIters": "3"},
			Items:   []ir.TaskItem{{Text: "x"}},
		}}},
	}
	got := Build([]*ir.Change{c}).Changes[0].Phases[0].Markers
	want := map[string]string{"shape": "loop", "stop": "green", "maxIters": "3"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("markers = %v, want %v", got, want)
	}
}

func TestTaskItemCarriesDependsOn(t *testing.T) {
	c := &ir.Change{
		Name: "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{
			Number: "1", Name: "Build",
			Items: []ir.TaskItem{
				{ID: "1.1", Text: "root"},
				{ID: "1.2", Text: "leaf", DependsOn: []string{"1.1"}},
			},
		}}},
	}
	items := Build([]*ir.Change{c}).Changes[0].Phases[0].Items
	if !reflect.DeepEqual(items[1].DependsOn, []string{"1.1"}) {
		t.Errorf("DependsOn = %v, want [1.1]", items[1].DependsOn)
	}
	if items[0].ID != "1.1" {
		t.Errorf("ID not carried through: %+v", items[0])
	}
}
