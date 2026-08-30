package broker

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
)

type fixtureAdapterRuntime struct {
	tracked       []plugin.HandleDescriptor
	lastPluginID  domain.PluginID
	lastOperation plugin.OperationEnvelope
}

type fixtureCapabilitySource map[string][]string

func (source fixtureCapabilitySource) AdapterCapabilities() map[string][]string {
	return source
}

func (runtime *fixtureAdapterRuntime) Invoke(
	_ context.Context,
	pluginID domain.PluginID,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	runtime.lastPluginID = pluginID
	runtime.lastOperation = envelope
	return plugin.OperationResult{
		ID: envelope.ID, State: domain.OperationStateSucceeded,
		Handle: &plugin.AdapterHandleValue{
			FormatVersion: 1, OpaqueValue: json.RawMessage(`{"provider":"fixture"}`),
		},
	}, nil
}

func TestPlanningCommandRequiresWorkflowExecution(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	adapters, err := NewAdapterService(store, runtime)
	if err != nil {
		t.Fatalf("NewAdapterService() returned %v", err)
	}
	sessions, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	executor, err := NewControlExecutor(store, adapters, sessions, fixtureCapabilitySource{})
	if err != nil {
		t.Fatalf("NewControlExecutor() returned %v", err)
	}
	payload := json.RawMessage(`{"pluginId":"planning-plugin","adapterId":"custom-planner","input":{}}`)
	_, err = executor.ExecuteCommandResult(ctx, socket.Principal{}, domain.CommandRequest{
		ID: "planning-command", Kind: "planning.discover", Payload: payload,
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("planning.discover error = %v", err)
	}
}

func TestGenericAdapterInvocationRejectsBrokerOwnedOperations(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	adapters, err := NewAdapterService(store, runtime)
	if err != nil {
		t.Fatalf("NewAdapterService() returned %v", err)
	}
	sessions, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	executor, err := NewControlExecutor(store, adapters, sessions, fixtureCapabilitySource{})
	if err != nil {
		t.Fatalf("NewControlExecutor() returned %v", err)
	}
	payload, err := json.Marshal(adapterCommand{
		PluginID: "sysinit",
		Operation: plugin.OperationEnvelope{
			ID: "unsafe-operation", AdapterID: "nix", Port: domain.AdapterPortEnvironment,
			Operation: "environment.execute", Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
		},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	_, err = executor.ExecuteCommandResult(ctx, socket.Principal{}, domain.CommandRequest{
		ID: "unsafe-command", Kind: "adapter.invoke", Payload: payload,
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("adapter.invoke error = %v", err)
	}
}

func (runtime *fixtureAdapterRuntime) TrackHandle(
	_ domain.PluginID,
	handle plugin.HandleDescriptor,
) error {
	runtime.tracked = append(runtime.tracked, handle)
	return nil
}

func TestAdapterServicePersistsWorkspaceAndEnvironmentHandles(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	runtime := &fixtureAdapterRuntime{}
	service, err := NewAdapterService(store, runtime)
	if err != nil {
		t.Fatalf("NewAdapterService() returned %v", err)
	}
	for _, fixture := range []struct {
		handleID domain.AdapterHandleID
		port     domain.AdapterPort
		adapter  string
	}{
		{handleID: "workspace-handle", port: domain.AdapterPortWorkspace, adapter: "seshy-workspace"},
		{handleID: "environment-handle", port: domain.AdapterPortEnvironment, adapter: "nix-environment"},
	} {
		result, err := service.Invoke(ctx, AdapterInvocationRequest{
			PluginID: "sysinit", NewHandleID: &fixture.handleID,
			Owner: domain.ResourceReference{Kind: "workflow-run", ID: "run-fixture"},
			Operation: plugin.OperationEnvelope{
				ID:   domain.OperationID("operation-" + string(fixture.handleID)),
				Port: fixture.port, AdapterID: fixture.adapter, Operation: "fixture.create",
				Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
			},
		})
		if err != nil || result.Handle == nil || result.Handle.ID != fixture.handleID {
			t.Fatalf("Invoke(%s) = %#v, %v", fixture.port, result, err)
		}
	}
	handles, err := store.AdapterHandles(ctx)
	if err != nil || len(handles) != 2 || len(runtime.tracked) != 2 {
		t.Fatalf("AdapterHandles() = %#v, tracked = %#v, error = %v", handles, runtime.tracked, err)
	}
}

func TestControlExecutorCreatesAndInspectsWorkflow(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	adapters, err := NewAdapterService(store, runtime)
	if err != nil {
		t.Fatalf("NewAdapterService() returned %v", err)
	}
	sessions, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	executor, err := NewControlExecutor(
		store, adapters, sessions,
		fixtureCapabilitySource{"pi": {"structured-result", "live-input"}},
	)
	if err != nil {
		t.Fatalf("NewControlExecutor() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	createPayload, err := json.Marshal(workflowCreateCommand{
		DefinitionID: "definition-control", Document: document,
	})
	if err != nil {
		t.Fatalf("Marshal(create) returned %v", err)
	}
	principal := socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}
	if _, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-create", Kind: "workflow.create", Payload: createPayload,
	}); err != nil {
		t.Fatalf("workflow.create returned %v", err)
	}
	runPayload, err := json.Marshal(workflowRunCommand{
		RunID: "run-control", DefinitionID: "definition-control",
	})
	if err != nil {
		t.Fatalf("Marshal(run) returned %v", err)
	}
	if _, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-run", Kind: "workflow.run", Payload: runPayload,
	}); err != nil {
		t.Fatalf("workflow.run returned %v", err)
	}
	scheduled, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-schedule", Kind: "workflow.schedule",
		Payload: json.RawMessage(`{"runId":"run-control","adapterCapacity":{"pi":1}}`),
	})
	if err != nil || !strings.Contains(string(scheduled), `"state":"running"`) {
		t.Fatalf("workflow.schedule = %s, %v", scheduled, err)
	}
	workspace := t.TempDir()
	if err := os.WriteFile(filepath.Join(workspace, "state.txt"), []byte("restart"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-control", "workspace-control", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	restartPayload, err := json.Marshal(sqlite.RestartPointRequest{
		ID: "restart-control", Kind: domain.RestartPointRunAdmission,
		WorkflowRunID: "run-control", SnapshotID: "snapshot-control", AdmissionIDs: []domain.AdmissionID{},
		CheckpointIDs: []domain.CheckpointID{},
	})
	if err != nil {
		t.Fatalf("Marshal(restart) returned %v", err)
	}
	restart, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-restart", Kind: "workflow.restart-point", Payload: restartPayload,
	})
	if err != nil || !strings.Contains(string(restart), `"id":"restart-control"`) {
		t.Fatalf("workflow.restart-point = %s, %v", restart, err)
	}
	restartPoints, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-restart-list", Kind: "workflow.restart-points",
		Payload: json.RawMessage(`{"runId":"run-control"}`),
	})
	if err != nil || !strings.Contains(string(restartPoints), `"id":"restart-control"`) {
		t.Fatalf("workflow.restart-points = %s, %v", restartPoints, err)
	}
	forks, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-fork-list", Kind: "workflow.forks",
		Payload: json.RawMessage(`{"runId":"run-control"}`),
	})
	if err != nil || string(forks) != "[]" {
		t.Fatalf("workflow.forks = %s, %v", forks, err)
	}
	workers, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-agent-list", Kind: "agent.list", Payload: json.RawMessage(`{}`),
	})
	if err != nil || string(workers) != "[]" {
		t.Fatalf("agent.list = %s, %v", workers, err)
	}
	result, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-inspect", Kind: "workflow.inspect",
		Payload: json.RawMessage(`{"runId":"run-control"}`),
	})
	if err != nil || !strings.Contains(string(result), `"id":"run-control"`) ||
		!strings.Contains(string(result), `"nodeKey":"implement"`) ||
		!strings.Contains(string(result), `"definitionVersion":1`) {
		t.Fatalf("workflow.inspect = %s, %v", result, err)
	}
	runs, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-list", Kind: "workflow.list", Payload: json.RawMessage(`{}`),
	})
	if err != nil || !strings.Contains(string(runs), `"id":"run-control"`) {
		t.Fatalf("workflow.list = %s, %v", runs, err)
	}
	current, _, err := store.WorkflowRun(ctx, "run-control")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	pausePayload := json.RawMessage(`{
		"id":"pause-control",
		"runId":"run-control",
		"cause":{
			"kind":"owner_input",
			"evidence":[{"kind":"workflow-run","id":"run-control"}],
			"allowedActions":["resume","cancel"],
			"recommendedAction":"resume"
		}
	}`)
	pauseVersion := current.Metadata.ResourceVersion
	paused, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-pause", Kind: "workflow.pause", ExpectedVersion: &pauseVersion, Payload: pausePayload,
	})
	if err != nil || !strings.Contains(string(paused), `"activePauseId":"pause-control"`) {
		t.Fatalf("workflow.pause = %s, %v", paused, err)
	}
	current, _, err = store.WorkflowRun(ctx, "run-control")
	if err != nil {
		t.Fatalf("paused WorkflowRun() returned %v", err)
	}
	resumeVersion := current.Metadata.ResourceVersion
	resumed, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-resume", Kind: "workflow.resume", ExpectedVersion: &resumeVersion,
		Payload: json.RawMessage(`{"id":"resume-control","runId":"run-control","pauseId":"pause-control"}`),
	})
	if err != nil || strings.Contains(string(resumed), `"activePauseId"`) {
		t.Fatalf("workflow.resume = %s, %v", resumed, err)
	}
	current, _, err = store.WorkflowRun(ctx, "run-control")
	if err != nil {
		t.Fatalf("resumed WorkflowRun() returned %v", err)
	}
	branchPayload, err := json.Marshal(replayCommand{
		ID: "fork-control", ParentWorkflowRunID: current.ID, ChildWorkflowRunID: "run-control-child",
		RestartPointID: "restart-control", TargetDefinitionID: current.WorkflowDefinition,
		TargetDefinitionVersion: current.DefinitionVersion,
		ExpectedParentVersion:   current.Metadata.ResourceVersion,
	})
	if err != nil {
		t.Fatalf("Marshal(branch) returned %v", err)
	}
	branched, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-branch", Kind: "workflow.branch", Payload: branchPayload,
	})
	if err != nil || !strings.Contains(string(branched), `"id":"run-control-child"`) {
		t.Fatalf("workflow.branch = %s, %v", branched, err)
	}
	if _, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-replay-removed", Kind: "workflow.replay", Payload: branchPayload,
	}); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("workflow.replay error = %v", err)
	}
	provenance, err := executor.ExecuteCommandResult(ctx, principal, domain.CommandRequest{
		ID: "command-provenance", Kind: "provenance.inspect", Payload: json.RawMessage(`{}`),
	})
	if err != nil || !strings.Contains(string(provenance), `"commitObservations"`) {
		t.Fatalf("provenance.inspect = %s, %v", provenance, err)
	}
}

func TestCommandServiceReservesTerminalEventCapacity(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxEventsPerSecond = 2
	store, err := sqlite.OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	executionErr := errors.New("injected execution failure")
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		return executionErr
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	record, err := service.HandleCommand(ctx, socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}, domain.CommandRequest{
		ID: "command-budget", IdempotencyKey: "request-budget", Kind: "unsupported", Payload: json.RawMessage(`{}`),
	})
	if !errors.Is(err, executionErr) {
		t.Fatalf("HandleCommand() error = %v", err)
	}
	if record.State != domain.CommandStateFailed {
		t.Fatalf("HandleCommand() state = %q", record.State)
	}
}

func TestCommandServicePersistsTypedResult(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	service, err := NewCommandService(store, CommandResultExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) (json.RawMessage, error) {
		return json.RawMessage(`{"workflowRunId":"run-1"}`), nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	record, err := service.HandleCommand(
		ctx,
		socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner},
		domain.CommandRequest{
			ID: "command-result", IdempotencyKey: "request-result",
			Kind: "workflow.inspect", Payload: json.RawMessage(`{}`),
		},
	)
	if err != nil || string(record.Result) != `{"workflowRunId":"run-1"}` {
		t.Fatalf("HandleCommand() = %#v, %v", record, err)
	}
}

func TestCommandServiceQueriesDoNotPersistCommands(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	service, err := NewCommandService(store, CommandResultExecutorFunc(func(
		_ context.Context,
		_ socket.Principal,
		request domain.CommandRequest,
	) (json.RawMessage, error) {
		return json.Marshal(map[string]string{"kind": request.Kind})
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	before, err := store.Inspect(ctx)
	if err != nil {
		t.Fatalf("Inspect(before) returned %v", err)
	}
	result, err := service.HandleQuery(ctx, socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}, socket.QueryRequest{
		Kind: "workflow.list", Payload: json.RawMessage(`{}`),
	})
	if err != nil || !strings.Contains(string(result), `"kind":"workflow.list"`) {
		t.Fatalf("HandleQuery() = %s, %v", result, err)
	}
	after, err := store.Inspect(ctx)
	if err != nil {
		t.Fatalf("Inspect(after) returned %v", err)
	}
	if before.LastEventCursor != after.LastEventCursor || !reflect.DeepEqual(before.Tables, after.Tables) {
		t.Fatalf("query changed durable state: before=%#v after=%#v", before, after)
	}
	_, err = service.HandleQuery(ctx, socket.Principal{}, socket.QueryRequest{
		Kind: "workflow.run", Payload: json.RawMessage(`{}`),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("mutating query error = %v", err)
	}
}

func TestCommandServicePersistsIndeterminateExecution(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	executionErr := &domain.Error{
		Code: domain.ErrorCodeIndeterminate, Op: "dispatch", Resource: "remote effect",
		Message: "completion is unknown",
	}
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		return executionErr
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	record, err := service.HandleCommand(
		ctx,
		socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner},
		domain.CommandRequest{
			ID: "command-indeterminate-effect", IdempotencyKey: "request-indeterminate-effect",
			Kind: "effect.push", Payload: json.RawMessage(`{}`),
		},
	)
	if !errors.Is(err, executionErr) {
		t.Fatalf("HandleCommand() error = %v", err)
	}
	if record.State != domain.CommandStateIndeterminate {
		t.Fatalf("HandleCommand() state = %q", record.State)
	}
}

func TestCommandServicePersistsSuccessAfterClientCancellation(t *testing.T) {
	t.Parallel()

	ctx, cancel := context.WithCancel(context.Background())
	store, err := sqlite.Open(context.Background(), filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		cancel()
		return nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	record, err := service.HandleCommand(ctx, socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}, domain.CommandRequest{
		ID: "command-cancel", IdempotencyKey: "request-cancel", Kind: "event.append", Payload: json.RawMessage(`{}`),
	})
	if err != nil {
		t.Fatalf("HandleCommand() returned %v", err)
	}
	if record.State != domain.CommandStateSucceeded {
		t.Fatalf("HandleCommand() state = %q", record.State)
	}
}

func TestCommandServiceWaitsForTerminalPersistence(t *testing.T) {
	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	transactionStarted := make(chan struct{})
	releaseTransaction := make(chan struct{})
	transactionDone := make(chan error, 1)
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		go func() {
			transactionDone <- store.Transaction(ctx, func(*sqlite.Tx) error {
				close(transactionStarted)
				<-releaseTransaction
				return nil
			})
		}()
		<-transactionStarted
		return nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	type result struct {
		record domain.CommandRecord
		err    error
	}
	commandDone := make(chan result, 1)
	go func() {
		record, err := service.HandleCommand(
			ctx,
			socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner},
			domain.CommandRequest{
				ID: "command-terminal-wait", IdempotencyKey: "request-terminal-wait",
				Kind: "event.append", Payload: json.RawMessage(`{}`),
			},
		)
		commandDone <- result{record: record, err: err}
	}()
	select {
	case completed := <-commandDone:
		close(releaseTransaction)
		t.Fatalf("HandleCommand() completed before persistence was available: %#v", completed)
	case <-time.After(100 * time.Millisecond):
	}
	close(releaseTransaction)
	if err := <-transactionDone; err != nil {
		t.Fatalf("Transaction() returned %v", err)
	}
	select {
	case completed := <-commandDone:
		if completed.err != nil {
			t.Fatalf("HandleCommand() returned %v", completed.err)
		}
		if completed.record.State != domain.CommandStateSucceeded {
			t.Fatalf("HandleCommand() state = %q", completed.record.State)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("HandleCommand() did not persist its terminal state")
	}
}

func TestCommandServiceDeduplicatesAcrossRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	principal := socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}
	request := domain.CommandRequest{
		ID:             "command-1",
		IdempotencyKey: "request-1",
		Kind:           "workflow.patch",
		Payload:        json.RawMessage(`{"edge":"build-to-test"}`),
	}
	store, err := sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	firstExecutions := 0
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		firstExecutions++
		return nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	first, err := service.HandleCommand(ctx, principal, request)
	if err != nil {
		t.Fatalf("HandleCommand() returned %v", err)
	}
	second, err := service.HandleCommand(ctx, principal, request)
	if err != nil {
		t.Fatalf("second HandleCommand() returned %v", err)
	}
	if firstExecutions != 1 || first.ID != second.ID || first.Metadata != second.Metadata {
		t.Fatalf("duplicate result = %#v, %#v after %d executions", first, second, firstExecutions)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	restartExecutions := 0
	service, err = NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		restartExecutions++
		return nil
	}))
	if err != nil {
		t.Fatalf("second NewCommandService() returned %v", err)
	}
	replayed, err := service.HandleCommand(ctx, principal, request)
	if err != nil {
		t.Fatalf("replayed HandleCommand() returned %v", err)
	}
	if restartExecutions != 0 || replayed.ID != first.ID || replayed.Metadata != first.Metadata {
		t.Fatalf("restart result = %#v after %d executions", replayed, restartExecutions)
	}

	conflict := request
	conflict.ID = "command-2"
	if _, err := service.HandleCommand(ctx, principal, conflict); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("conflicting HandleCommand() error = %v", err)
	}
}

func TestCommandServiceClaimsAcceptedCommandAfterRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	principal := socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}
	request := domain.CommandRequest{
		ID:             "command-recovery",
		IdempotencyKey: "request-recovery",
		Kind:           "workflow.patch",
		Payload:        json.RawMessage(`{"edge":"build-to-judge"}`),
	}
	store, err := sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if _, created, err := store.AcceptCommand(ctx, principal.Identifier(), request); err != nil || !created {
		t.Fatalf("AcceptCommand() = created %t, error %v", created, err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	executions := 0
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		executions++
		return nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	record, err := service.HandleCommand(ctx, principal, request)
	if err != nil {
		t.Fatalf("HandleCommand() returned %v", err)
	}
	if executions != 1 || record.State != domain.CommandStateSucceeded {
		t.Fatalf("HandleCommand() state = %q after %d executions", record.State, executions)
	}
}

func TestCommandServiceMarksRunningCommandIndeterminateAfterRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	principal := socket.Principal{UID: 501, Role: socket.PrincipalRoleOwner}
	request := domain.CommandRequest{
		ID:             "command-indeterminate",
		IdempotencyKey: "request-indeterminate",
		Kind:           "workflow.patch",
		Payload:        json.RawMessage(`{"edge":"judge-to-test"}`),
	}
	store, err := sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	if _, created, err := store.AcceptCommand(ctx, principal.Identifier(), request); err != nil || !created {
		t.Fatalf("AcceptCommand() = created %t, error %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, request.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand() = claimed %t, error %v", claimed, err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = sqlite.Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	executions := 0
	service, err := NewCommandService(store, CommandExecutorFunc(func(
		context.Context,
		socket.Principal,
		domain.CommandRequest,
	) error {
		executions++
		return nil
	}))
	if err != nil {
		t.Fatalf("NewCommandService() returned %v", err)
	}
	if err := service.RecoverInterruptedCommands(ctx); err != nil {
		t.Fatalf("RecoverInterruptedCommands() returned %v", err)
	}
	record, err := service.HandleCommand(ctx, principal, request)
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("HandleCommand() error = %v", err)
	}
	if executions != 0 || record.State != domain.CommandStateIndeterminate {
		t.Fatalf("HandleCommand() state = %q after %d executions", record.State, executions)
	}
}
