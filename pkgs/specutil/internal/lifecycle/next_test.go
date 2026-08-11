package lifecycle

import "testing"

import "github.com/roshbhatia/specutil/internal/ir"

// phase builds a phase whose items carry the given ids, done flags, and deps.
func phase(number, name, shape string, items ...ir.TaskItem) ir.Phase {
	p := ir.Phase{Number: number, Name: name, Items: items}
	if shape != "" {
		p.Markers = map[string]string{"shape": shape}
	}
	return p
}

func item(id string, done bool, deps ...string) ir.TaskItem {
	return ir.TaskItem{ID: id, Text: "do " + id, Done: done, DependsOn: deps}
}

func change(phases ...ir.Phase) *ir.Change {
	return &ir.Change{Name: "demo", Tasks: &ir.Tasks{Phases: phases}}
}

func ids(ts []Task) []string {
	out := make([]string, 0, len(ts))
	for _, t := range ts {
		out = append(out, t.ID)
	}
	return out
}

func eq(t *testing.T, label string, got, want []string) {
	t.Helper()
	if len(got) != len(want) {
		t.Fatalf("%s: got %v, want %v", label, got, want)
	}
	for i := range got {
		if got[i] != want[i] {
			t.Fatalf("%s: got %v, want %v", label, got, want)
		}
	}
}

func TestReadySetIsTasksWhoseDepsAreDone(t *testing.T) {
	n := ComputeNext(change(phase("1", "Build", "graph",
		item("1.1", true), item("1.2", false), item("1.3", false, "1.2"), item("1.4", false, "1.1"))))
	eq(t, "ready", ids(n.Ready), []string{"1.2", "1.4"})
	eq(t, "blocked", ids(n.Blocked), []string{"1.3"})
	if !n.Concurrent {
		t.Error("two runnable tasks in a graph phase are concurrent")
	}
}

// A phase is a boundary between runs, so a later phase's work is never offered
// alongside an earlier phase's.
func TestReadinessNeverCrossesAPhase(t *testing.T) {
	n := ComputeNext(change(
		phase("1", "First", "graph", item("1.1", false)),
		phase("2", "Second", "graph", item("2.1", false)),
	))
	if n.Phase != "1" {
		t.Fatalf("expected phase 1, got %q", n.Phase)
	}
	eq(t, "ready", ids(n.Ready), []string{"1.1"})
}

func TestPhasesOrderNumericallyNotLexically(t *testing.T) {
	n := ComputeNext(change(
		phase("10", "Tenth", "graph", item("10.1", false)),
		phase("9", "Ninth", "graph", item("9.1", false)),
	))
	if n.Phase != "9" {
		t.Fatalf("phase 9 must come before phase 10, got %q", n.Phase)
	}
}

// A loop re-runs the same tasks, so its next iteration reads what this one wrote
// and the ready set must not be split across workers.
// A graph phase may legally declare no edges, but then nothing states the order.
// Claiming concurrency there would send a verify task out alongside the tasks it
// verifies, which is how every seshy session's changes are written today.
func TestGraphWithNoDeclaredEdgesIsNotConcurrent(t *testing.T) {
	n := ComputeNext(change(phase("1", "Toolchain", "graph",
		item("1.1", false), item("1.2", false), item("1.3", false))))
	if n.EdgesDeclared {
		t.Error("no subtask declares a dependency, so no edges are declared")
	}
	if n.Concurrent {
		t.Error("a graph phase with no declared edges must not claim concurrency")
	}
	if len(n.Ready) != 3 {
		t.Errorf("all three are still ready, got %d", len(n.Ready))
	}
}

// One declared edge is enough: the author engaged with ordering, so a subtask
// carrying none is genuinely independent.
func TestOneDeclaredEdgeEnablesConcurrency(t *testing.T) {
	n := ComputeNext(change(phase("1", "Build", "graph",
		item("1.1", true), item("1.2", false), item("1.3", false, "1.1"))))
	if !n.EdgesDeclared || !n.Concurrent {
		t.Errorf("expected edges declared and concurrent, got %+v", n)
	}
}

func TestLoopPhaseIsNeverConcurrent(t *testing.T) {
	n := ComputeNext(change(phase("1", "Converge", "loop",
		item("1.1", false), item("1.2", false))))
	if n.Concurrent {
		t.Error("a loop phase must not report concurrent")
	}
}

func TestGateAndReviewAreNotFanOutWork(t *testing.T) {
	gate := ir.TaskItem{ID: "1.2", Text: "Apply: switch", Kind: ir.KindApply}
	review := ir.TaskItem{ID: "1.3", Text: "Adversarial review (skill)"}
	n := ComputeNext(change(phase("1", "Ship", "graph", item("1.1", false), gate, review)))
	if n.Concurrent {
		t.Error("one task plus a gate and a review is not fan-out")
	}
	if len(n.Ready) != 3 {
		t.Errorf("all three are still ready, got %d", len(n.Ready))
	}
}

func TestEveryTaskDoneReportsDone(t *testing.T) {
	n := ComputeNext(change(phase("1", "Build", "graph", item("1.1", true))))
	if !n.Done {
		t.Error("expected done")
	}
	if len(n.Ready) != 0 {
		t.Error("a finished change offers no work")
	}
}

// A dep naming nothing in the change is task-deps-resolve's finding. Treating it
// as blocking would stall the phase on a typo with no way to proceed.
func TestUnknownDependencyDoesNotBlock(t *testing.T) {
	n := ComputeNext(change(phase("1", "Build", "graph", item("1.1", false, "9.9"))))
	eq(t, "ready", ids(n.Ready), []string{"1.1"})
}

func TestCycleLeavesReadyEmptyWithWorkPending(t *testing.T) {
	n := ComputeNext(change(phase("1", "Build", "graph",
		item("1.1", false, "1.2"), item("1.2", false, "1.1"))))
	if n.Done || len(n.Ready) != 0 {
		t.Fatalf("a cycle must leave ready empty with work pending: %+v", n)
	}
}
