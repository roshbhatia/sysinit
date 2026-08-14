package provider

import (
	"encoding/json"
	"os"
	"strings"
	"testing"
)

const codexStream = `{"type":"thread.started","thread_id":"th_1"}
{"type":"item.completed","item":{"id":"i1","type":"reasoning","text":"Thinking about it."}}
{"type":"item.started","item":{"id":"i2","type":"command_execution","command":"grep -n x f.txt"}}
{"type":"item.completed","item":{"id":"i2","type":"command_execution","command":"grep -n x f.txt"}}
{"type":"item.completed","item":{"id":"i3","type":"agent_message","text":"the answer"}}
{"type":"turn.completed"}
`

func TestACodexStreamBecomesOneEventPerThingThatHappened(t *testing.T) {
	var run codexRun
	events, _ := collect(t, func(out chan<- Event) {
		run = scanCodex(strings.NewReader(codexStream), "gpt-5", out)
	})

	started := kinds(events, Started)
	if len(started) != 1 || started[0].Text != "gpt-5" {
		t.Errorf("the opening line is %v, want the model", started)
	}
	if run.Session != "th_1" {
		t.Errorf("the thread is %q", run.Session)
	}
	if run.Answer != "the answer" {
		t.Errorf("the answer is %q", run.Answer)
	}
	if run.Turns != 1 {
		t.Errorf("the turn count is %d, want 1", run.Turns)
	}
	if run.Failure != "" {
		t.Errorf("a run that answered reported the failure %q", run.Failure)
	}
	if text := kinds(events, Text); len(text) != 2 {
		t.Errorf("the prose is %v, want the reasoning and the answer", text)
	}
}

func TestACodexToolIsAnnouncedOnceThoughItArrivesTwice(t *testing.T) {
	events, _ := collect(t, func(out chan<- Event) {
		scanCodex(strings.NewReader(codexStream), "", out)
	})
	tools := kinds(events, Tool)
	if len(tools) != 1 {
		t.Fatalf("the tool lines are %v, want one", tools)
	}
	if tools[0].Tool != "shell" || tools[0].Text != "grep -n x f.txt" {
		t.Errorf("the tool line is %+v", tools[0])
	}
}

func TestACodexRunWithNoModelSaysSoRatherThanNothing(t *testing.T) {
	events, _ := collect(t, func(out chan<- Event) {
		scanCodex(strings.NewReader(`{"type":"thread.started","thread_id":"th"}`), "", out)
	})
	if started := kinds(events, Started); len(started) != 1 || started[0].Text != "default model" {
		t.Errorf("the opening line is %v", started)
	}
}

func TestACodexTurnThatFailedCarriesItsReason(t *testing.T) {
	stream := `{"type":"turn.failed","error":{"message":"the sandbox refused"}}` + "\n"
	var run codexRun
	collect(t, func(out chan<- Event) {
		run = scanCodex(strings.NewReader(stream), "", out)
	})
	if run.Failure != "the sandbox refused" {
		t.Errorf("the failure is %q", run.Failure)
	}
}

func TestACodexErrorBecomesANotice(t *testing.T) {
	stream := `{"type":"error","message":"rate limited"}` + "\n" +
		`{"type":"item.completed","item":{"id":"e","type":"error","message":"a tool broke"}}` + "\n"
	events, _ := collect(t, func(out chan<- Event) {
		scanCodex(strings.NewReader(stream), "", out)
	})
	if notices := kinds(events, Notice); len(notices) != 2 {
		t.Errorf("the notices are %v, want both the stream error and the item one", notices)
	}
}

func TestACodexStreamSurvivesALineItCannotRead(t *testing.T) {
	stream := "{{{ not json\n" + `{"type":"item.completed","item":{"id":"a","type":"agent_message","text":"still here"}}` + "\n"
	var run codexRun
	collect(t, func(out chan<- Event) {
		run = scanCodex(strings.NewReader(stream), "", out)
	})
	if run.Answer != "still here" {
		t.Errorf("the answer after the bad line is %q", run.Answer)
	}
}

func TestACodexLineLongerThanTheDefaultLimitIsStillRead(t *testing.T) {
	huge, err := json.Marshal(map[string]any{
		"type": "item.completed",
		"item": map[string]any{"id": "big", "type": "command_execution", "command": strings.Repeat("y", 200_000)},
	})
	if err != nil {
		t.Fatal(err)
	}
	stream := string(huge) + "\n" + `{"type":"item.completed","item":{"id":"a","type":"agent_message","text":"after the big one"}}` + "\n"

	var run codexRun
	collect(t, func(out chan<- Event) {
		run = scanCodex(strings.NewReader(stream), "", out)
	})
	if run.Answer != "after the big one" {
		t.Errorf("the answer after the long line is %q", run.Answer)
	}
}

func TestEachKindOfCodexToolIsNamed(t *testing.T) {
	for _, one := range []struct {
		item codexItem
		name string
		text string
	}{
		{codexItem{Type: "command_execution", Command: "ls"}, "shell", "ls"},
		{codexItem{Type: "mcp_tool_call", Server: "linear", Tool: "list_issues"}, "mcp", "linear.list_issues"},
		{codexItem{Type: "mcp_tool_call", Server: "linear"}, "mcp", "linear"},
		{codexItem{Type: "web_search", Query: "go generics"}, "search", "go generics"},
	} {
		name, text, ok := toolOf(one.item)
		if !ok || name != one.name || text != one.text {
			t.Errorf("%s became %q/%q", one.item.Type, name, text)
		}
	}
	if _, _, ok := toolOf(codexItem{Type: "reasoning"}); ok {
		t.Error("reasoning was named a tool")
	}
}

func TestAFileChangeNamesEveryPathItTouched(t *testing.T) {
	item := codexItem{Type: "file_change"}
	item.Changes = append(item.Changes, struct {
		Path string `json:"path"`
	}{Path: "a.go"}, struct {
		Path string `json:"path"`
	}{Path: "b.go"})

	name, text, ok := toolOf(item)
	if !ok || name != "edit" || text != "a.go b.go" {
		t.Errorf("the edit line is %q/%q", name, text)
	}
}

func TestTheShapeIsFoundWhereverTheModelPutIt(t *testing.T) {
	for _, one := range []struct {
		name  string
		text  string
		found bool
	}{
		{"on its own", `{"a":1}`, true},
		{"inside a fence", "```json\n{\"a\":1}\n```", true},
		{"inside a sentence", `Here you go: {"a":1} and that is all.`, true},
		{"no object at all", "just prose", false},
		{"an object that will not parse", `{not json}`, false},
	} {
		t.Run(one.name, func(t *testing.T) {
			if got := structured(one.text) != nil; got != one.found {
				t.Errorf("found is %v, want %v", got, one.found)
			}
		})
	}
}

func TestTheSchemaIsWrittenOutForCodexToRead(t *testing.T) {
	path, err := schemaFile(map[string]any{"type": "object"})
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(path)

	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var read map[string]any
	if err := json.Unmarshal(raw, &read); err != nil {
		t.Fatalf("the file is not JSON: %v", err)
	}
	if read["type"] != "object" {
		t.Errorf("the file holds %v", read)
	}
}
