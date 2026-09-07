package guard

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

func TestBoundCommand(t *testing.T) {
	for _, command := range []string{
		"cat /etc/hosts",
		"rg TODO .",
		"find . -name '*.go'",
		"git log --oneline",
	} {
		bounded, ok := boundCommand(command)
		if !ok || !strings.Contains(bounded, command) || !strings.Contains(bounded, "head -c 16384") {
			t.Fatalf("%q was not bounded: %q", command, bounded)
		}
	}

	for _, command := range []string{
		"cat /etc/hosts | head -20",
		"rg TODO . --max-count=5",
		"find . -delete",
		"git status",
		"cat",
	} {
		if bounded, ok := boundCommand(command); ok {
			t.Fatalf("%q was rewritten as %q", command, bounded)
		}
	}
}

func TestDecideBashPreservesInput(t *testing.T) {
	input := map[string]any{"command": "rg TODO .", "timeout": float64(30)}
	outcome := DecideBash(input, "", nil)
	if outcome.Kind != hookfmt.Allow {
		t.Fatalf("decision = %q, want allow", outcome.Kind)
	}
	if outcome.UpdatedInput["timeout"] != float64(30) {
		t.Fatalf("updated input lost timeout: %v", outcome.UpdatedInput)
	}
	if !strings.Contains(outcome.Context, "capped") {
		t.Fatalf("the bound left no note for the model: %+v", outcome)
	}
	if input["command"] != "rg TODO ." {
		t.Fatalf("decision mutated its input: %v", input)
	}

	input["run_in_background"] = true
	if outcome := DecideBash(input, "", nil); outcome.Kind != hookfmt.Pass {
		t.Fatalf("background command decision = %q", outcome.Kind)
	}
}

func TestLoadRulesAndDecide(t *testing.T) {
	path := filepath.Join(t.TempDir(), "rules.json")
	if err := os.WriteFile(path, []byte(`[{"regex":"rm[ ]+-rf","reason":"unsafe"}]`), 0o600); err != nil {
		t.Fatal(err)
	}
	rules, err := loadRules(path)
	if err != nil {
		t.Fatalf("loadRules: %v", err)
	}
	if reason, denied := Decide("rm -rf target", rules); !denied || reason != "unsafe" {
		t.Fatalf("Decide returned reason=%q denied=%v", reason, denied)
	}
	if _, err := loadRules(""); err == nil {
		t.Fatal("loadRules accepted an empty path")
	}
}

func largeFile(t *testing.T, name string) (string, string) {
	t.Helper()
	dir := t.TempDir()
	path := filepath.Join(dir, name)
	body := strings.Repeat(strings.Repeat("x", 100)+"\n", 200)
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	return dir, path
}

func TestDecideReadDeniesUnboundedLargeRead(t *testing.T) {
	_, path := largeFile(t, "large.txt")
	var event readEvent
	event.ToolInput.FilePath = path
	outcome := DecideRead(event)
	if outcome.Kind != hookfmt.Deny {
		t.Fatalf("large read decision = %q", outcome.Kind)
	}
	for _, want := range []string{"offset and limit", bulkReadCommand, path, "about 200 lines"} {
		if !strings.Contains(outcome.Message, want) {
			t.Fatalf("deny message lacks %q: %s", want, outcome.Message)
		}
	}

	limit := 10
	event.ToolInput.Limit = &limit
	if outcome := DecideRead(event); outcome.Kind != hookfmt.Pass {
		t.Fatalf("bounded read decision = %q", outcome.Kind)
	}

	event.ToolInput.Limit = nil
	event.ToolInput.FilePath = path + ".png"
	if err := os.Rename(path, path+".png"); err != nil {
		t.Fatal(err)
	}
	if outcome := DecideRead(event); outcome.Kind != hookfmt.Pass {
		t.Fatalf("opaque read decision = %q", outcome.Kind)
	}
}

func TestDecideBashRoutesWholeFileReads(t *testing.T) {
	dir, path := largeFile(t, "large.txt")
	small := filepath.Join(dir, "small.txt")
	if err := os.WriteFile(small, []byte("short\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	for _, command := range []string{"cat large.txt", "cat -n " + path, "less large.txt", "bat large.txt"} {
		outcome := DecideBash(map[string]any{"command": command}, dir, nil)
		if outcome.Kind != hookfmt.Deny || !strings.Contains(outcome.Message, bulkReadCommand) {
			t.Fatalf("%q decision = %+v", command, outcome)
		}
	}

	if outcome := DecideBash(map[string]any{"command": "cat small.txt"}, dir, nil); outcome.Kind != hookfmt.Allow {
		t.Fatalf("small cat decision = %q, want the bound", outcome.Kind)
	}
	for _, command := range []string{"head -n 20 large.txt", "cat large.txt small.txt", "cat large.txt | wc -l"} {
		if outcome := DecideBash(map[string]any{"command": command}, dir, nil); outcome.Kind == hookfmt.Deny {
			t.Fatalf("%q was denied", command)
		}
	}
}
