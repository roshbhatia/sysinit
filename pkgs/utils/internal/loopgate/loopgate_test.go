package loopgate

import (
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func gate(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	t.Setenv("SYSINIT_LOOP_GATE_DIR", dir)
	return filepath.Join(dir, "loop-gate.json")
}

func capture(t *testing.T) func() string {
	t.Helper()
	read, write, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	saved := os.Stdout
	os.Stdout = write
	done := make(chan string, 1)
	go func() {
		data, _ := io.ReadAll(read)
		done <- string(data)
	}()
	return func() string {
		os.Stdout = saved
		write.Close()
		out := <-done
		read.Close()
		return out
	}
}

func TestArmWritesTheDeclaredConditionAndItsDefaults(t *testing.T) {
	path := gate(t)
	if code := Run([]string{"arm", "--until", "true"}); code != 0 {
		t.Fatalf("arm exited %d", code)
	}
	s, ok := read(path)
	if !ok {
		t.Fatal("arm wrote no state")
	}
	if s.Until != "true" || s.Max != 4 || s.Stall != 2 || s.Iter != 0 {
		t.Errorf("armed state = %+v", s)
	}
}

func TestArmRefusesAMissingConditionOrANonInteger(t *testing.T) {
	gate(t)
	for _, args := range [][]string{
		{"arm"},
		{"arm", "--max", "3"},
		{"arm", "--until", "true", "--max", "many"},
		{"arm", "--until", "true", "--stall", "1.5"},
		{"arm", "--until"},
	} {
		if code := Run(args); code == 0 {
			t.Errorf("arm accepted %v", args)
		}
	}
}

func TestCheckWithNoStateSaysNothing(t *testing.T) {
	gate(t)
	if outcome := Decide(strings.NewReader("{}")); outcome.Kind != "pass" {
		t.Errorf("decision = %q with no gate armed", outcome.Kind)
	}
}

func TestAPassingConditionDisarmsTheGate(t *testing.T) {
	path := gate(t)
	Run([]string{"arm", "--until", "true"})
	if outcome := Decide(strings.NewReader("{}")); outcome.Kind != "pass" {
		t.Fatalf("decision = %q", outcome.Kind)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Error("a passing condition left the gate armed")
	}
}

func TestAFailingConditionBlocksAndCountsTheIteration(t *testing.T) {
	path := gate(t)
	Run([]string{"arm", "--until", "echo still broken; exit 3", "--max", "9", "--stall", "9"})

	decision := Decide(strings.NewReader("{}"))
	if decision.Kind != "block" {
		t.Errorf("decision = %q", decision.Kind)
	}
	for _, want := range []string{"iteration 1/9", "Exit code: 3", "still broken"} {
		if !strings.Contains(decision.Message, want) {
			t.Errorf("message is missing %q:\n%s", want, decision.Message)
		}
	}

	s, ok := read(path)
	if !ok {
		t.Fatal("a blocked stop left no state")
	}
	if s.Iter != 1 || s.LastHash == "" {
		t.Errorf("state after one iteration = %+v", s)
	}
}

func TestAnActiveStopHookIsNotBlockedTwice(t *testing.T) {
	gate(t)
	Run([]string{"arm", "--until", "exit 1", "--max", "9", "--stall", "9"})
	if outcome := Decide(strings.NewReader(`{"stop_hook_active":true}`)); outcome.Kind != "pass" {
		t.Errorf("an active stop hook got %q", outcome.Kind)
	}
}

func TestIdenticalOutputStallsTheGate(t *testing.T) {
	path := gate(t)
	Run([]string{"arm", "--until", "echo same; exit 1", "--max", "99", "--stall", "2"})
	for i := 0; i < 3; i++ {
		Decide(strings.NewReader("{}"))
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Error("three identical failures left the gate armed")
	}
}

func TestTheIterationCapDisarmsTheGate(t *testing.T) {
	path := gate(t)

	Run([]string{"arm", "--until", "echo $RANDOM; exit 1", "--max", "2", "--stall", "99"})
	for i := 0; i < 2; i++ {
		Decide(strings.NewReader("{}"))
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Error("the cap did not disarm the gate")
	}
}

func TestStatusReportsBothCounters(t *testing.T) {
	gate(t)
	Run([]string{"arm", "--until", "make test", "--max", "5", "--stall", "3"})
	restore := capture(t)
	Run([]string{"status"})
	out := restore()
	for _, want := range []string{"armed", "make test", "0/5", "0/3"} {
		if !strings.Contains(out, want) {
			t.Errorf("status is missing %q:\n%s", want, out)
		}
	}
}

func TestClearDisarms(t *testing.T) {
	path := gate(t)
	Run([]string{"arm", "--until", "true"})
	if code := Run([]string{"clear"}); code != 0 {
		t.Fatalf("clear exited %d", code)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Error("clear left the state behind")
	}

	if code := Run([]string{"clear"}); code != 0 {
		t.Errorf("clear on a disarmed gate exited %d", code)
	}
}

func TestAnUnknownSubcommandIsAUsageError(t *testing.T) {
	for _, args := range [][]string{{}, {"nope"}} {
		if code := Run(args); code != 2 {
			t.Errorf("Run(%v) = %d, want 2", args, code)
		}
	}
}
