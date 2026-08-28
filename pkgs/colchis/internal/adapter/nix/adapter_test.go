package nix

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

const fixtureSnapshotDigest = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

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

func TestResolveBindsNixIdentityToSnapshot(t *testing.T) {
	t.Parallel()

	workspace := t.TempDir()
	if err := os.WriteFile(filepath.Join(workspace, "flake.nix"), []byte("{}"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	workspace, err := filepath.EvalSymlinks(workspace)
	if err != nil {
		t.Fatalf("EvalSymlinks() returned %v", err)
	}
	reference := "path:" + workspace
	runner := &fixtureRunner{responses: resolveResponses(reference)}
	adapter := newFixtureAdapter(t, runner, nil)
	input, err := json.Marshal(ResolveRequest{
		Workspace: workspace, Shell: "default", SnapshotDigest: fixtureSnapshotDigest,
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-resolve", AdapterID: AdapterID, Port: domain.AdapterPortEnvironment,
		Operation: OperationResolve, Input: input,
		Deadline: time.Now().Add(time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	if result.Handle == nil || result.Handle.FormatVersion != 2 {
		t.Fatalf("operation result = %#v", result)
	}
	var output ResolveResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if output.Environment.System != "aarch64-darwin" || output.Environment.SnapshotDigest != fixtureSnapshotDigest ||
		output.Environment.Derivation != "/nix/store/environment.drv" {
		t.Fatalf("environment = %#v", output.Environment)
	}
	validateAdapterResult(t, envelope, result)
}

func TestExecuteUsesHandleAndConfiguredSecret(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey("develop", "path:/workspace#default", "--command", "go", "test", "./..."): {
			ExitCode: 2, Stdout: []byte("test output"), Stderr: []byte("test failed"),
		},
	}}
	adapter := newFixtureAdapter(t, runner, map[string]string{"MODEL_TOKEN": "secret-value"})
	envelope := environmentEnvelope(t, OperationExecute, json.RawMessage(`{
  "command":["go","test","./..."],"secretNames":["MODEL_TOKEN"],
  "expectedSnapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`))
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ExecuteResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if output.ExitCode != 2 || output.Stderr != "test failed" ||
		!containsEnvironment(runner.calls[0].Environment, "MODEL_TOKEN=secret-value") ||
		runner.calls[0].Directory == adapter.config.Directory {
		t.Fatalf("execution output = %#v, call = %#v", output, runner.calls[0])
	}
	validateAdapterResult(t, envelope, result)
}

func TestExecuteRejectsStaleSnapshotAndUnknownSecret(t *testing.T) {
	t.Parallel()

	adapter := newFixtureAdapter(t, &fixtureRunner{responses: map[string]external.Result{}}, nil)
	envelope := environmentEnvelope(t, OperationExecute, json.RawMessage(`{
  "command":["true"],"secretNames":[],
  "expectedSnapshotDigest":"sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
}`))
	_, err := adapter.Invoke(context.Background(), envelope, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("stale Invoke() error = %v", err)
	}

	envelope = environmentEnvelope(t, OperationExecute, json.RawMessage(`{
  "command":["true"],"secretNames":["MISSING"],
  "expectedSnapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`))
	_, err = adapter.Invoke(context.Background(), envelope, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("secret Invoke() error = %v", err)
	}
}

func TestExecuteRejectsWorkspaceChangesAfterResolution(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{}}
	adapter := newFixtureAdapter(t, runner, nil)
	envelope := environmentEnvelope(t, OperationExecute, json.RawMessage(`{
  "command":["true"],"secretNames":[],
  "expectedSnapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`))
	var handle handleValue
	if err := json.Unmarshal(envelope.Handle.OpaqueValue, &handle); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(handle.Workspace, "changed.txt"), []byte("changed"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	_, err := adapter.Invoke(context.Background(), envelope, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) || len(runner.calls) != 0 {
		t.Fatalf("changed workspace Invoke() error = %v after %d calls", err, len(runner.calls))
	}
}

func TestReconcileValidatesWorkspaceState(t *testing.T) {
	t.Parallel()

	adapter := newFixtureAdapter(t, &fixtureRunner{responses: map[string]external.Result{}}, nil)
	envelope := environmentEnvelope(t, OperationExecute, json.RawMessage(`{
  "command":["true"],"secretNames":[],
  "expectedSnapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`))
	results, err := adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{*envelope.Handle})
	if err != nil || len(results) != 1 || results[0].State != plugin.ReconcileStateAdopted {
		t.Fatalf("Reconcile() = %#v, %v", results, err)
	}
	legacy := *envelope.Handle
	legacy.ID = "legacy-environment-handle"
	legacy.FormatVersion = 1
	legacy.OpaqueValue = json.RawMessage(`{
  "environmentId":"sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
  "system":"aarch64-darwin","flakeReference":"path:/workspace","shell":"default",
  "derivation":"/nix/store/environment.drv",
  "snapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`)
	results, err = adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{legacy})
	if err != nil || len(results) != 1 || results[0].State != plugin.ReconcileStateOrphaned {
		t.Fatalf("legacy Reconcile() = %#v, %v", results, err)
	}
	var handle handleValue
	if err := json.Unmarshal(envelope.Handle.OpaqueValue, &handle); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if err := os.WriteFile(filepath.Join(handle.Workspace, "changed.txt"), []byte("changed"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	results, err = adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{*envelope.Handle})
	if err != nil || len(results) != 1 || results[0].State != plugin.ReconcileStateOrphaned {
		t.Fatalf("changed Reconcile() = %#v, %v", results, err)
	}
}

func TestCheckReturnsMachineReadableBuildEvidence(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]external.Result{
		commandKey(
			"build", "--no-link", "--json", "--no-write-lock-file",
			"path:/workspace#checks.aarch64-darwin.test",
		): {ExitCode: 0, Stdout: []byte(`[{"drvPath":"/nix/store/test.drv","outputs":{}}]`)},
	}}
	adapter := newFixtureAdapter(t, runner, nil)
	envelope := environmentEnvelope(t, OperationCheck, json.RawMessage(`{
  "checks":["test"],
  "expectedSnapshotDigest":"sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
}`))
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var output ChecksResult
	if err := json.Unmarshal(result.Output, &output); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(output.Checks) != 1 || output.Checks[0].Name != "test" || output.Checks[0].ExitCode != 0 {
		t.Fatalf("checks output = %#v", output)
	}
	validateAdapterResult(t, envelope, result)
}

func TestLocalAdapterResolvesSelectedNixWorkspace(t *testing.T) {
	workspace := os.Getenv("COLCHIS_TEST_NIX_WORKSPACE")
	if workspace == "" {
		t.Skip("COLCHIS_TEST_NIX_WORKSPACE is unset")
	}
	adapter, err := NewLocal(workspace, 0)
	if err != nil {
		t.Fatalf("NewLocal() returned %v", err)
	}
	input, err := json.Marshal(ResolveRequest{
		Workspace: workspace, Shell: "default", SnapshotDigest: fixtureSnapshotDigest,
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	envelope := plugin.OperationEnvelope{
		ID: "operation-live-resolve", AdapterID: AdapterID, Port: domain.AdapterPortEnvironment,
		Operation: OperationResolve, Input: input, Deadline: time.Now().Add(2 * time.Minute),
	}
	result, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	validateAdapterResult(t, envelope, result)
}

func resolveResponses(reference string) map[string]external.Result {
	return map[string]external.Result{
		commandKey("flake", "metadata", "--json", "--no-write-lock-file", reference): {
			ExitCode: 0,
			Stdout: []byte(`{
  "fingerprint":"fixture-fingerprint","locks":{"version":7},
  "locked":{"rev":"fixture-revision"},"resolvedUrl":"path:/workspace"
}`),
		},
		commandKey("eval", "--raw", "--impure", "--expr", "builtins.currentSystem"): {
			ExitCode: 0, Stdout: []byte("aarch64-darwin"),
		},
		commandKey(
			"eval", "--raw", "--no-write-lock-file",
			reference+"#devShells.aarch64-darwin.default.drvPath",
		): {ExitCode: 0, Stdout: []byte("/nix/store/environment.drv")},
	}
}

func environmentEnvelope(t *testing.T, operation string, input json.RawMessage) plugin.OperationEnvelope {
	t.Helper()
	workspace := t.TempDir()
	if err := os.WriteFile(filepath.Join(workspace, "flake.nix"), []byte("{}"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	workspace, err := filepath.EvalSymlinks(workspace)
	if err != nil {
		t.Fatalf("EvalSymlinks() returned %v", err)
	}
	workspaceState, err := workspaceFingerprint(workspace)
	if err != nil {
		t.Fatalf("workspaceFingerprint() returned %v", err)
	}
	handleID := domain.AdapterHandleID("environment-handle")
	handlePayload, _ := json.Marshal(handleValue{
		EnvironmentID: "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc",
		Workspace:     workspace, WorkspaceState: workspaceState,
		System: "aarch64-darwin", FlakeReference: "path:/workspace", Shell: "default",
		Derivation: "/nix/store/environment.drv", SnapshotDigest: fixtureSnapshotDigest,
	})
	handle := plugin.HandleDescriptor{
		ID: handleID, PluginID: "sysinit", Port: domain.AdapterPortEnvironment, AdapterID: AdapterID,
		FormatVersion: 2, OpaqueValue: handlePayload,
	}
	return plugin.OperationEnvelope{
		ID: domain.OperationID("operation-" + operation), AdapterID: AdapterID,
		Port: domain.AdapterPortEnvironment, Operation: operation,
		HandleID: &handleID, Handle: &handle, Input: input, Deadline: time.Now().Add(time.Minute),
	}
}

func newFixtureAdapter(t *testing.T, runner CommandRunner, secrets map[string]string) *Adapter {
	t.Helper()
	adapter, err := New(Config{
		Executable: "/fixture/nix", Directory: t.TempDir(),
		Environment: []string{"PATH=/fixture"}, Secrets: secrets,
	}, runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	return adapter
}

func validateAdapterResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
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

func containsEnvironment(environment []string, expected string) bool {
	for _, value := range environment {
		if value == expected {
			return true
		}
	}
	return false
}

func commandKey(arguments ...string) string {
	return strings.Join(arguments, "\x00")
}
