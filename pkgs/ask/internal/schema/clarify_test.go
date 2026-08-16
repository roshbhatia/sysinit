package schema

import (
	"encoding/json"
	"strings"
	"testing"
)

func TestRelaxedHoldsBothAnswerAndQuestion(t *testing.T) {
	built, err := Build("files:[]string, count:int")
	if err != nil {
		t.Fatal(err)
	}
	loose, mayAsk := Relaxed(built)
	if !mayAsk {
		t.Fatal("a shape built from a field spec can carry the question")
	}

	if err := Check(loose, map[string]any{"files": []any{"a.go"}, "count": 1}); err != nil {
		t.Fatalf("the answer should pass the wire shape, got %v", err)
	}
	if err := Check(loose, map[string]any{Field: "which directory?"}); err != nil {
		t.Fatalf("the question should pass the wire shape, got %v", err)
	}
	if err := Check(loose, map[string]any{"files": "a.go"}); err == nil {
		t.Fatal("a wrong type should fail even on the loose shape")
	}
}

// The Anthropic API rejects a top-level anyOf in a tool schema.
func TestRelaxedKeepsNoTopLevelUnion(t *testing.T) {
	built, err := Build("files:[]string")
	if err != nil {
		t.Fatal(err)
	}
	loose, _ := Relaxed(built)
	for _, banned := range []string{"anyOf", "oneOf", "allOf"} {
		if _, found := loose[banned]; found {
			t.Fatalf("the wire shape holds %s at the top level", banned)
		}
	}
	if loose["type"] != "object" {
		t.Fatal("the API also requires a top-level type")
	}
}

// Reaching back would make every field of the strict shape optional.
func TestRelaxedLeavesTheStrictShapeAlone(t *testing.T) {
	built, err := Build("files:[]string")
	if err != nil {
		t.Fatal(err)
	}
	before, _ := json.Marshal(built)
	Relaxed(built)
	after, _ := json.Marshal(built)
	if string(before) != string(after) {
		t.Fatalf("the strict shape changed:\n%s\n%s", before, after)
	}
	if err := Check(built, map[string]any{}); err == nil {
		t.Fatal("the strict shape still requires its fields")
	}
}

func TestRelaxedLeavesAHandWrittenSchemaAlone(t *testing.T) {
	given := map[string]any{"type": "array", "items": map[string]any{"type": "string"}}
	loose, mayAsk := Relaxed(given)
	if mayAsk {
		t.Fatal("a shape with no properties has nowhere to put the question")
	}
	if loose["type"] != "array" {
		t.Fatal("it should go out unchanged")
	}
}

func TestQuestion(t *testing.T) {
	if got := Question(map[string]any{Field: "which one?"}); got != "which one?" {
		t.Fatalf("got %q", got)
	}
	if got := Question(map[string]any{"files": []any{"a.go"}}); got != "" {
		t.Fatalf("an answer is not a question, got %q", got)
	}
	if got := Question(map[string]any{"files": []any{}, Field: "note"}); got != "" {
		t.Fatalf("a field beside the answer is not a question, got %q", got)
	}
	if got := Question(nil); got != "" {
		t.Fatalf("got %q", got)
	}
}

func TestRuleNamesTheField(t *testing.T) {
	if !strings.Contains(Rule, Field) {
		t.Fatal("the agent is told the field by name, so the two cannot drift")
	}
}
