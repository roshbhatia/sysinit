package rollout

import (
	"os"
	"path/filepath"
	"testing"
)

func TestReadFileNormalizesCodexActivity(t *testing.T) {
	path := filepath.Join(t.TempDir(), "rollout-test.jsonl")
	fixture := `{"type":"session_meta","timestamp":"2026-08-25T01:00:00Z","payload":{"id":"session-1","cwd":"/work/one"}}
{"type":"turn_context","timestamp":"2026-08-25T01:00:00Z","payload":{"turn_id":"turn-1","cwd":"/work/one","model":"gpt-test"}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:00Z","payload":{"type":"task_started","turn_id":"turn-1","trace_id":"trace-1","started_at":1787619600}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:01Z","payload":{"type":"item_completed","thread_id":"session-1","turn_id":"turn-1","started_at_ms":1787619601000,"completed_at_ms":1787619601100,"item":{"type":"UserMessage","id":"user-1","content":[{"type":"Text","text":"fix it"}]}}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:02Z","payload":{"type":"item_completed","thread_id":"session-1","turn_id":"turn-1","item":{"type":"AgentMessage","id":"message-1","phase":"commentary","content":[{"type":"Text","text":"checking"}]}}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:03Z","payload":{"type":"item_completed","thread_id":"session-1","turn_id":"turn-1","started_at_ms":1787619603000,"completed_at_ms":1787619603400,"item":{"type":"CommandExecution","id":"command-1","command":["/bin/zsh","-lc","git status --short"],"cwd":"file:///work/two","stdout":" M file.go","stderr":"","exit_code":0}}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:04Z","payload":{"type":"item_completed","thread_id":"session-1","turn_id":"turn-1","started_at_ms":1787619604000,"completed_at_ms":1787619604500,"item":{"type":"FileChange","id":"edit-1","status":"completed","changes":{"/work/two/file.go":{"type":"update","unified_diff":"@@ -1 +1 @@\n-old\n+new\n"}}}}}
{"type":"event_msg","timestamp":"2026-08-25T01:00:05Z","payload":{"type":"task_complete","turn_id":"turn-1","started_at":1787619600,"completed_at":1787619605}}
`
	if err := os.WriteFile(path, []byte(fixture), 0o600); err != nil {
		t.Fatal(err)
	}

	batch := ReadFile(path)
	if got, want := len(batch.Spans), 4; got != want {
		t.Fatalf("spans = %d, want %d", got, want)
	}
	if got, want := len(batch.Records), 4; got != want {
		t.Fatalf("records = %d, want %d", got, want)
	}

	byID := map[string]int{}
	for index, span := range batch.Spans {
		byID[span.SpanID] = index
		if span.Session != "session-1" {
			t.Errorf("span %q session = %q", span.SpanID, span.Session)
		}
		if span.Attrs["traces.view"] != "activity" {
			t.Errorf("span %q has no activity view", span.SpanID)
		}
	}

	turn := batch.Spans[byID["turn-1"]]
	if turn.Name != "agent.turn" || turn.Attrs["model"] != "gpt-test" {
		t.Errorf("turn = %#v", turn)
	}
	message := batch.Spans[byID["message-1"]]
	if message.Start.Year() != 2026 || message.End != message.Start {
		t.Errorf("message timestamps = %s to %s", message.Start, message.End)
	}
	command := batch.Spans[byID["command-1"]]
	if command.ParentID != "turn-1" || command.Attrs["full_command"] != "git status --short" || command.Attrs["cwd"] != "/work/two" {
		t.Errorf("command = %#v", command)
	}
	if command.Attrs["traces.action"] != "shell" {
		t.Errorf("command action = %q", command.Attrs["traces.action"])
	}
	edit := batch.Spans[byID["edit-1"]]
	if edit.Attrs["files_changed"] != "1" || edit.Attrs["lines_added"] != "1" || edit.Attrs["lines_removed"] != "1" {
		t.Errorf("edit attrs = %#v", edit.Attrs)
	}
	if edit.Attrs["traces.action"] != "edit" {
		t.Errorf("edit action = %q", edit.Attrs["traces.action"])
	}
	if batch.Records[0].Event != EventPrompt || batch.Records[0].Attrs["prompt"] != "fix it" {
		t.Errorf("prompt = %#v", batch.Records[0])
	}
}
