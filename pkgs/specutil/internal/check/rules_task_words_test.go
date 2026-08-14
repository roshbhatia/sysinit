package check

import (
	"strings"
	"testing"

	"github.com/roshbhatia/specutil/internal/ir"
)

func wordsChange(text string) *ir.Change {
	return &ir.Change{
		Name: "c",
		Tasks: &ir.Tasks{
			Section: ir.Section{Raw: "## 1. Build\n"},
			Phases: []ir.Phase{{
				Number: "1", Name: "Build",
				Items: []ir.TaskItem{{ID: "1.1", Text: text}},
			}},
		},
	}
}

func TestTaskTextMaxWordsFlagsAnOverlongLine(t *testing.T) {
	long := strings.TrimSpace(strings.Repeat("word ", 61))
	rep, err := Run(Config{Rules: []RuleConfig{{ID: "task-text-max-words", Params: map[string]any{"max": 60}}}},
		[]*ir.Change{wordsChange(long)})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if rep.OK() {
		t.Fatal("a 61-word task line must be flagged against a 60-word budget")
	}
	if !strings.Contains(rep.Findings[0].Msg, "1.1") {
		t.Errorf("the finding should name the task: %s", rep.Findings[0].Msg)
	}
}

func TestTaskTextMaxWordsPassesAtTheBudgetAndWhenUnset(t *testing.T) {
	at := strings.TrimSpace(strings.Repeat("word ", 60))
	rep, err := Run(Config{Rules: []RuleConfig{{ID: "task-text-max-words", Params: map[string]any{"max": 60}}}},
		[]*ir.Change{wordsChange(at)})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Errorf("a task exactly at the budget must pass: %+v", rep.Findings)
	}

	rep, err = Run(Config{Rules: []RuleConfig{{ID: "task-text-max-words"}}},
		[]*ir.Change{wordsChange(strings.Repeat("word ", 500))})
	if err != nil {
		t.Fatalf("Run: %v", err)
	}
	if !rep.OK() {
		t.Errorf("an unset budget must check nothing: %+v", rep.Findings)
	}
}
