package ask

import (
	"context"
	"encoding/json"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

type fixtureRunner struct {
	run func(external.Request) (external.Result, error)
}

func (runner *fixtureRunner) Run(_ context.Context, request external.Request) (external.Result, error) {
	return runner.run(request)
}

func TestStartValidatesStructuredAskResult(t *testing.T) {
	t.Parallel()

	runtimeDirectory := t.TempDir()
	var schemaPath string
	runner := &fixtureRunner{run: func(request external.Request) (external.Result, error) {
		for _, argument := range request.Arguments {
			if strings.HasPrefix(argument, "@") {
				schemaPath = strings.TrimPrefix(argument, "@")
			}
		}
		if schemaPath == "" {
			t.Fatal("ask schema argument is missing")
		}
		if _, err := os.Stat(schemaPath); err != nil {
			t.Fatalf("schema file is unavailable during Run(): %v", err)
		}
		return external.Result{ExitCode: 0, Stdout: []byte(`{"summary":"done"}`)}, nil
	}}
	adapter := newFixtureAdapter(t, runtimeDirectory, runner)
	envelope := startEnvelope(t)
	events := make([]string, 0, 2)
	result, err := adapter.Invoke(context.Background(), envelope, func(kind string, _ json.RawMessage) error {
		events = append(events, kind)
		return nil
	})
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	if result.Handle == nil || result.SessionState != domain.SessionStateCompleted ||
		strings.Join(events, ",") != "agent.started,agent.completed" {
		t.Fatalf("operation result = %#v, events = %#v", result, events)
	}
	if _, err := os.Stat(schemaPath); !os.IsNotExist(err) {
		t.Fatalf("temporary schema remains: %v", err)
	}
	var output StartResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if output.Status != "completed" || string(output.Value) != `{"summary":"done"}` {
		t.Fatalf("start output = %#v", output)
	}
	validateAskResult(t, envelope, result)
	handleID := domain.AdapterHandleID("ask-handle")
	descriptor := plugin.HandleDescriptor{
		ID: handleID, PluginID: "sysinit", Port: domain.AdapterPortAgentRuntime,
		AdapterID: AdapterID, FormatVersion: 1, OpaqueValue: result.Handle.OpaqueValue,
	}
	reconciled, err := adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{descriptor})
	if err != nil || len(reconciled) != 1 || reconciled[0].State != plugin.ReconcileStateCompleted {
		t.Fatalf("Reconcile() = %#v, %v", reconciled, err)
	}
}

func TestStartReturnsStructuredQuestion(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{run: func(external.Request) (external.Result, error) {
		return external.Result{
			ExitCode: 3, Stderr: []byte("ask: the agent needs to know: Which package should change?\n"),
		}, nil
	}}
	adapter := newFixtureAdapter(t, t.TempDir(), runner)
	envelope := startEnvelope(t)
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output StartResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if output.Status != "needs-input" || output.Question != "Which package should change?" {
		t.Fatalf("start output = %#v", output)
	}
	validateAskResult(t, envelope, result)
}

func TestStartRejectsOffSchemaResult(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{run: func(external.Request) (external.Result, error) {
		return external.Result{ExitCode: 0, Stdout: []byte(`{"wrong":true}`)}, nil
	}}
	adapter := newFixtureAdapter(t, t.TempDir(), runner)
	_, err := adapter.Invoke(context.Background(), startEnvelope(t), nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Invoke() error = %v", err)
	}
}

func startEnvelope(t *testing.T) plugin.OperationEnvelope {
	t.Helper()
	schema := json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","required":["summary"],
  "properties":{"summary":{"type":"string"}},"additionalProperties":false
}`)
	digest, err := workflowmodel.JSONSchemaDigest(schema)
	if err != nil {
		t.Fatalf("JSONSchemaDigest() returned %v", err)
	}
	input, err := json.Marshal(StartRequest{
		Prompt: "Complete the task.", Provider: "codex", ResponseSchema: schema,
		ResponseSchemaDigest: digest,
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	return plugin.OperationEnvelope{
		ID: "operation-ask", AdapterID: AdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationStart, Input: input,
		JobPolicy: &domain.JobPolicy{
			Approvals:  domain.ApprovalPolicyNever,
			Filesystem: domain.FilesystemPolicyReadOnly,
			Network:    domain.NetworkPolicyDeny,
		},
		Deadline: time.Now().Add(time.Minute),
	}
}

func newFixtureAdapter(t *testing.T, runtimeDirectory string, runner CommandRunner) *Adapter {
	t.Helper()
	adapter, err := New(Config{
		Executable: "/fixture/ask", Directory: "/workspace", RuntimeDirectory: runtimeDirectory,
		Environment: []string{"PATH=/fixture"},
	}, runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	return adapter
}

func validateAskResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
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
