package syncplan

import (
	"reflect"
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func change(tasks ...ir.TaskItem) *ir.Change {
	return &ir.Change{
		Name:  "demo",
		Tasks: &ir.Tasks{Phases: []ir.Phase{{Number: "1", Name: "Build", Items: tasks}}},
	}
}

func task(id, text string) ir.TaskItem { return ir.TaskItem{ID: id, Text: text} }

func TestIdentitySurvivesRenumber(t *testing.T) {
	// Same phase + same text, different task number => same identity.
	a := Identity("Build", "Implement the parser")
	b := Identity("Build", "Implement the parser")
	if a != b {
		t.Fatal("identity should be number-independent")
	}
	// Minor edit (trailing punctuation, case) is absorbed by normalization.
	if Identity("Build", "Implement the parser") != Identity("Build", "implement the parser.") {
		t.Error("identity should absorb case and trailing punctuation")
	}
}

func TestIdentityDistinctTasksDoNotCollide(t *testing.T) {
	if Identity("Build", "Write the parser") == Identity("Build", "Write the renderer") {
		t.Error("distinct tasks must not collide")
	}
}

func TestContentHashFlipsOnAnyEdit(t *testing.T) {
	if ContentHash("hello") == ContentHash("hello.") {
		t.Error("content hash must change on any byte change")
	}
}

func TestLockRoundTrip(t *testing.T) {
	repo := t.TempDir()
	lock, err := LoadLock(repo, "demo")
	if err != nil {
		t.Fatal(err)
	}
	lock.Set("linear", "abc123", Ref{ExternalID: "ENG-1", ContentHash: "deadbeef"})
	if err := lock.Save(repo, "demo"); err != nil {
		t.Fatal(err)
	}
	reloaded, err := LoadLock(repo, "demo")
	if err != nil {
		t.Fatal(err)
	}
	ref, ok := reloaded.Get("linear", "abc123")
	if !ok || ref.ExternalID != "ENG-1" {
		t.Fatalf("round-trip failed: %+v ok=%v", ref, ok)
	}
}

func TestLockGetUnknownIsAbsent(t *testing.T) {
	lock, _ := LoadLock(t.TempDir(), "demo")
	if _, ok := lock.Get("linear", "nope"); ok {
		t.Error("unknown identity should report absent, not fabricate")
	}
}

func TestPlanCreateUpdateOrphan(t *testing.T) {
	c := change(task("1.1", "Keep me"), task("1.2", "Change me"), task("1.3", "Brand new"))
	lock, _ := LoadLock(t.TempDir(), "demo")
	// "Keep me" already synced and unchanged.
	lock.Set("linear", Identity("1 Build", "Keep me"), Ref{ExternalID: "ENG-1", ContentHash: ContentHash("Keep me")})
	// "Change me" synced but content drifted.
	lock.Set("linear", Identity("1 Build", "Change me"), Ref{ExternalID: "ENG-2", ContentHash: ContentHash("old text")})
	// A lock entry with no current task => orphan.
	lock.Set("linear", "ghostid", Ref{ExternalID: "ENG-9", ContentHash: "x"})

	plan := BuildPlan(c, lock, "linear")
	kinds := map[OpKind]int{}
	var update Operation
	for _, op := range plan.Operations {
		kinds[op.Kind]++
		if op.Kind == OpUpdate {
			update = op
		}
	}
	if kinds[OpCreate] != 1 || kinds[OpUpdate] != 1 || kinds[OpOrphan] != 1 {
		t.Fatalf("expected 1 create/1 update/1 orphan, got %v", kinds)
	}
	if update.ExternalID != "ENG-2" {
		t.Errorf("update must carry the existing external ID, got %q", update.ExternalID)
	}
}

func TestPlanDeterministic(t *testing.T) {
	c := change(task("1.1", "a"), task("1.2", "b"), task("1.3", "c"))
	lock, _ := LoadLock(t.TempDir(), "demo")
	p1 := BuildPlan(c, lock, "linear")
	p2 := BuildPlan(c, lock, "linear")
	if len(p1.Operations) != len(p2.Operations) {
		t.Fatal("plan length unstable")
	}
	if !reflect.DeepEqual(p1, p2) {
		t.Errorf("plan unstable across runs:\n%+v\n%+v", p1, p2)
	}
}

func TestDiffReportsCategories(t *testing.T) {
	// one new, one edited (minor, identity-stable), one removed (orphan).
	c := change(task("1.1", "Edited task slightly"), task("1.2", "Totally new task"))
	lock, _ := LoadLock(t.TempDir(), "demo")
	lock.Set("linear", Identity("1 Build", "Edited task slightly"), Ref{
		ExternalID: "ENG-1", ContentHash: ContentHash("Edited task"), Title: "Edited task",
	})
	lock.Set("linear", Identity("1 Build", "Removed task"), Ref{
		ExternalID: "ENG-2", ContentHash: ContentHash("Removed task"), Title: "Removed task",
	})

	d := DiffChange(c, lock, "linear")
	if len(d.New) != 1 || len(d.Changed) != 1 || len(d.Orphaned) != 1 {
		t.Fatalf("expected 1 new/1 changed/1 orphaned, got new=%d changed=%d orphaned=%d",
			len(d.New), len(d.Changed), len(d.Orphaned))
	}
}

func TestPlanLabelsCarryStageAndKind(t *testing.T) {
	c := &ir.Change{
		Name: "my-feature",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "Build and Deploy", Items: []ir.TaskItem{
				{ID: "1.1", Text: "verify: endpoint returns 200", Kind: ir.KindVerify},
			}},
		}},
	}
	lock, _ := LoadLock(t.TempDir(), "my-feature")
	plan := BuildPlan(c, lock, "github-issues")

	if len(plan.Operations) != 1 {
		t.Fatalf("expected 1 operation, got %d", len(plan.Operations))
	}
	op := plan.Operations[0]
	want := []string{"stage:build-and-deploy", "kind:verify"}
	if !reflect.DeepEqual(op.Labels, want) {
		t.Errorf("Labels = %v, want %v", op.Labels, want)
	}
	if op.Milestone != "Build and Deploy" {
		t.Errorf("Milestone = %q, want %q", op.Milestone, "Build and Deploy")
	}
}

// A tracker must never see the source numbering: no task identifier in the
// title, no phase number in the milestone, no "1.1" anywhere in the body.
func TestPlanCarriesNoSourceNumbering(t *testing.T) {
	c := &ir.Change{
		Name: "my-feature",
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "Foundation", Items: []ir.TaskItem{
				{ID: "1.1", Text: "create the endpoint"},
			}},
		}},
	}
	lock, _ := LoadLock(t.TempDir(), "my-feature")
	plan := BuildPlan(c, lock, "linear")

	op := plan.Operations[0]
	if op.Title != "Create the endpoint" {
		t.Errorf("Title = %q, want the capitalized task text with no identifier", op.Title)
	}
	if op.Milestone != "Foundation" {
		t.Errorf("Milestone = %q, want the phase name with no number", op.Milestone)
	}
	if op.Position != 1 {
		t.Errorf("Position = %d, want 1", op.Position)
	}
	for _, field := range []string{op.Title, op.Milestone, op.Body, plan.Overview, plan.Title} {
		if strings.Contains(field, "1.1") {
			t.Errorf("source task identifier leaked into tracker output: %q", field)
		}
	}
}

func TestPlanTitleAndOverviewAreReaderFacing(t *testing.T) {
	c := &ir.Change{
		Name:     "add-auth-layer",
		Proposal: &ir.Proposal{Why: "Endpoints are open."},
		Tasks: &ir.Tasks{Phases: []ir.Phase{
			{Number: "1", Name: "Foundation", Items: []ir.TaskItem{{ID: "1.1", Text: "do it"}}},
		}},
	}
	lock, _ := LoadLock(t.TempDir(), "add-auth-layer")
	plan := BuildPlan(c, lock, "linear")

	if plan.Title != "Add auth layer" {
		t.Errorf("Title = %q, want the humanized slug", plan.Title)
	}
	if plan.Change != "add-auth-layer" {
		t.Errorf("Change = %q, want the slug retained as the correlation key", plan.Change)
	}
	if !strings.Contains(plan.Overview, "Endpoints are open.") {
		t.Errorf("overview must carry the summary, got %q", plan.Overview)
	}
	if !reflect.DeepEqual(plan.Milestones, []string{"Foundation"}) {
		t.Errorf("Milestones = %v, want [Foundation]", plan.Milestones)
	}
}

func TestDiffFuzzyRematch(t *testing.T) {
	// A heavy edit moves the identity, but the title is similar enough to
	// re-match the orphaned lock entry instead of reporting new + orphan.
	c := change(task("1.1", "Implement the markdown section parser carefully"))
	lock, _ := LoadLock(t.TempDir(), "demo")
	lock.Set("linear", Identity("1 Build", "Implement the markdown section parser"), Ref{
		ExternalID: "ENG-7", ContentHash: "x", Title: "Implement the markdown section parser",
	})

	d := DiffChange(c, lock, "linear")
	if len(d.Orphaned) != 0 {
		t.Errorf("fuzzy re-match should consume the orphan, got %v", d.Orphaned)
	}
	if len(d.New) != 0 {
		t.Errorf("re-matched item should not be reported as new, got %v", d.New)
	}
	if len(d.Changed) != 1 || d.Changed[0].ExternalID != "ENG-7" {
		t.Fatalf("expected one re-matched change carrying ENG-7, got %+v", d.Changed)
	}
}
