package seshy

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
)

type fixtureRunner struct {
	responses map[string]external.Result
	calls     []external.Request
}

func (runner *fixtureRunner) Run(_ context.Context, request external.Request) (external.Result, error) {
	runner.calls = append(runner.calls, request)
	result, found := runner.responses[strings.Join(request.Arguments, "\x00")]
	if !found {
		return external.Result{ExitCode: 127, Stderr: []byte("fixture response is missing")}, nil
	}
	return result, nil
}

func TestCreateReturnsSeshyWorkspaceHandle(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("new", "session-one", "--empty"): {ExitCode: 0},
		commandKey("attach", "session-one"): {
			ExitCode: 0,
			Stdout:   []byte(`{"name":"session-one","path":"/sessions/session-one","repos":[]}`),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	envelope := plugin.OperationEnvelope{
		ID: "operation-create", AdapterID: WorkspaceAdapterID, Port: domain.AdapterPortWorkspace,
		Operation: OperationCreate,
		Input:     json.RawMessage(`{"name":"session-one","repositories":[]}`),
		Deadline:  time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	if result.Handle == nil || result.Handle.FormatVersion != 1 ||
		string(result.Handle.OpaqueValue) != `{"name":"session-one"}` {
		t.Fatalf("operation result = %#v", result)
	}
	var output WorkspaceResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if output.Workspace.Name != "session-one" || output.Workspace.Repositories == nil || output.SourceDigest == "" {
		t.Fatalf("workspace output = %#v", output)
	}
	validateResult(t, envelope, result)
}

func TestAddUsesOpaqueWorkspaceHandle(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("add", "session-one", "/repos/api"): {ExitCode: 0},
		commandKey("attach", "session-one"): {
			ExitCode: 0,
			Stdout: []byte(`{
  "name":"session-one","path":"/sessions/session-one",
  "repos":[{"name":"api","path":"/sessions/session-one/api","branch":"dev/api"}]
}`),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	handleID := domain.AdapterHandleID("workspace-handle")
	handle := plugin.HandleDescriptor{
		ID: handleID, PluginID: "sysinit", Port: domain.AdapterPortWorkspace,
		AdapterID: WorkspaceAdapterID, FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"name":"session-one"}`),
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-add", AdapterID: WorkspaceAdapterID, Port: domain.AdapterPortWorkspace,
		Operation: OperationAdd, HandleID: &handleID, Handle: &handle,
		Input: json.RawMessage(`{"repository":"/repos/api"}`), Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output WorkspaceResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Workspace.Repositories) != 1 || output.Workspace.Repositories[0].Name != "api" {
		t.Fatalf("workspace output = %#v", output)
	}
	validateResult(t, envelope, result)
}

func TestWorkspaceHandleMustMatchExplicitName(t *testing.T) {
	t.Parallel()

	adapter := newFixtureAdapter(t, &fixtureRunner{responses: map[string]external.Result{}})
	handleID := domain.AdapterHandleID("workspace-handle")
	handle := plugin.HandleDescriptor{
		ID: handleID, PluginID: "sysinit", Port: domain.AdapterPortWorkspace,
		AdapterID: WorkspaceAdapterID, FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"name":"session-one"}`),
	}
	_, err := adapter.Invoke(context.Background(), plugin.OperationEnvelope{
		ID: "operation-snapshot", AdapterID: WorkspaceAdapterID, Port: domain.AdapterPortWorkspace,
		Operation: OperationSnapshot, HandleID: &handleID, Handle: &handle,
		Input: json.RawMessage(`{"name":"session-two"}`), Deadline: time.Now().Add(time.Minute),
	}, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("Invoke() error = %v", err)
	}
}

func TestReconcileChecksSeshyWorkspace(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("attach", "session-one"): {
			ExitCode: 0, Stdout: []byte(`{"name":"session-one","path":"/sessions/session-one","repos":[]}`),
		},
	}}
	adapter := newFixtureAdapter(t, runner)
	handle := plugin.HandleDescriptor{
		ID: "workspace-handle", PluginID: "sysinit", Port: domain.AdapterPortWorkspace,
		AdapterID: WorkspaceAdapterID, FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"name":"session-one"}`),
	}
	results, err := adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{handle})
	if err != nil || len(results) != 1 || results[0].State != plugin.ReconcileStateAdopted {
		t.Fatalf("Reconcile() = %#v, %v", results, err)
	}
}

func TestLocalAdapterReadsSelectedSeshySession(t *testing.T) {
	name := os.Getenv("COLCHIS_TEST_SESHY_SESSION")
	if name == "" {
		t.Skip("COLCHIS_TEST_SESHY_SESSION is unset")
	}
	adapter, err := NewLocal(".", 0)
	if err != nil {
		t.Fatalf("NewLocal() returned %v", err)
	}
	input, err := json.Marshal(workspaceRequest{Name: name})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-live-snapshot", AdapterID: WorkspaceAdapterID, Port: domain.AdapterPortWorkspace,
		Operation: OperationSnapshot, Input: input,
		Deadline: time.Now().Add(time.Minute),
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
		Executable: "/fixture/sy", Directory: "/workspace", Environment: []string{"PATH=/fixture"},
	}, runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	return adapter
}

func validateResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
	t.Helper()
	manifests, err := Manifests()
	if err != nil {
		t.Fatalf("Manifests() returned %v", err)
	}
	for _, manifest := range manifests {
		if manifest.ID == envelope.AdapterID {
			if err := plugin.ValidateOperationEnvelope(envelope, manifest); err != nil {
				t.Fatalf("ValidateOperationEnvelope() returned %v", err)
			}
			if err := plugin.ValidateOperationResult(result, envelope, manifest); err != nil {
				t.Fatalf("ValidateOperationResult() returned %v", err)
			}
			return
		}
	}
	t.Fatalf("manifest %q is missing", envelope.AdapterID)
}

func commandKey(arguments ...string) string {
	return strings.Join(arguments, "\x00")
}
