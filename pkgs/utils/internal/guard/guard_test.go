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
	outcome := DecideBash(input, nil)
	if outcome.Kind != hookfmt.Allow {
		t.Fatalf("decision = %q, want allow", outcome.Kind)
	}
	if outcome.UpdatedInput["timeout"] != float64(30) {
		t.Fatalf("updated input lost timeout: %v", outcome.UpdatedInput)
	}
	if input["command"] != "rg TODO ." {
		t.Fatalf("decision mutated its input: %v", input)
	}

	input["run_in_background"] = true
	if outcome := DecideBash(input, nil); outcome.Kind != hookfmt.Pass {
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

func TestDecideReadClipsOnlyUnboundedText(t *testing.T) {
	path := filepath.Join(t.TempDir(), "large.txt")
	body := strings.Repeat(strings.Repeat("x", 100)+"\n", 200)
	if err := os.WriteFile(path, []byte(body), 0o600); err != nil {
		t.Fatal(err)
	}
	var event readEvent
	event.ToolInput.FilePath = path
	outcome := DecideRead(event)
	if outcome.Kind != hookfmt.Allow {
		t.Fatalf("large read decision = %q", outcome.Kind)
	}
	if limit, ok := outcome.UpdatedInput["limit"].(int); !ok || limit < readMinLines {
		t.Fatalf("large read limit = %v", outcome.UpdatedInput["limit"])
	}

	limit := 10
	event.ToolInput.Limit = &limit
	if outcome := DecideRead(event); outcome.Kind != hookfmt.Pass {
		t.Fatalf("bounded read decision = %q", outcome.Kind)
	}
}
