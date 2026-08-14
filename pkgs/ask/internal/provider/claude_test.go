package provider

import (
	"strings"
	"testing"
)

func collect(t *testing.T, scan func(chan<- Event)) ([]Event, *Result) {
	t.Helper()
	events := make(chan Event, 64)
	done := make(chan struct{})
	var seen []Event
	go func() {
		defer close(done)
		for event := range events {
			seen = append(seen, event)
		}
	}()
	scan(events)
	close(events)
	<-done

	var result *Result
	for _, event := range seen {
		if event.Kind == Done {
			result = event.Result
		}
	}
	return seen, result
}

func wanted() map[string]any {
	return map[string]any{"type": "object"}
}

func kinds(events []Event, want Kind) []Event {
	var picked []Event
	for _, event := range events {
		if event.Kind == want {
			picked = append(picked, event)
		}
	}
	return picked
}

const claudeStream = `{"type":"system","subtype":"init","model":"claude-opus-5","tools":["Bash","Read"]}
{"type":"assistant","message":{"content":[{"type":"text","text":"Reading the file.\nThen the rest."}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ls -a","description":"list"}}]}}
{"type":"rate_limit_event"}
{"type":"result","subtype":"success","result":"two","session_id":"abc","total_cost_usd":0.25,"duration_ms":1500,"num_turns":3}
`

func TestAClaudeStreamBecomesOneEventPerThingThatHappened(t *testing.T) {
	events, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(claudeStream), nil, out)
	})

	started := kinds(events, Started)
	if len(started) != 1 || started[0].Text != "claude-opus-5, 2 tools" {
		t.Errorf("the opening line is %v, want the model and its tool count", started)
	}

	if text := kinds(events, Text); len(text) != 1 || text[0].Text != "Reading the file.\nThen the rest." {
		t.Errorf("the prose is %v", text)
	}
	tools := kinds(events, Tool)
	if len(tools) != 1 || tools[0].Tool != "Bash" || tools[0].Text != "ls -a" {
		t.Errorf("the tool line is %v, want Bash and its command", tools)
	}
	if notices := kinds(events, Notice); len(notices) != 1 {
		t.Errorf("the rate limit was not reported: %v", notices)
	}

	if result == nil {
		t.Fatal("the stream carried no result")
	}
	if result.Text != "two" || result.Turns != 3 || result.CostUSD != 0.25 || result.Session != "abc" {
		t.Errorf("the result is %+v", result)
	}
	if result.Failed {
		t.Errorf("a successful run was reported as failed: %s", result.Reason)
	}
}

func TestAClaudeStreamWithNoResultReportsNone(t *testing.T) {
	_, result := collect(t, func(out chan<- Event) {
		if got := scanClaude(strings.NewReader(`{"type":"system","subtype":"init"}`), nil, out); got != nil {
			t.Errorf("a stream with no result line returned %+v", got)
		}
	})
	if result != nil {
		t.Errorf("a Done event was sent for a run that never answered: %+v", result)
	}
}

func TestAClaudeStreamSurvivesALineItCannotRead(t *testing.T) {
	stream := "not json at all\n" + `{"type":"result","result":"still here"}` + "\n"
	_, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(stream), nil, out)
	})
	if result == nil || result.Text != "still here" {
		t.Errorf("the answer after the bad line is %+v", result)
	}
}

func TestClaudeAnswersTheShapeThatWasAskedFor(t *testing.T) {
	stream := `{"type":"result","result":"{}","structured_output":{"level":"error"}}` + "\n"
	_, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(stream), wanted(), out)
	})
	if result == nil || result.Failed {
		t.Fatalf("a structured answer was rejected: %+v", result)
	}
	if result.Structured["level"] != "error" {
		t.Errorf("the shape is %v", result.Structured)
	}
}

func TestClaudeFindsTheShapeInsideProse(t *testing.T) {
	stream := `{"type":"result","result":"Here it is:\n{\"level\":\"warn\"}\nThat is all."}` + "\n"
	_, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(stream), wanted(), out)
	})
	if result == nil || result.Failed {
		t.Fatalf("an object wrapped in prose was rejected: %+v", result)
	}
	if result.Structured["level"] != "warn" {
		t.Errorf("the shape is %v", result.Structured)
	}
}

func TestClaudeFailsWhenNoShapeCameBack(t *testing.T) {
	stream := `{"type":"result","result":"no object anywhere"}` + "\n"
	_, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(stream), wanted(), out)
	})
	if result == nil || !result.Failed {
		t.Fatalf("prose passed for a shape: %+v", result)
	}
	if result.Reason != offShape {
		t.Errorf("the reason is %q, want the shared wording", result.Reason)
	}
}

func TestAFailedClaudeRunKeepsItsOwnReason(t *testing.T) {
	stream := `{"type":"result","subtype":"error_max_turns","is_error":true,"result":""}` + "\n"
	_, result := collect(t, func(out chan<- Event) {
		scanClaude(strings.NewReader(stream), wanted(), out)
	})
	if result == nil || !result.Failed {
		t.Fatalf("a failed run was reported as an answer: %+v", result)
	}
	if result.Reason != "error_max_turns" {
		t.Errorf("the reason is %q, want the harness's own", result.Reason)
	}
}

func TestATooLineNamesTheArgumentWorthShowing(t *testing.T) {
	for _, one := range []struct {
		name string
		args string
		want string
	}{
		{"a command wins over its description", `{"description":"list","command":"ls -a"}`, "ls -a"},
		{"a path when there is no command", `{"file_path":"/tmp/x.go"}`, "/tmp/x.go"},
		{"only the first line", `{"command":"one\ntwo"}`, "one"},
		{"nothing worth showing", `{"unknown":"x"}`, ""},
		{"arguments that will not parse", `not json`, ""},
	} {
		t.Run(one.name, func(t *testing.T) {
			if got := summarize([]byte(one.args)); got != one.want {
				t.Errorf("the line is %q, want %q", got, one.want)
			}
		})
	}
}

func TestALongToolArgumentIsCutRatherThanWrapped(t *testing.T) {
	got := summarize([]byte(`{"command":"` + strings.Repeat("x", 200) + `"}`))
	if len([]rune(got)) != 91 || !strings.HasSuffix(got, "…") {
		t.Errorf("the line is %d runes and ends %q", len([]rune(got)), got[len(got)-3:])
	}
}
