package transcript

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

// One prompt, one reply that reasons and then calls a tool, and the tool's
// result. The whole point of the reader is that this stands up as a tree with no
// OTLP span anywhere, so the test asserts the tree and not the record count.
const fixture = `{"type":"ai-title","aiTitle":"Reading a transcript"}
{"type":"user","uuid":"u1","sessionId":"s1","cwd":"/repo","gitBranch":"main","timestamp":"2026-08-25T10:00:00.000Z","message":{"content":"count the files"}}
{"type":"assistant","uuid":"a1","parentUuid":"u1","sessionId":"s1","requestId":"req_1","timestamp":"2026-08-25T10:00:01.000Z","message":{"model":"claude-opus-5","stop_reason":"tool_use","usage":{"output_tokens":42,"cache_read_input_tokens":900},"content":[{"type":"thinking","thinking":"ls first"},{"type":"text","text":"Counting them."},{"type":"tool_use","id":"toolu_1","name":"Bash","input":{"command":"ls | wc -l"}}]}}
{"type":"user","uuid":"u2","parentUuid":"a1","sessionId":"s1","timestamp":"2026-08-25T10:00:03.000Z","message":{"content":[{"type":"tool_result","tool_use_id":"toolu_1","content":"7"}]}}
{"type":"user","uuid":"u3","parentUuid":"u2","sessionId":"s1","isMeta":true,"timestamp":"2026-08-25T10:00:04.000Z","message":{"content":"a system reminder, not a turn"}}
`

func write(t *testing.T) string {
	t.Helper()
	dir := t.TempDir()
	project := filepath.Join(dir, "-repo")
	if err := os.MkdirAll(project, 0o755); err != nil {
		t.Fatal(err)
	}
	path := filepath.Join(project, "s1.jsonl")
	if err := os.WriteFile(path, []byte(fixture), 0o600); err != nil {
		t.Fatal(err)
	}
	return dir
}

func TestReadBuildsTheTree(t *testing.T) {
	batch := Read(write(t), time.Hour, "")

	byID := map[string]int{}
	for i, span := range batch.Spans {
		byID[span.SpanID] = i
	}
	for _, want := range []string{"u1", "req_1", "toolu_1"} {
		if _, ok := byID[want]; !ok {
			t.Fatalf("no span %q; got %d spans", want, len(batch.Spans))
		}
	}

	turn := batch.Spans[byID["u1"]]
	if turn.Name != "agent.turn" {
		t.Errorf("turn name = %q", turn.Name)
	}
	if turn.ParentID != "" {
		t.Errorf("turn has parent %q", turn.ParentID)
	}
	if turn.Attrs["user_prompt"] != "count the files" {
		t.Errorf("prompt = %q", turn.Attrs["user_prompt"])
	}
	// The turn has to reach the tool result, or its own duration reports only
	// the moment the prompt was submitted.
	if got := turn.End.Sub(turn.Start); got != 3*time.Second {
		t.Errorf("turn duration = %s, want 3s", got)
	}
	if turn.Attrs["session.title"] != "Reading a transcript" {
		t.Errorf("title = %q", turn.Attrs["session.title"])
	}

	model := batch.Spans[byID["req_1"]]
	if model.Name != "agent.model" || model.ParentID != "u1" {
		t.Errorf("model = %q under %q", model.Name, model.ParentID)
	}
	if model.Attrs["output_tokens"] != "42" || model.Attrs["cache_read_tokens"] != "900" {
		t.Errorf("usage not read: %v", model.Attrs)
	}
	if model.Attrs["stop_reason"] != "tool_use" {
		t.Errorf("stop_reason = %q", model.Attrs["stop_reason"])
	}

	// The call belongs to the reply that asked for it, not to the turn beside it.
	tool := batch.Spans[byID["toolu_1"]]
	if tool.ParentID != "req_1" {
		t.Errorf("tool parent = %q, want req_1", tool.ParentID)
	}
	if tool.Attrs["tool_name"] != "Bash" || tool.Attrs["full_command"] != "ls | wc -l" {
		t.Errorf("tool args not read: %v", tool.Attrs)
	}
	if got := tool.End.Sub(tool.Start); got != 2*time.Second {
		t.Errorf("tool duration = %s, want 2s", got)
	}

	// A meta entry is a reminder the harness injected. Counting one as a prompt
	// split the run at every hook.
	turns := 0
	for _, span := range batch.Spans {
		if span.Name == "agent.turn" {
			turns++
		}
	}
	if turns != 1 {
		t.Errorf("turns = %d, want 1", turns)
	}
}

func TestReadCarriesTheText(t *testing.T) {
	batch := Read(write(t), time.Hour, "")
	found := map[string]otlp.Record{}
	for _, one := range batch.Records {
		found[one.Event] = one
	}
	if got := found[EventPrompt].Body; got != "count the files" {
		t.Errorf("prompt record = %q", got)
	}
	reply := found[EventText]
	if reply.Body != "Counting them." || reply.Attrs["thinking"] != "ls first" {
		t.Errorf("reply record = %q / %q", reply.Body, reply.Attrs["thinking"])
	}
	if reply.Attrs["request_id"] != "req_1" {
		t.Errorf("reply join key = %q", reply.Attrs["request_id"])
	}
	if got := found[EventResult].Body; got != "7" {
		t.Errorf("result record = %q", got)
	}
}

func TestSessionFilterSkipsOtherFiles(t *testing.T) {
	if got := Read(write(t), time.Hour, "other"); len(got.Spans) != 0 {
		t.Errorf("filter let %d spans through", len(got.Spans))
	}
}
