package openspec

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	resultmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/result"
)

type fixtureRunner struct {
	responses map[string]json.RawMessage
	errors    map[string]error
	calls     []string
}

func (runner *fixtureRunner) RunJSON(_ context.Context, arguments ...string) (json.RawMessage, error) {
	key := strings.Join(arguments, "\x00")
	runner.calls = append(runner.calls, key)
	if err := runner.errors[key]; err != nil {
		return nil, err
	}
	payload, found := runner.responses[key]
	if !found {
		return nil, adapterError(domain.ErrorCodeNotFound, "fixture command", key, "response is missing", nil)
	}
	return append(json.RawMessage(nil), payload...), nil
}

func TestDiscoverPreservesDeclaredAndTemplateArtifacts(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]json.RawMessage{
		commandKey("schemas", "--json"): json.RawMessage(`[
  {"name":"shape-flow","description":"graph schema","artifacts":["checks","brief"],"source":"user","future":{"mode":"graph"}},
  {"name":"taskless","description":"artifact only","artifacts":["memo"],"source":"package"}
]`),
		commandKey("templates", "--schema", "shape-flow", "--json"): json.RawMessage(`{
  "brief":{"path":"/schema/brief.md","source":"user"}
}`),
		commandKey("schema", "which", "shape-flow", "--json"): json.RawMessage(`{
  "name":"shape-flow","source":"user","path":"/schemas/shape-flow","unknownResolution":true
}`),
		commandKey("templates", "--schema", "taskless", "--json"): json.RawMessage(`{
  "memo":{"path":"/schema/memo.md","source":"package"}
}`),
		commandKey("schema", "which", "taskless", "--json"): json.RawMessage(`{
  "name":"taskless","source":"package","path":"/schemas/taskless"
}`),
	}}
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	result, err := adapter.Discover(context.Background())
	if err != nil {
		t.Fatalf("Discover() returned %v", err)
	}
	if len(result.Schemas) != 2 || result.Schemas[0].ID != "shape-flow" ||
		strings.Join(result.Schemas[0].DeclaredArtifacts, ",") != "brief,checks" ||
		strings.Join(result.Schemas[0].TemplateArtifacts, ",") != "brief" {
		t.Fatalf("discovery = %#v", result)
	}
	if !strings.Contains(string(result.Schemas[0].OpaqueSourceData), `"future":{"mode":"graph"}`) ||
		!strings.Contains(string(result.Schemas[0].OpaqueSourceData), `"unknownResolution":true`) {
		t.Fatalf("opaque schema data = %s", result.Schemas[0].OpaqueSourceData)
	}
	if result.SourceDigest == "" || result.Schemas[0].SourceDigest == "" {
		t.Fatalf("source digests are empty: %#v", result)
	}
}

func TestSnapshotUsesSelectedSchemaOutputsWithoutArtifactAssumptions(t *testing.T) {
	t.Parallel()

	runner := snapshotFixtureRunner("shape-flow", true)
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	snapshot, err := adapter.Snapshot(context.Background(), SnapshotRequest{Change: "change-1"})
	if err != nil {
		t.Fatalf("Snapshot() returned %v", err)
	}
	if snapshot.SchemaID != "shape-flow" || len(snapshot.Artifacts) != 2 ||
		snapshot.Artifacts[0].ID != "intent" || snapshot.Artifacts[1].ID != "proof" {
		t.Fatalf("snapshot artifacts = %#v", snapshot.Artifacts)
	}
	if len(snapshot.WorkItems) != 1 || snapshot.WorkItems[0].ID != "work-alpha" ||
		!strings.Contains(string(snapshot.WorkItems[0].OpaqueData), `"runtimeHint":"pi"`) {
		t.Fatalf("snapshot work items = %#v", snapshot.WorkItems)
	}
	if len(snapshot.Context) != 2 || snapshot.Context[0].ArtifactID != "intent" ||
		!containsAction(snapshot.Actions, "apply") || !containsGate(snapshot.Gates, "implementation") {
		t.Fatalf("snapshot normalization = %#v", snapshot)
	}
	if strings.Contains(string(snapshot.OpaqueSourceData), `proposal.md`) ||
		!strings.Contains(string(snapshot.OpaqueSourceData), `"futureStatus":{"value":7}`) {
		t.Fatalf("snapshot opaque source = %s", snapshot.OpaqueSourceData)
	}
}

func TestSnapshotDoesNotInventTasksForTasklessSchema(t *testing.T) {
	t.Parallel()

	runner := snapshotFixtureRunner("taskless", false)
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	snapshot, err := adapter.Snapshot(context.Background(), SnapshotRequest{Change: "change-1"})
	if err != nil {
		t.Fatalf("Snapshot() returned %v", err)
	}
	if snapshot.SchemaID != "taskless" || len(snapshot.WorkItems) != 0 ||
		containsGate(snapshot.Gates, "implementation") {
		t.Fatalf("taskless snapshot = %#v", snapshot)
	}
	if len(snapshot.Artifacts) != 1 || snapshot.Artifacts[0].ID != "memo" {
		t.Fatalf("taskless artifacts = %#v", snapshot.Artifacts)
	}
}

func TestSnapshotOmitsUnavailableLifecycleActions(t *testing.T) {
	t.Parallel()

	runner := &fixtureRunner{responses: map[string]json.RawMessage{
		commandKey("status", "--change", "change-1", "--json"): json.RawMessage(`{
  "changeName":"change-1","schemaName":"artifact-only",
  "artifactPaths":{"memo":{"outputPath":"memo.txt"}},
  "artifacts":[{"id":"memo","outputPath":"memo.txt","status":"ready","requires":[]}]
}`),
	}}
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	snapshot, err := adapter.Snapshot(context.Background(), SnapshotRequest{Change: "change-1"})
	if err != nil {
		t.Fatalf("Snapshot() returned %v", err)
	}
	if !containsAction(snapshot.Actions, "memo") || containsAction(snapshot.Actions, "apply") ||
		containsAction(snapshot.Actions, "archive") {
		t.Fatalf("snapshot actions = %#v", snapshot.Actions)
	}
}

func TestSnapshotReturnsLifecycleActionFailure(t *testing.T) {
	t.Parallel()

	runner := snapshotFixtureRunner("taskless", false)
	runner.errors = map[string]error{
		commandKey("instructions", "apply", "--change", "change-1", "--json"): adapterError(
			domain.ErrorCodeInternal, "fixture command", "apply", "instruction failed", nil,
		),
	}
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	_, err = adapter.Snapshot(context.Background(), SnapshotRequest{Change: "change-1"})
	if !domain.IsErrorCode(err, domain.ErrorCodeInternal) {
		t.Fatalf("Snapshot() returned %v", err)
	}
}

func TestActionUsesStatusAndNamedInstructionOutput(t *testing.T) {
	t.Parallel()

	runner := snapshotFixtureRunner("taskless", false)
	runner.responses[commandKey("instructions", "memo", "--change", "change-1", "--json")] = json.RawMessage(`{
  "changeName":"change-1","artifactId":"memo","schemaName":"taskless",
  "description":"Write the memo","instruction":"Use the selected schema template.",
  "outputPath":"memo.txt","resolvedOutputPath":"/change/memo.txt",
  "dependencies":[],"unlocks":["publish"],"contextFiles":{"memo":["/change/source.txt"]},
  "futureInstruction":{"owner":"local"}
}`)
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	result, err := adapter.Action(context.Background(), ActionRequest{Change: "change-1", Action: "memo"})
	if err != nil {
		t.Fatalf("Action() returned %v", err)
	}
	if result.SchemaID != "taskless" || result.Action != "memo" || result.OutputPath != "memo.txt" ||
		len(result.Context) != 1 || len(result.WorkItems) != 0 {
		t.Fatalf("action result = %#v", result)
	}
	if !strings.Contains(string(result.OpaqueSourceData), `"futureInstruction":{"owner":"local"}`) {
		t.Fatalf("action opaque source = %s", result.OpaqueSourceData)
	}
}

func TestInvokeRejectsUnknownRequestFields(t *testing.T) {
	t.Parallel()

	adapter, err := New(&fixtureRunner{responses: map[string]json.RawMessage{}})
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	_, err = adapter.Invoke(
		context.Background(), OperationSnapshot,
		json.RawMessage(`{"change":"change-1","schema":"hard-coded"}`),
	)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("Invoke() error = %v", err)
	}
}

func TestManifestValidatesAdapterResponses(t *testing.T) {
	t.Parallel()

	manifest, err := Manifest()
	if err != nil {
		t.Fatalf("Manifest() returned %v", err)
	}
	if manifest.ID != FrameworkID || manifest.Port != domain.AdapterPortPlanning || len(manifest.Operations) != 3 {
		t.Fatalf("manifest = %#v", manifest)
	}
	for operation, contract := range manifest.Operations {
		if err := plugin.ValidateSchemaContract(operation, contract); err != nil {
			t.Fatalf("ValidateSchemaContract(%q) returned %v", operation, err)
		}
	}

	runner := snapshotFixtureRunner("shape-flow", true)
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	output, err := adapter.Invoke(
		context.Background(), OperationSnapshot, json.RawMessage(`{"change":"change-1"}`),
	)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	contract := manifest.Operations[OperationSnapshot]
	validator, err := resultmodel.NewValidator(
		contract.ResponseSchema, contract.ResponseSchemaDigest, 0, uint64(len(output)),
	)
	if err != nil {
		t.Fatalf("NewValidator() returned %v", err)
	}
	if decision := validator.Validate(output, 0); !decision.Accepted {
		t.Fatalf("snapshot response rejected: %#v", decision)
	}
}

func TestCLIRunnerBoundsAndValidatesOutput(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := filepath.Join(directory, "fixture-openspec")
	if err := os.WriteFile(
		executable,
		[]byte("#!/bin/sh\nprintf '%s' '{\"schema\":\"custom\"}'\n"),
		0o700,
	); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	runner, err := NewCLIRunner(executable, directory, 128)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	payload, err := runner.RunJSON(context.Background(), "schemas", "--json")
	if err != nil {
		t.Fatalf("RunJSON() returned %v", err)
	}
	if string(payload) != `{"schema":"custom"}` {
		t.Fatalf("payload = %s", payload)
	}

	bounded, err := NewCLIRunner(executable, directory, 4)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	_, err = bounded.RunJSON(context.Background(), "schemas", "--json")
	if !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) {
		t.Fatalf("bounded RunJSON() error = %v", err)
	}
}

func TestCLIRunnerPreservesFailureEvidence(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := filepath.Join(directory, "failing-openspec")
	if err := os.WriteFile(
		executable,
		[]byte("#!/bin/sh\nprintf '%s' 'schema missing' >&2\nexit 7\n"),
		0o700,
	); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	runner, err := NewCLIRunner(executable, directory, 128)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	_, err = runner.RunJSON(context.Background(), "status", "--json")
	if !domain.IsErrorCode(err, domain.ErrorCodeInternal) || !strings.Contains(err.Error(), "schema missing") {
		t.Fatalf("RunJSON() error = %v", err)
	}
}

func TestCLIRunnerClassifiesUnavailableInstruction(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := filepath.Join(directory, "taskless-openspec")
	if err := os.WriteFile(
		executable,
		[]byte("#!/bin/sh\nprintf '%s' '{\"status\":[{\"severity\":\"error\",\"code\":\"change_error\",\"message\":\"Artifact '\"'$2'\"' not found in schema '\"'taskless'\"'\"}]}'\nexit 1\n"),
		0o700,
	); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	runner, err := NewCLIRunner(executable, directory, 1024)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	_, err = runner.RunJSON(context.Background(), "instructions", "apply", "--change", "change-1", "--json")
	if !domain.IsErrorCode(err, domain.ErrorCodeNotFound) {
		t.Fatalf("RunJSON() returned %v", err)
	}
}

func TestCLIRunnerCancellationTerminatesChildProcess(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := filepath.Join(directory, "forking-openspec")
	if err := os.WriteFile(
		executable,
		[]byte("#!/bin/sh\nsleep 30 &\nchild=$!\nprintf '%s' \"$child\" > child.pid\nwait \"$child\"\n"),
		0o700,
	); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	runner, err := NewCLIRunner(executable, directory, 128)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	result := make(chan error, 1)
	go func() {
		_, runErr := runner.RunJSON(ctx, "status", "--json")
		result <- runErr
	}()
	pidPath := filepath.Join(directory, "child.pid")
	var childPID int
	deadline := time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		payload, readErr := os.ReadFile(pidPath)
		if readErr == nil {
			value := strings.TrimSpace(string(payload))
			if value == "" {
				time.Sleep(10 * time.Millisecond)
				continue
			}
			childPID, err = strconv.Atoi(value)
			if err != nil || childPID <= 0 {
				t.Fatalf("child PID %q is invalid: %v", value, err)
			}
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	if childPID == 0 {
		t.Fatal("child process did not report its PID")
	}
	cancel()
	if err := <-result; err == nil {
		t.Fatal("RunJSON() accepted a cancelled command")
	}
	deadline = time.Now().Add(5 * time.Second)
	for time.Now().Before(deadline) {
		if err := syscall.Kill(childPID, 0); err == syscall.ESRCH {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("child process %d survived cancellation", childPID)
}

func TestCLIRunnerReadsSelectedOpenSpecSchema(t *testing.T) {
	change := os.Getenv("COLCHIS_TEST_OPENSPEC_CHANGE")
	if change == "" {
		t.Skip("COLCHIS_TEST_OPENSPEC_CHANGE is unset")
	}
	executable, err := exec.LookPath("openspec")
	if err != nil {
		t.Fatalf("LookPath() returned %v", err)
	}
	directory, err := os.Getwd()
	if err != nil {
		t.Fatalf("Getwd() returned %v", err)
	}
	runner, err := NewCLIRunner(executable, directory, 0)
	if err != nil {
		t.Fatalf("NewCLIRunner() returned %v", err)
	}
	adapter, err := New(runner)
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	snapshot, err := adapter.Snapshot(context.Background(), SnapshotRequest{Change: change})
	if err != nil {
		t.Fatalf("Snapshot() returned %v", err)
	}
	if snapshot.Change != change || snapshot.SchemaID == "" || snapshot.SourceDigest == "" {
		t.Fatalf("snapshot identity = %#v", snapshot)
	}
}

func snapshotFixtureRunner(schema string, withTasks bool) *fixtureRunner {
	status := json.RawMessage(`{
  "changeName":"change-1","schemaName":"shape-flow",
  "artifactPaths":{
    "intent":{"outputPath":"intent.txt","resolvedOutputPath":"/change/intent.txt","existingOutputPaths":["/change/intent.txt"]},
    "proof":{"outputPath":"proof/**/*.txt","resolvedOutputPath":"/change/proof/**/*.txt","existingOutputPaths":["/change/proof/a.txt"]}
  },
  "isPlanningComplete":true,"isComplete":true,"applyRequires":["proof"],
  "actionContext":{"requiresAffectedAreaSelection":true,"constraints":["Select one area."]},
  "artifacts":[
    {"id":"intent","outputPath":"intent.txt","status":"done","requires":[]},
    {"id":"proof","outputPath":"proof/**/*.txt","status":"ready","requires":["intent"]}
  ],
  "futureStatus":{"value":7}
}`)
	apply := json.RawMessage(`{
  "changeName":"change-1","schemaName":"shape-flow",
  "contextFiles":{"intent":["/change/intent.txt"],"proof":["/change/proof/a.txt"]},
  "progress":{"total":1,"complete":0,"remaining":1},
  "tasks":[{"id":"work-alpha","description":"Run the proof","done":false,"runtimeHint":"pi"}],
  "state":"ready","instruction":"Apply the selected schema."
}`)
	if schema == "taskless" {
		status = json.RawMessage(`{
  "changeName":"change-1","schemaName":"taskless",
  "artifactPaths":{"memo":{"outputPath":"memo.txt","resolvedOutputPath":"/change/memo.txt","existingOutputPaths":["/change/memo.txt"]}},
  "isPlanningComplete":true,"isComplete":true,"applyRequires":[],
  "actionContext":{"requiresAffectedAreaSelection":false,"constraints":[]},
  "artifacts":[{"id":"memo","outputPath":"memo.txt","status":"done","requires":[]}]
}`)
		apply = json.RawMessage(`{
  "changeName":"change-1","schemaName":"taskless",
  "contextFiles":{"memo":["/change/memo.txt"]},"state":"ready",
  "instruction":"Follow the artifact actions."
}`)
	} else if !withTasks {
		apply = json.RawMessage(`{"changeName":"change-1","schemaName":"shape-flow","contextFiles":{}}`)
	}
	return &fixtureRunner{responses: map[string]json.RawMessage{
		commandKey("status", "--change", "change-1", "--json"):                status,
		commandKey("instructions", "apply", "--change", "change-1", "--json"): apply,
	}}
}

func commandKey(arguments ...string) string {
	return strings.Join(arguments, "\x00")
}

func containsAction(actions []Action, id string) bool {
	for _, action := range actions {
		if action.ID == id {
			return true
		}
	}
	return false
}

func containsGate(gates []Gate, id string) bool {
	for _, gate := range gates {
		if gate.ID == id {
			return true
		}
	}
	return false
}
