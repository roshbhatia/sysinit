package broker

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

type fixtureSessionRuntime struct {
	invoke       func(context.Context, domain.PluginID, plugin.OperationEnvelope) (plugin.OperationResult, error)
	cancel       func(context.Context, domain.PluginID, plugin.CancelParams) error
	reconcile    func(context.Context, domain.PluginID, []plugin.HandleDescriptor) ([]plugin.ReconcileResult, error)
	track        func(domain.PluginID, plugin.HandleDescriptor) error
	resolve      func(domain.AdapterPort, string) (domain.PluginID, []string, error)
	capabilities []string
}

func (runtime *fixtureSessionRuntime) ResolveAdapter(
	port domain.AdapterPort,
	adapterID string,
) (domain.PluginID, []string, error) {
	if runtime.resolve != nil {
		return runtime.resolve(port, adapterID)
	}
	selectedPlugin, resolvedAdapterID := domain.ParseAdapterSelector(adapterID)
	if selectedPlugin != "" && selectedPlugin != "pi-plugin" {
		return "", nil, &domain.Error{
			Code: domain.ErrorCodeNotFound, Resource: adapterID, Message: "fixture plugin does not exist",
		}
	}
	if port == domain.AdapterPortAttachment && resolvedAdapterID == "pi.attachment" {
		return "pi-plugin", []string{"attachment.native-event-stream"}, nil
	}
	if port != domain.AdapterPortAgentRuntime || resolvedAdapterID != "pi" {
		return "", nil, &domain.Error{
			Code: domain.ErrorCodeNotFound, Resource: adapterID, Message: "fixture adapter does not exist",
		}
	}
	return "pi-plugin", append([]string(nil), runtime.capabilities...), nil
}

func (runtime *fixtureSessionRuntime) Invoke(
	ctx context.Context,
	pluginID domain.PluginID,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	return runtime.invoke(ctx, pluginID, envelope)
}

func (runtime *fixtureSessionRuntime) Cancel(
	ctx context.Context,
	pluginID domain.PluginID,
	params plugin.CancelParams,
) error {
	return runtime.cancel(ctx, pluginID, params)
}

func (runtime *fixtureSessionRuntime) Reconcile(
	ctx context.Context,
	pluginID domain.PluginID,
	handles []plugin.HandleDescriptor,
) ([]plugin.ReconcileResult, error) {
	return runtime.reconcile(ctx, pluginID, handles)
}

func (runtime *fixtureSessionRuntime) TrackHandle(
	pluginID domain.PluginID,
	handle plugin.HandleDescriptor,
) error {
	return runtime.track(pluginID, handle)
}

func TestSessionServiceStoresPromptBeforeRuntimeDispatch(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-start")
	defer store.Close()
	prompt := []byte("Implement the selected stage.")
	digest := sha256.Sum256(prompt)
	promptID := domain.PromptArtifactID("prompt-" + fmt.Sprintf("%x", digest[:]))
	invocations := 0
	runtime := defaultFixtureSessionRuntime()
	var invokedPlugin domain.PluginID
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		invocations++
		invokedPlugin = pluginID
		if _, err := store.PromptArtifact(callContext, promptID); err != nil {
			return plugin.OperationResult{}, fmt.Errorf("prompt was unavailable before dispatch: %w", err)
		}
		if envelope.AdapterID != "pi" || envelope.JobPolicy == nil ||
			envelope.JobPolicy.Filesystem != domain.FilesystemPolicyWorkspaceWrite {
			return plugin.OperationResult{}, fmt.Errorf("job policy was not bound before dispatch: %#v", envelope.JobPolicy)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{"value":"started"}`),
			Handle: &plugin.AdapterHandleValue{
				FormatVersion: 1, OpaqueValue: json.RawMessage(`{"runtimeSession":"private"}`),
			},
		}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(ctx, startSessionTestRequest(node, "run-session-start", "session-start", prompt))
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if invocations != 1 || started.Session.State != domain.SessionStateRunning ||
		invokedPlugin != "pi-plugin" || started.Session.RuntimeAdapterID != "pi" ||
		started.Session.RuntimeHandle == nil || *started.Session.RuntimeHandle != started.Handle.ID ||
		started.Prompt.ID != promptID {
		t.Fatalf("started session = %#v after %d invocations", started, invocations)
	}
}

func TestSessionServiceRejectsRuntimeMissingPinnedCapability(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-capability")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	runtime.capabilities = []string{"job-policy"}
	invocations := 0
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		ctx context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		invocations++
		return baseInvoke(ctx, pluginID, envelope)
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	_, err = service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-capability", "session-capability", []byte("Start.")),
	)
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) || invocations != 0 {
		t.Fatalf("StartSession() error = %v after %d invocations", err, invocations)
	}
}

func TestSessionServicePersistsOneShotCompletion(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-one-shot")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	runtime.invoke = func(
		_ context.Context,
		_ domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			SessionState: domain.SessionStateCompleted,
			Output:       json.RawMessage(`{"status":"completed"}`),
			Handle: &plugin.AdapterHandleValue{
				FormatVersion: 1, OpaqueValue: json.RawMessage(`{"status":"completed"}`),
			},
		}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-one-shot", "session-one-shot", []byte("Run once.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if started.Session.State != domain.SessionStateCompleted || started.Session.ActiveOperationID != nil {
		t.Fatalf("one-shot session = %#v", started.Session)
	}
}

func TestSessionServiceRecordsInterventionBeforeForwarding(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-input")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-input", "session-input", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	runtime.invoke = func(
		callContext context.Context,
		_ domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		history, historyErr := store.SessionHistory(callContext, started.Session.ID)
		if historyErr != nil || len(history.Interventions) != 1 ||
			history.Interventions[0].State != domain.InterventionStateForwarded {
			return plugin.OperationResult{}, fmt.Errorf("intervention was not durable before dispatch: %#v, %w", history, historyErr)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{"value":"accepted"}`),
		}, nil
	}
	handleID := started.Handle.ID
	forwarded, err := service.ForwardIntervention(ctx, ForwardInterventionRequest{
		Intervention: sqlite.InterventionRequest{
			ID: "intervention-input", SessionID: started.Session.ID,
			Kind: domain.InterventionKindMessage, Payload: json.RawMessage(`{"text":"Use the smaller fix."}`),
			Source: "owner-terminal",
		},
		Operation: plugin.OperationEnvelope{
			ID: "operation-input", AdapterID: "pi", Port: domain.AdapterPortAgentRuntime,
			Operation: "agent-runtime.input", HandleID: &handleID,
			Input: json.RawMessage(`{"value":"Use the smaller fix."}`), Deadline: time.Now().Add(time.Minute),
		},
	})
	if err != nil {
		t.Fatalf("ForwardIntervention() returned %v", err)
	}
	if forwarded.Intervention.State != domain.InterventionStateCompleted || forwarded.Result == nil {
		t.Fatalf("forwarded intervention = %#v", forwarded)
	}
}

func TestSessionServiceRecordsAttachmentBeforeForwarding(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-attach")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-attach", "session-attach", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	runtime.invoke = func(
		callContext context.Context,
		_ domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		history, historyErr := store.SessionHistory(callContext, started.Session.ID)
		if historyErr != nil || len(history.Interventions) != 1 ||
			history.Interventions[0].State != domain.InterventionStateForwarded {
			return plugin.OperationResult{}, fmt.Errorf("attachment was not durable before dispatch: %#v, %w", history, historyErr)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{"attachmentId":"attachment-1","transport":"native-event-stream"}`),
		}, nil
	}
	attached, err := service.ForwardAttachment(ctx, ForwardAttachmentRequest{
		Intervention: sqlite.InterventionRequest{
			ID: "intervention-attach", SessionID: started.Session.ID,
			Kind: domain.InterventionKindAttach, Payload: json.RawMessage(`{"cursor":0}`),
			Source: "owner-terminal",
		},
		PluginID: "pi-plugin",
		Operation: plugin.OperationEnvelope{
			ID: "operation-attach", AdapterID: "pi.attachment", Port: domain.AdapterPortAttachment,
			Operation: "attachment.open", Input: json.RawMessage(`{"sessionId":"session-attach","cursor":0}`),
			Deadline: time.Now().Add(time.Minute),
		},
	})
	if err != nil {
		t.Fatalf("ForwardAttachment() returned %v", err)
	}
	if attached.Intervention.State != domain.InterventionStateCompleted ||
		!strings.Contains(string(attached.Result.Output), `"attachmentId":"attachment-1"`) {
		t.Fatalf("attachment result = %#v", attached)
	}
	for _, test := range []struct {
		name     string
		pluginID domain.PluginID
		input    json.RawMessage
	}{
		{name: "other plugin", pluginID: "other-plugin", input: json.RawMessage(`{"sessionId":"session-attach"}`)},
		{name: "other session", pluginID: "pi-plugin", input: json.RawMessage(`{"sessionId":"session-other"}`)},
	} {
		t.Run(test.name, func(t *testing.T) {
			_, err := service.ForwardAttachment(ctx, ForwardAttachmentRequest{
				Intervention: sqlite.InterventionRequest{
					ID:        domain.InterventionID("intervention-attach-" + strings.ReplaceAll(test.name, " ", "-")),
					SessionID: started.Session.ID, Kind: domain.InterventionKindAttach,
					Payload: json.RawMessage(`{}`), Source: "owner-terminal",
				},
				PluginID: test.pluginID,
				Operation: plugin.OperationEnvelope{
					ID:        domain.OperationID("operation-attach-" + strings.ReplaceAll(test.name, " ", "-")),
					AdapterID: "pi.attachment", Port: domain.AdapterPortAttachment,
					Operation: "attachment.open", Input: test.input, Deadline: time.Now().Add(time.Minute),
				},
			})
			if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
				t.Fatalf("ForwardAttachment() error = %v", err)
			}
		})
	}
}

func TestSessionServiceRecordsUnsupportedPolicyChange(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-policy")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-policy", "session-policy", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	invoked := false
	runtime.invoke = func(
		context.Context,
		domain.PluginID,
		plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		invoked = true
		return plugin.OperationResult{}, errors.New("policy operation must not run")
	}
	policy := domain.JobPolicy{
		Approvals:  domain.ApprovalPolicyNever,
		Filesystem: domain.FilesystemPolicyDangerFullAccess,
		Network:    domain.NetworkPolicyAllow,
	}
	handleID := started.Handle.ID
	result, err := service.ForwardIntervention(ctx, ForwardInterventionRequest{
		Intervention: sqlite.InterventionRequest{
			ID: "intervention-policy", SessionID: started.Session.ID,
			Kind: domain.InterventionKindPolicy, Payload: json.RawMessage(`{"reason":"owner override"}`),
			Source: "owner-terminal",
		},
		Operation: plugin.OperationEnvelope{
			ID: "operation-policy", AdapterID: "pi", Port: domain.AdapterPortAgentRuntime,
			Operation: "agent-runtime.policy", HandleID: &handleID, JobPolicy: &policy,
			Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
		},
	})
	if err == nil || !strings.Contains(err.Error(), "requires a new attempt or replay") || invoked {
		t.Fatalf("ForwardIntervention() result = %#v, invoked = %t, error = %v", result, invoked, err)
	}
	if result.Intervention.State != domain.InterventionStateFailed {
		t.Fatalf("policy intervention = %#v", result.Intervention)
	}
}

func TestSessionServiceForwardsSupportedPolicyChange(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-policy-update")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(
		node, "run-session-policy-update", "session-policy-update", []byte("Start."),
	)
	runtime.capabilities = append(runtime.capabilities, "policy-update")
	started, err := service.StartSession(ctx, request)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	runtime.invoke = func(
		callContext context.Context,
		_ domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		history, historyErr := store.SessionHistory(callContext, started.Session.ID)
		if historyErr != nil || len(history.Interventions) != 1 ||
			history.Interventions[0].State != domain.InterventionStateForwarded || envelope.JobPolicy == nil {
			return plugin.OperationResult{}, fmt.Errorf("policy was not durable before dispatch: %#v, %w", history, historyErr)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded, Output: json.RawMessage(`{"applied":true}`),
		}, nil
	}
	policy := domain.JobPolicy{
		Approvals:  domain.ApprovalPolicyAlways,
		Filesystem: domain.FilesystemPolicyReadOnly,
		Network:    domain.NetworkPolicyDeny,
	}
	handleID := started.Handle.ID
	result, err := service.ForwardIntervention(ctx, ForwardInterventionRequest{
		Intervention: sqlite.InterventionRequest{
			ID: "intervention-policy-update", SessionID: started.Session.ID,
			Kind: domain.InterventionKindPolicy, Payload: json.RawMessage(`{"reason":"owner override"}`),
			Source: "owner-terminal",
		},
		Operation: plugin.OperationEnvelope{
			ID: "operation-policy-update", AdapterID: "pi", Port: domain.AdapterPortAgentRuntime,
			Operation: "agent-runtime.policy", HandleID: &handleID, JobPolicy: &policy,
			Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
		},
	})
	if err != nil || result.Intervention.State != domain.InterventionStateCompleted {
		t.Fatalf("ForwardIntervention() result = %#v, error = %v", result, err)
	}
	updated, err := store.Session(ctx, started.Session.ID)
	if err != nil || updated.JobPolicy != policy {
		t.Fatalf("updated session policy = %#v, %v", updated.JobPolicy, err)
	}
}

func TestSessionServiceQueuesUnsupportedLiveInput(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-queue")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	invocations := 0
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		invocations++
		return baseInvoke(callContext, pluginID, envelope)
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(node, "run-session-queue", "session-queue", []byte("Start."))
	runtime.capabilities = []string{"job-policy", "queued-input", "structured-result"}
	started, err := service.StartSession(ctx, request)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	queued, err := service.ForwardIntervention(ctx, ForwardInterventionRequest{
		Intervention: sqlite.InterventionRequest{
			ID: "intervention-queue", SessionID: started.Session.ID,
			Kind: domain.InterventionKindMessage, Payload: json.RawMessage(`{"text":"Queue this."}`),
			Source: "owner-terminal",
		},
	})
	if err != nil {
		t.Fatalf("ForwardIntervention() returned %v", err)
	}
	if !queued.Queued || queued.Intervention.State != domain.InterventionStateQueued || invocations != 1 {
		t.Fatalf("queued intervention = %#v after %d invocations", queued, invocations)
	}
}

func TestSessionCancellationRecordsOrphanWhenSupervisorFails(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-cancel")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	runtime.cancel = func(context.Context, domain.PluginID, plugin.CancelParams) error {
		return context.DeadlineExceeded
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-cancel", "session-cancel", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	activeOperation := domain.OperationID("operation-active")
	started.Session, err = store.SetSessionOperation(
		ctx, started.Session.ID, started.Session.Metadata.ResourceVersion, &activeOperation,
	)
	if err != nil {
		t.Fatalf("SetSessionOperation() returned %v", err)
	}
	deadline := time.Now().Add(time.Second)
	session, intervention, err := service.CancelSession(ctx, sqlite.InterventionRequest{
		ID: "intervention-cancel", SessionID: started.Session.ID,
		Kind: domain.InterventionKindInterrupt, Payload: json.RawMessage(`{"reason":"owner interrupt"}`),
		Source: "owner-terminal", Deadline: &deadline,
	})
	if !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("CancelSession() error = %v", err)
	}
	if session.State != domain.SessionStateOrphaned || intervention.State != domain.InterventionStateFailed {
		t.Fatalf("cancelled session = %#v, intervention = %#v", session, intervention)
	}
}

func TestSessionCancellationInterruptsRuntimeWithoutActiveOperation(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-interrupt")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	interrupts := 0
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		if envelope.Operation == "agent-runtime.interrupt" {
			interrupts++
			return plugin.OperationResult{
				ID: envelope.ID, State: domain.OperationStateSucceeded, Output: json.RawMessage(`{"interrupted":true}`),
			}, nil
		}
		return baseInvoke(callContext, pluginID, envelope)
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(
		node, "run-session-interrupt", "session-interrupt", []byte("Start."),
	)
	runtime.capabilities = []string{"interrupt", "job-policy", "resume", "structured-result"}
	started, err := service.StartSession(ctx, request)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if started.Session.ActiveOperationID != nil {
		t.Fatalf("started session has active operation: %#v", started.Session)
	}
	deadline := time.Now().Add(time.Second)
	session, intervention, err := service.CancelSession(ctx, sqlite.InterventionRequest{
		ID: "intervention-interrupt", SessionID: started.Session.ID,
		Kind: domain.InterventionKindInterrupt, Payload: json.RawMessage(`{"reason":"owner interrupt"}`),
		Source: "owner-terminal", Deadline: &deadline,
	})
	if err != nil {
		t.Fatalf("CancelSession() returned %v", err)
	}
	if interrupts != 1 || session.State != domain.SessionStateCancelled ||
		intervention.State != domain.InterventionStateCompleted {
		t.Fatalf("cancelled session = %#v, intervention = %#v after %d interrupts", session, intervention, interrupts)
	}
}

func TestSessionRecoveryRecordsAdoption(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-recovery")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	reconciledOpaqueHandle := false
	runtime.reconcile = func(
		_ context.Context,
		_ domain.PluginID,
		handles []plugin.HandleDescriptor,
	) ([]plugin.ReconcileResult, error) {
		if len(handles) == 1 && string(handles[0].OpaqueValue) == `{"runtimeSession":"private"}` {
			reconciledOpaqueHandle = true
		}
		return []plugin.ReconcileResult{{HandleID: handles[0].ID, State: plugin.ReconcileStateAdopted}}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-recovery", "session-recovery", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	recovered, err := service.RecoverSessions(ctx)
	if err != nil {
		t.Fatalf("RecoverSessions() returned %v", err)
	}
	if !reconciledOpaqueHandle || len(recovered) != 1 || recovered[0].State != domain.SessionStateRunning ||
		recovered[0].Metadata.ResourceVersion <= started.Session.Metadata.ResourceVersion {
		t.Fatalf("recovered sessions = %#v", recovered)
	}
}

func TestSessionRecoveryPersistsOrphanWhenRuntimeIsUnavailable(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-orphan-recovery")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	runtime.reconcile = func(
		context.Context,
		domain.PluginID,
		[]plugin.HandleDescriptor,
	) ([]plugin.ReconcileResult, error) {
		return nil, errors.New("runtime unavailable")
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	started, err := service.StartSession(
		ctx, startSessionTestRequest(node, "run-session-orphan-recovery", "session-orphan-recovery", []byte("Start.")),
	)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	recovered, err := service.RecoverSessions(ctx)
	if err != nil {
		t.Fatalf("RecoverSessions() returned %v", err)
	}
	if len(recovered) != 1 || recovered[0].ID != started.Session.ID ||
		recovered[0].State != domain.SessionStateOrphaned {
		t.Fatalf("recovered sessions = %#v", recovered)
	}
	runtime.reconcile = func(
		_ context.Context,
		_ domain.PluginID,
		handles []plugin.HandleDescriptor,
	) ([]plugin.ReconcileResult, error) {
		return []plugin.ReconcileResult{{
			HandleID: handles[0].ID, State: plugin.ReconcileStateRehydrated,
		}}, nil
	}
	rehydrated, err := service.RecoverSessions(ctx)
	if err != nil {
		t.Fatalf("second RecoverSessions() returned %v", err)
	}
	if len(rehydrated) != 1 || rehydrated[0].State != domain.SessionStateRunning {
		t.Fatalf("rehydrated sessions = %#v", rehydrated)
	}
}

func TestPluginEventRecorderPersistsBeforeAcknowledgement(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	recorder, err := NewPluginEventRecorder(store)
	if err != nil {
		t.Fatalf("NewPluginEventRecorder() returned %v", err)
	}
	event := plugin.OperationEvent{
		OperationID: "operation-event", Sequence: 1, Kind: "output",
		Payload: json.RawMessage(`{"text":"durable"}`), OccurredAt: time.Now().UTC(),
	}
	if err := recorder.RecordPluginEvent(ctx, "pi-plugin", event); err != nil {
		t.Fatalf("RecordPluginEvent() returned %v", err)
	}
	events, err := store.EventsAfter(ctx, 0, 10)
	if err != nil || len(events) != 1 || events[0].Aggregate.ID != string(event.OperationID) {
		t.Fatalf("EventsAfter() = %#v, %v", events, err)
	}
}

func TestSessionSyncPersistsNormalizedRuntimeEvents(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-sync")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		if envelope.Operation != "agent-runtime.reconcile" {
			return baseInvoke(callContext, pluginID, envelope)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{
  "state":"idle","cursor":2,"firstAvailableCursor":1,"more":false,
  "events":[
    {"sequence":1,"kind":"turn","providerEventType":"turn_start","occurredAt":"2026-08-28T12:00:00Z","data":{}},
    {"sequence":2,"kind":"model_call","providerEventType":"message_end","occurredAt":"2026-08-28T12:00:01Z","data":{"role":"assistant"}}
  ]
}`),
		}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(node, "run-session-sync", "session-sync", []byte("Start."))
	runtime.capabilities = []string{"job-policy", "normalized-events", "resume", "structured-result"}
	started, err := service.StartSession(ctx, request)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if err := service.SyncActiveSessions(ctx); err != nil {
		t.Fatalf("SyncActiveSessions() returned %v", err)
	}
	synced, err := store.Session(ctx, started.Session.ID)
	if err != nil {
		t.Fatalf("Session() returned %v", err)
	}
	if synced.RuntimeEventCursor != 2 {
		t.Fatalf("synced session = %#v", synced)
	}
	events, err := store.EventsAfter(ctx, 0, 100)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	count := 0
	for _, event := range events {
		if event.Type == "session.runtime.event" {
			count++
		}
	}
	if count != 2 {
		t.Fatalf("persisted runtime event count = %d", count)
	}
}

func TestSessionSyncRejectsEmptyMoreBatch(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-empty-more")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		if envelope.Operation != "agent-runtime.reconcile" {
			return baseInvoke(callContext, pluginID, envelope)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{
  "state":"idle","cursor":0,"firstAvailableCursor":0,"more":true,"events":[]
}`),
		}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(node, "run-session-empty-more", "session-empty-more", []byte("Start."))
	runtime.capabilities = []string{"job-policy", "normalized-events", "resume", "structured-result"}
	if _, err := service.StartSession(ctx, request); err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if err := service.SyncActiveSessions(ctx); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("SyncActiveSessions() returned %v", err)
	}
}

func TestSessionSyncPersistsTerminalRuntimeStateWithoutNewEvents(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-terminal-sync")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		if envelope.Operation != "agent-runtime.reconcile" {
			return baseInvoke(callContext, pluginID, envelope)
		}
		return plugin.OperationResult{
			ID: envelope.ID, State: domain.OperationStateSucceeded,
			Output: json.RawMessage(`{"state":"completed","cursor":0,"firstAvailableCursor":0,"more":false,"events":[]}`),
		}, nil
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(node, "run-session-terminal-sync", "session-terminal-sync", []byte("Start."))
	runtime.capabilities = []string{"job-policy", "normalized-events", "resume", "structured-result"}
	started, err := service.StartSession(ctx, request)
	if err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	if err := service.SyncActiveSessions(ctx); err != nil {
		t.Fatalf("SyncActiveSessions() returned %v", err)
	}
	completed, err := store.Session(ctx, started.Session.ID)
	if err != nil {
		t.Fatalf("Session() returned %v", err)
	}
	if completed.State != domain.SessionStateCompleted {
		t.Fatalf("synced session state = %q", completed.State)
	}
}

func TestRuntimeSyncRecordsFailureWithoutStoppingLoop(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createBrokerSessionRun(t, ctx, "run-session-sync-failure")
	defer store.Close()
	runtime := defaultFixtureSessionRuntime()
	baseInvoke := runtime.invoke
	runtime.invoke = func(
		callContext context.Context,
		pluginID domain.PluginID,
		envelope plugin.OperationEnvelope,
	) (plugin.OperationResult, error) {
		if envelope.Operation == "agent-runtime.reconcile" {
			return plugin.OperationResult{}, errors.New("fixture sync failed")
		}
		return baseInvoke(callContext, pluginID, envelope)
	}
	service, err := NewSessionService(store, runtime)
	if err != nil {
		t.Fatalf("NewSessionService() returned %v", err)
	}
	request := startSessionTestRequest(node, "run-session-sync-failure", "session-sync-failure", []byte("Start."))
	runtime.capabilities = []string{"job-policy", "normalized-events", "structured-result"}
	if _, err := service.StartSession(ctx, request); err != nil {
		t.Fatalf("StartSession() returned %v", err)
	}
	loopContext, cancel := context.WithCancel(ctx)
	loopDone := make(chan error, 1)
	go func() { loopDone <- service.RunEventSync(loopContext, 10*time.Millisecond) }()
	deadline := time.Now().Add(2 * time.Second)
	failures := 0
	for time.Now().Before(deadline) {
		events, readErr := store.EventsAfter(ctx, 0, 100)
		if readErr != nil {
			cancel()
			t.Fatalf("EventsAfter() returned %v", readErr)
		}
		failures = 0
		for _, event := range events {
			if event.Type == "broker.runtime-sync.failed" {
				failures++
			}
		}
		if failures == 1 {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}
	cancel()
	if err := <-loopDone; !errors.Is(err, context.Canceled) {
		t.Fatalf("RunEventSync() error = %v", err)
	}
	if failures != 1 {
		t.Fatalf("runtime sync failure events = %d", failures)
	}
}

func defaultFixtureSessionRuntime() *fixtureSessionRuntime {
	return &fixtureSessionRuntime{
		invoke: func(
			_ context.Context,
			_ domain.PluginID,
			envelope plugin.OperationEnvelope,
		) (plugin.OperationResult, error) {
			result := plugin.OperationResult{
				ID: envelope.ID, State: domain.OperationStateSucceeded,
				Output: json.RawMessage(`{"value":"accepted"}`),
			}
			if envelope.Operation == "agent-runtime.start" {
				result.Handle = &plugin.AdapterHandleValue{
					FormatVersion: 1, OpaqueValue: json.RawMessage(`{"runtimeSession":"private"}`),
				}
			}
			return result, nil
		},
		cancel: func(context.Context, domain.PluginID, plugin.CancelParams) error { return nil },
		reconcile: func(
			_ context.Context,
			_ domain.PluginID,
			handles []plugin.HandleDescriptor,
		) ([]plugin.ReconcileResult, error) {
			results := make([]plugin.ReconcileResult, 0, len(handles))
			for _, handle := range handles {
				results = append(results, plugin.ReconcileResult{
					HandleID: handle.ID, State: plugin.ReconcileStateAdopted,
				})
			}
			return results, nil
		},
		track:        func(domain.PluginID, plugin.HandleDescriptor) error { return nil },
		capabilities: []string{"job-policy", "live-input", "resume", "structured-result"},
	}
}

func createBrokerSessionRun(
	t *testing.T,
	ctx context.Context,
	runID domain.WorkflowRunID,
) (*sqlite.Store, domain.NodeRun) {
	t.Helper()
	store, err := sqlite.Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	document, err := os.ReadFile("../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		store.Close()
		t.Fatalf("ReadFile() returned %v", err)
	}
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		store.Close()
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, workflowmodel.CapabilityMap{
		"pi": {"structured-result", "live-input"},
	})
	if err != nil {
		store.Close()
		t.Fatalf("Resolve() returned %v", err)
	}
	definitionID := domain.WorkflowDefinitionID("definition-" + string(runID))
	if _, err := store.CreateWorkflowDefinition(ctx, definitionID, nil, document, resolved); err != nil {
		store.Close()
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, runID, definitionID, nil); err != nil {
		store.Close()
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, runID, sqlite.AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 {
		store.Close()
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	return store, reserved[0]
}

func startSessionTestRequest(
	node domain.NodeRun,
	runID domain.WorkflowRunID,
	sessionID domain.SessionID,
	prompt []byte,
) StartSessionRequest {
	return StartSessionRequest{
		Session: sqlite.CreateSessionRequest{
			ID: sessionID, WorkflowRunID: runID, NodeRunID: node.ID,
			RuntimePluginID: "caller-plugin", RuntimeAdapterID: "caller-runtime",
			Capabilities: []string{"job-policy", "live-input", "resume"},
		},
		HandleID: domain.AdapterHandleID("handle-" + string(sessionID)),
		Operation: plugin.OperationEnvelope{
			ID:        domain.OperationID("operation-start-" + string(sessionID)),
			AdapterID: "caller-runtime", Port: domain.AdapterPortAgentRuntime,
			Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"start"}`),
			Deadline: time.Now().Add(time.Minute),
		},
		PromptMediaType: "text/plain", TemplateDigest: "sha256:template", RenderedPrompt: prompt,
	}
}
