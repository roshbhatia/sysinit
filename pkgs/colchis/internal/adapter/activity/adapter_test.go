package activity

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
	responses map[string]external.Result
}

func (runner *fixtureRunner) Run(_ context.Context, request external.Request) (external.Result, error) {
	key := filepath.Base(request.Executable) + "\x00" + strings.Join(request.Arguments, "\x00")
	result, found := runner.responses[key]
	if !found {
		return external.Result{ExitCode: 127, Stderr: []byte("fixture response is missing")}, nil
	}
	return result, nil
}

func TestImportNormalizesTraceAndEditActivity(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	editLog := filepath.Join(directory, "edit-events.jsonl")
	if err := os.WriteFile(editLog, []byte(`{"version":1,"ts":1700000001000,"harness":"codex","kind":"edit","file":"/workspace/main.go","cwd":"/workspace","session":"session-1","delta":"/private/sysinit/deltas/secret.diff"}`+"\n"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("traces", "-json", "-session", "session-1"): {
			ExitCode: 0,
			Stdout: []byte(`{"traceId":"trace-1","spanId":"turn-1","name":"agent.turn","service":"codex","session":"session-1","startUnixNano":"1700000000000000000","endUnixNano":"1700000000500000000","attrs":{"traces.view":"activity"}}
`),
		},
		commandKey("agent-edit-event", "--print-log", "--cwd", "/workspace"): {
			ExitCode: 0, Stdout: []byte(editLog + "\n"),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-import", AdapterID: AdapterID, Port: domain.AdapterPortActivity,
		Operation: OperationImport,
		Input: json.RawMessage(`{
  "workspace":"/workspace","session":"session-1",
  "sources":["traces","agent-edit-event"]
}`),
		Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ImportResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 2 || output.Records[0].SourceID != "trace-1:turn-1" ||
		output.Records[1].Source != SourceEdits || output.SourceDigest == "" {
		t.Fatalf("activity output = %#v", output)
	}
	if strings.Contains(string(output.Records[1].OpaqueData), "/private/sysinit") {
		t.Fatalf("edit storage path leaked: %s", output.Records[1].OpaqueData)
	}
	validateActivityResult(t, envelope, result)
}

func TestObserveReturnsOneExternalSource(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("traces", "-json", "-all"): {
			ExitCode: 0,
			Stdout: []byte(
				`{"traceId":"trace-1","spanId":"turn-1","name":"agent.turn","startUnixNano":"1700000000000000000"}` + "\n" +
					`{"traceId":"trace-1","spanId":"model-1","parentId":"turn-1","name":"agent.model","startUnixNano":"1700000000100000000"}` + "\n",
			),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-observe", AdapterID: AdapterID, Port: domain.AdapterPortActivity,
		Operation: OperationObserve,
		Input:     json.RawMessage(`{"sourceId":"trace-1:model-1","sources":["traces"]}`),
		Deadline:  time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ImportResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 1 || output.Records[0].Kind != "model_call" ||
		output.Records[0].ParentSourceID != "trace-1:turn-1" {
		t.Fatalf("activity output = %#v", output)
	}
	validateActivityResult(t, envelope, result)
}

func TestImportRetainsSparseEventsWithDistinctIdentities(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("traces", "-json", "-session", "session-1"): {
			ExitCode: 0,
			Stdout: []byte(
				`{"event":"codex.sse_event","service":"codex","session":"session-1","startUnixNano":"1700000000000000000","attrs":{"event.kind":"response.completed"}}` + "\n" +
					`{"event":"codex.tool_decision","traceId":"trace-1","spanId":"span-1","service":"codex","session":"session-1","startUnixNano":"1700000000100000000"}` + "\n" +
					`{"event":"codex.tool_result","traceId":"trace-1","spanId":"span-1","service":"codex","session":"session-1","startUnixNano":"1700000000200000000"}` + "\n",
			),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-sparse-events", AdapterID: AdapterID, Port: domain.AdapterPortActivity,
		Operation: OperationImport,
		Input:     json.RawMessage(`{"workspace":"/workspace","session":"session-1","sources":["traces"]}`),
		Deadline:  time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ImportResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 3 {
		t.Fatalf("record count = %d, want 3", len(output.Records))
	}
	identities := make(map[string]struct{}, len(output.Records))
	for _, record := range output.Records {
		identities[record.SourceID] = struct{}{}
	}
	if len(identities) != 3 || output.Records[0].Kind != "model_call" {
		t.Fatalf("activity output = %#v", output)
	}
	validateActivityResult(t, envelope, result)
}

func TestImportReturnsRecentRecordsWithinRequestedLimit(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("traces", "-json", "-session", "session-1"): {
			ExitCode: 0,
			Stdout: []byte(
				`{"traceId":"trace-1","spanId":"turn-1","name":"agent.turn","startUnixNano":"1700000000000000000"}` + "\n" +
					`{"traceId":"trace-1","spanId":"turn-2","name":"agent.turn","startUnixNano":"1700000001000000000"}` + "\n",
			),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-limited", AdapterID: AdapterID, Port: domain.AdapterPortActivity,
		Operation: OperationImport,
		Input: json.RawMessage(
			`{"workspace":"/workspace","session":"session-1","sources":["traces"],"maxRecords":1}`,
		),
		Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ImportResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Records) != 1 || output.Records[0].SourceID != "trace-1:turn-2" ||
		output.TotalRecords != 2 || !output.Truncated {
		t.Fatalf("activity output = %#v", output)
	}
	validateActivityResult(t, envelope, result)
}

func TestLocalAdapterImportsSelectedActivitySession(t *testing.T) {
	session := os.Getenv("COLCHIS_TEST_ACTIVITY_SESSION")
	if session == "" {
		t.Skip("COLCHIS_TEST_ACTIVITY_SESSION is unset")
	}
	workspace, err := os.Getwd()
	if err != nil {
		t.Fatalf("Getwd() returned %v", err)
	}
	adapter, err := NewLocal(workspace, 64<<20)
	if err != nil {
		t.Fatalf("NewLocal() returned %v", err)
	}
	input, err := json.Marshal(ImportRequest{
		Workspace: workspace, Session: session, Sources: []string{SourceTraces, SourceEdits},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-live-activity", AdapterID: AdapterID, Port: domain.AdapterPortActivity,
		Operation: OperationImport, Input: input, Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	validateActivityResult(t, envelope, result)
}

func newFixtureAdapter(t *testing.T, runner CommandRunner) *Adapter {
	t.Helper()
	adapter, err := New(Config{
		TracesExecutable: "/fixture/traces", EditEventExecutable: "/fixture/agent-edit-event",
		Directory: "/workspace", Environment: []string{"PATH=/fixture"}, MaxSourceBytes: 1 << 20,
	}, runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	return adapter
}

func validateActivityResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
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
