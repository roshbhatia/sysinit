package note

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

type fixtureRunner struct {
	responses map[string][]external.Result
	calls     []string
}

func (runner *fixtureRunner) Run(_ context.Context, request external.Request) (external.Result, error) {
	key := filepath.Base(request.Executable) + "\x00" + strings.Join(request.Arguments, "\x00")
	runner.calls = append(runner.calls, key)
	responses := runner.responses[key]
	if len(responses) == 0 {
		return external.Result{ExitCode: 127, Stderr: []byte("fixture response is missing")}, nil
	}
	runner.responses[key] = responses[1:]
	return responses[0], nil
}

func TestSyncNormalizesNotesAndOwnerAuthority(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string][]external.Result{
		commandKey("utils", "note", "list", "--json", "--file", "/workspace/main.go", "--open"): {{
			ExitCode: 0,
			Stdout: []byte(`{"version":1,"notes":[
  {"id":"owner-1","file":"/workspace/main.go","line":4,"summary":"Explain this branch.","rationale":"The fallback is unclear.","author":"Roshan","origin":"user","anchor":"if fallback {","state":"open"},
  {"id":"agent-1","file":"/workspace/main.go","line":8,"summary":"The branch now names its fallback.","rationale":null,"author":"Codex","origin":"agent","anchor":"fallback := defaultValue"}
]}`),
		}},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-sync", AdapterID: AdapterID, Port: domain.AdapterPortAnnotation,
		Operation: OperationSync,
		Input:     json.RawMessage(`{"file":"/workspace/main.go","openOnly":true}`),
		Deadline:  time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output Result
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 2 || output.Records[0].Authority != "owner" ||
		output.Records[1].State != "answered" || output.SourceDigest == "" {
		t.Fatalf("note output = %#v", output)
	}
	validateResult(t, envelope, result)
}

func TestAnswerReturnsAnsweredNoteAndReply(t *testing.T) {
	t.Parallel()

	answerKey := commandKey(
		"utils", "note", "answer", "--id", "owner-1", "--summary", "The fallback is required.",
		"--rationale", "The caller can omit its value.", "--author", "Codex",
	)
	listKey := commandKey("utils", "note", "list", "--json")
	runner := &fixtureRunner{responses: map[string][]external.Result{
		answerKey: {{ExitCode: 0, Stdout: []byte("note: answered owner-1\n")}},
		listKey: {{ExitCode: 0, Stdout: []byte(`{"version":1,"notes":[
  {"id":"owner-1","file":"/workspace/main.go","line":4,"summary":"Explain this branch.","rationale":null,"author":"Roshan","origin":"user","anchor":"if fallback {","state":"answered"},
  {"id":"reply-1","file":"/workspace/main.go","line":4,"summary":"The fallback is required.","rationale":"The caller can omit its value.","author":"Codex","origin":"agent","anchor":"if fallback {","reply_to":"owner-1"},
  {"id":"other-1","file":"/workspace/other.go","line":2,"summary":"Unrelated.","rationale":null,"author":"Codex","origin":"agent","anchor":"return nil"}
]}`)}},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-answer", AdapterID: AdapterID, Port: domain.AdapterPortAnnotation,
		Operation: OperationAnswer,
		Input: json.RawMessage(
			`{"id":"owner-1","summary":"The fallback is required.","rationale":"The caller can omit its value.","author":"Codex"}`,
		),
		Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output Result
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 2 || output.Records[1].Kind != "reply" ||
		output.Records[1].ReplyTo != "owner-1" || len(runner.calls) != 2 {
		t.Fatalf("note output = %#v, calls = %#v", output, runner.calls)
	}
	validateResult(t, envelope, result)
}

func TestLocalAdapterSyncsSelectedFile(t *testing.T) {
	file := os.Getenv("COLCHIS_TEST_NOTE_FILE")
	if file == "" {
		t.Skip("COLCHIS_TEST_NOTE_FILE is unset")
	}
	directory, err := os.Getwd()
	if err != nil {
		t.Fatalf("Getwd() returned %v", err)
	}
	adapter, err := NewLocal(directory, 8<<20)
	if err != nil {
		t.Fatalf("NewLocal() returned %v", err)
	}
	input, err := json.Marshal(SyncRequest{File: file})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-live-note", AdapterID: AdapterID, Port: domain.AdapterPortAnnotation,
		Operation: OperationSync, Input: input, Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	validateResult(t, envelope, result)
}

func newFixtureAdapter(t *testing.T, runner CommandRunner) *Adapter {
	t.Helper()
	adapter, err := New(Config{
		Executable: "/fixture/utils", Directory: "/workspace",
		Environment: []string{"PATH=/fixture"}, MaxSourceBytes: 1 << 20,
	}, runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	return adapter
}

func validateResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
	t.Helper()
	manifest, err := Manifest()
	if err != nil {
		t.Fatalf("Manifest() returned %v", err)
	}
	if err := plugin.ValidateOperationEnvelope(envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationEnvelope() returned %v", err)
	}
	if err := plugin.ValidateOperationResult(result, envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationResult() returned %v", err)
	}
}

func commandKey(executable string, arguments ...string) string {
	return executable + "\x00" + strings.Join(arguments, "\x00")
}
