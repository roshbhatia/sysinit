package broker

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
)

type SessionRuntime interface {
	Invoke(context.Context, domain.PluginID, plugin.OperationEnvelope) (plugin.OperationResult, error)
	Cancel(context.Context, domain.PluginID, plugin.CancelParams) error
	Reconcile(context.Context, domain.PluginID, []plugin.HandleDescriptor) ([]plugin.ReconcileResult, error)
	TrackHandle(domain.PluginID, plugin.HandleDescriptor) error
	ResolveAdapter(domain.AdapterPort, string) (domain.PluginID, []string, error)
}

type SessionService struct {
	store   *sqlite.Store
	runtime SessionRuntime

	syncMu        sync.Mutex
	lastSyncError string
}

type StartSessionRequest struct {
	Session         sqlite.CreateSessionRequest
	HandleID        domain.AdapterHandleID
	Operation       plugin.OperationEnvelope
	PromptMediaType string
	TemplateDigest  string
	SecretNames     []string
	RenderedPrompt  []byte
}

type StartSessionResult struct {
	Session domain.Session
	Handle  domain.AdapterHandle
	Prompt  domain.PromptArtifact
	Result  plugin.OperationResult
}

type ForwardInterventionRequest struct {
	Intervention sqlite.InterventionRequest
	Operation    plugin.OperationEnvelope
}

type ForwardInterventionResult struct {
	Intervention domain.Intervention
	Result       *plugin.OperationResult
	Queued       bool
}

type ForwardAttachmentRequest struct {
	Intervention sqlite.InterventionRequest `json:"intervention"`
	PluginID     domain.PluginID            `json:"pluginId"`
	Operation    plugin.OperationEnvelope   `json:"operation"`
}

type ForwardAttachmentResult struct {
	Intervention domain.Intervention    `json:"intervention"`
	Result       plugin.OperationResult `json:"result"`
}

type SyncSessionRequest struct {
	SessionID   domain.SessionID
	OperationID domain.OperationID
	Maximum     uint32
	Deadline    time.Time
}

type SyncSessionResult struct {
	Session domain.Session
	Events  []domain.RuntimeEvent
	More    bool
}

type PluginEventRecorder struct {
	store *sqlite.Store
}

func NewPluginEventRecorder(store *sqlite.Store) (*PluginEventRecorder, error) {
	if store == nil {
		return nil, invalidSessionService("plugin event recorder", "store is nil")
	}
	return &PluginEventRecorder{store: store}, nil
}

func (recorder *PluginEventRecorder) RecordPluginEvent(
	ctx context.Context,
	pluginID domain.PluginID,
	event plugin.OperationEvent,
) error {
	if err := pluginID.Validate(); err != nil {
		return err
	}
	if err := event.OperationID.Validate(); err != nil {
		return err
	}
	if event.Sequence == 0 || event.Kind == "" || event.OccurredAt.IsZero() || !json.Valid(event.Payload) {
		return invalidSessionService(string(event.OperationID), "plugin event is invalid")
	}
	payload, err := json.Marshal(event)
	if err != nil {
		return err
	}
	_, err = recorder.store.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: event.OccurredAt.UTC(),
		Aggregate: domain.ResourceReference{Kind: "plugin-operation", ID: string(event.OperationID)},
		Type:      "plugin.operation.event", Payload: payload,
		Metadata: map[string]string{"pluginId": string(pluginID)},
	})
	return err
}

func NewSessionService(store *sqlite.Store, runtime SessionRuntime) (*SessionService, error) {
	if store == nil {
		return nil, invalidSessionService("session service", "store is nil")
	}
	if runtime == nil {
		return nil, invalidSessionService("session service", "runtime is nil")
	}
	return &SessionService{store: store, runtime: runtime}, nil
}

func (service *SessionService) StartSession(
	ctx context.Context,
	request StartSessionRequest,
) (StartSessionResult, error) {
	if err := request.HandleID.Validate(); err != nil {
		return StartSessionResult{}, err
	}
	contract, err := service.store.NodeExecutionContract(ctx, request.Session.NodeRunID)
	if err != nil {
		return StartSessionResult{}, err
	}
	pluginID, capabilities, err := service.runtime.ResolveAdapter(
		domain.AdapterPortAgentRuntime, contract.Adapter,
	)
	if err != nil {
		return StartSessionResult{}, err
	}
	if !hasCapabilities(capabilities, contract.RequiredCapabilities) || !hasCapability(capabilities, "job-policy") {
		return StartSessionResult{}, invalidSessionService(
			string(request.Session.NodeRunID), "runtime lacks a capability required by the pinned node",
		)
	}
	_, runtimeAdapterID := domain.ParseAdapterSelector(contract.Adapter)
	request.Session.RuntimePluginID = pluginID
	request.Session.RuntimeAdapterID = runtimeAdapterID
	request.Session.Capabilities = capabilities
	request.Operation.AdapterID = runtimeAdapterID
	prompt, err := service.store.StorePromptArtifact(
		ctx, request.PromptMediaType, request.TemplateDigest, request.SecretNames, request.RenderedPrompt,
	)
	if err != nil {
		return StartSessionResult{}, err
	}
	session, err := service.store.CreateSession(ctx, request.Session)
	if err != nil {
		return StartSessionResult{Prompt: prompt}, err
	}
	if !hasCapability(session.Capabilities, "job-policy") {
		failed, transitionErr := service.failSession(session)
		return StartSessionResult{Session: failed, Prompt: prompt}, errors.Join(
			invalidSessionService(string(session.ID), "runtime does not enforce job policy"), transitionErr,
		)
	}
	if request.Operation.Operation != "agent-runtime.start" || request.Operation.Port != domain.AdapterPortAgentRuntime ||
		request.Operation.AdapterID != request.Session.RuntimeAdapterID || request.Operation.HandleID != nil {
		failed, transitionErr := service.failSession(session)
		return StartSessionResult{Session: failed, Prompt: prompt}, errors.Join(
			invalidSessionService(string(session.ID), "runtime start operation is invalid"), transitionErr,
		)
	}
	request.Operation.JobPolicy = &session.JobPolicy
	session, err = service.store.SetSessionOperation(
		ctx, session.ID, session.Metadata.ResourceVersion, &request.Operation.ID,
	)
	if err != nil {
		return StartSessionResult{Session: session, Prompt: prompt}, err
	}
	result, invokeErr := service.runtime.Invoke(ctx, pluginID, request.Operation)
	if invokeErr != nil || result.State != domain.OperationStateSucceeded || result.Handle == nil {
		failed, transitionErr := service.failSession(session)
		if invokeErr == nil {
			invokeErr = invalidSessionService(string(session.ID), "runtime start returned no usable handle")
		}
		return StartSessionResult{Session: failed, Prompt: prompt, Result: result}, errors.Join(invokeErr, transitionErr)
	}
	startingSession := session
	boundSession, handle, err := service.store.BindSessionHandle(ctx, sqlite.BindSessionHandleRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		HandleID: request.HandleID, FormatVersion: result.Handle.FormatVersion,
		OpaqueValue: result.Handle.OpaqueValue, State: result.SessionState, TraceSessionID: result.TraceSessionID,
	})
	if err != nil {
		orphaned, transitionErr := service.store.TransitionSession(context.Background(), sqlite.SessionTransitionRequest{
			SessionID: startingSession.ID, ExpectedVersion: startingSession.Metadata.ResourceVersion,
			State: domain.SessionStateOrphaned,
		})
		return StartSessionResult{Session: orphaned, Prompt: prompt, Result: result}, errors.Join(
			&domain.Error{
				Code: domain.ErrorCodeIndeterminate, Op: "start session", Resource: string(startingSession.ID),
				Message: "runtime started before its handle could be persisted", Err: err,
			}, transitionErr,
		)
	}
	session = boundSession
	if err := service.runtime.TrackHandle(session.RuntimePluginID, plugin.HandleDescriptor{
		ID: handle.ID, PluginID: session.RuntimePluginID,
		Port: domain.AdapterPortAgentRuntime, AdapterID: session.RuntimeAdapterID,
		FormatVersion: handle.FormatVersion,
		OpaqueValue:   append(json.RawMessage(nil), handle.OpaqueValue...),
	}); err != nil {
		orphaned, transitionErr := service.store.TransitionSession(context.Background(), sqlite.SessionTransitionRequest{
			SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
			State: domain.SessionStateOrphaned,
		})
		return StartSessionResult{Session: orphaned, Handle: handle, Prompt: prompt, Result: result}, errors.Join(
			&domain.Error{
				Code: domain.ErrorCodeIndeterminate, Op: "start session", Resource: string(session.ID),
				Message: "runtime handle could not be tracked", Err: err,
			}, transitionErr,
		)
	}
	return StartSessionResult{Session: session, Handle: handle, Prompt: prompt, Result: result}, nil
}

func (service *SessionService) ForwardIntervention(
	ctx context.Context,
	request ForwardInterventionRequest,
) (ForwardInterventionResult, error) {
	intervention, err := service.store.RecordIntervention(ctx, request.Intervention)
	if err != nil {
		return ForwardInterventionResult{}, err
	}
	session, err := service.store.Session(ctx, request.Intervention.SessionID)
	if err != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed}, errors.Join(err, transitionErr)
	}
	if request.Intervention.Kind == domain.InterventionKindMessage &&
		!hasCapability(session.Capabilities, "live-input") {
		if hasCapability(session.Capabilities, "queued-input") {
			queued, transitionErr := service.store.TransitionIntervention(
				ctx, intervention.ID, intervention.Metadata.ResourceVersion, domain.InterventionStateQueued,
			)
			return ForwardInterventionResult{Intervention: queued, Queued: transitionErr == nil}, transitionErr
		}
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed}, errors.Join(
			invalidSessionService(string(session.ID), "runtime does not support live or queued input"), transitionErr,
		)
	}
	if request.Intervention.Kind == domain.InterventionKindPolicy && !hasCapability(session.Capabilities, "policy-update") {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed}, errors.Join(
			invalidSessionService(string(session.ID), "runtime policy change requires a new attempt or replay"),
			transitionErr,
		)
	}
	if err := validateInterventionOperation(session, request); err != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed}, errors.Join(err, transitionErr)
	}
	intervention, err = service.store.TransitionIntervention(
		ctx, intervention.ID, intervention.Metadata.ResourceVersion, domain.InterventionStateForwarded,
	)
	if err != nil {
		return ForwardInterventionResult{Intervention: intervention}, err
	}
	session, err = service.store.SetSessionOperation(
		ctx, session.ID, session.Metadata.ResourceVersion, &request.Operation.ID,
	)
	if err != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed}, errors.Join(err, transitionErr)
	}
	result, invokeErr := service.runtime.Invoke(ctx, session.RuntimePluginID, request.Operation)
	cleared, clearErr := service.store.SetSessionOperation(
		context.Background(), session.ID, session.Metadata.ResourceVersion, nil,
	)
	if invokeErr != nil || result.State != domain.OperationStateSucceeded {
		failed, transitionErr := service.failIntervention(intervention)
		if invokeErr == nil {
			invokeErr = invalidSessionService(string(intervention.ID), "runtime rejected intervention")
		}
		return ForwardInterventionResult{Intervention: failed, Result: &result}, errors.Join(
			invokeErr, clearErr, transitionErr,
		)
	}
	var policyErr error
	if request.Intervention.Kind == domain.InterventionKindPolicy && clearErr == nil {
		_, policyErr = service.store.SetSessionJobPolicy(
			context.Background(), cleared.ID, cleared.Metadata.ResourceVersion, *request.Operation.JobPolicy,
		)
	}
	if policyErr != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardInterventionResult{Intervention: failed, Result: &result}, errors.Join(
			&domain.Error{
				Code: domain.ErrorCodeIndeterminate, Op: "apply session policy", Resource: string(session.ID),
				Message: "runtime applied policy before the broker persisted it", Err: policyErr,
			}, transitionErr,
		)
	}
	completed, transitionErr := service.store.TransitionIntervention(
		context.Background(), intervention.ID, intervention.Metadata.ResourceVersion,
		domain.InterventionStateCompleted,
	)
	return ForwardInterventionResult{Intervention: completed, Result: &result}, errors.Join(clearErr, transitionErr)
}

func (service *SessionService) ForwardAttachment(
	ctx context.Context,
	request ForwardAttachmentRequest,
) (ForwardAttachmentResult, error) {
	intervention, err := service.store.RecordIntervention(ctx, request.Intervention)
	if err != nil {
		return ForwardAttachmentResult{}, err
	}
	session, sessionErr := service.store.Session(ctx, request.Intervention.SessionID)
	if sessionErr != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardAttachmentResult{Intervention: failed}, errors.Join(sessionErr, transitionErr)
	}
	if request.PluginID == "" {
		request.PluginID = session.RuntimePluginID
	}
	if request.PluginID != session.RuntimePluginID {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardAttachmentResult{Intervention: failed}, errors.Join(
			invalidSessionService(string(session.ID), "attachment plugin does not own the session"), transitionErr,
		)
	}
	selectedPluginID, runtimeAttachmentID := domain.ParseAdapterSelector(request.Operation.AdapterID)
	attachmentSelector := request.Operation.AdapterID
	if selectedPluginID == "" {
		attachmentSelector = string(session.RuntimePluginID) + "::" + runtimeAttachmentID
	}
	attachmentPluginID, _, resolveErr := service.runtime.ResolveAdapter(
		domain.AdapterPortAttachment, attachmentSelector,
	)
	if resolveErr != nil || attachmentPluginID != session.RuntimePluginID {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardAttachmentResult{Intervention: failed}, errors.Join(
			invalidSessionService(string(session.ID), "attachment adapter does not own the session"),
			resolveErr, transitionErr,
		)
	}
	request.Operation.AdapterID = runtimeAttachmentID
	if err := validateAttachmentOperation(session, request); err != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return ForwardAttachmentResult{Intervention: failed}, errors.Join(err, transitionErr)
	}
	intervention, err = service.store.TransitionIntervention(
		ctx, intervention.ID, intervention.Metadata.ResourceVersion, domain.InterventionStateForwarded,
	)
	if err != nil {
		return ForwardAttachmentResult{Intervention: intervention}, err
	}
	result, invokeErr := service.runtime.Invoke(ctx, request.PluginID, request.Operation)
	if invokeErr != nil || result.State != domain.OperationStateSucceeded {
		failed, transitionErr := service.failIntervention(intervention)
		if invokeErr == nil {
			invokeErr = invalidSessionService(string(intervention.ID), "attachment adapter rejected intervention")
		}
		return ForwardAttachmentResult{Intervention: failed, Result: result}, errors.Join(invokeErr, transitionErr)
	}
	completed, transitionErr := service.store.TransitionIntervention(
		context.Background(), intervention.ID, intervention.Metadata.ResourceVersion,
		domain.InterventionStateCompleted,
	)
	return ForwardAttachmentResult{Intervention: completed, Result: result}, transitionErr
}

func (service *SessionService) CancelSession(
	ctx context.Context,
	request sqlite.InterventionRequest,
) (domain.Session, domain.Intervention, error) {
	intervention, err := service.store.RecordIntervention(ctx, request)
	if err != nil {
		return domain.Session{}, domain.Intervention{}, err
	}
	if request.Kind != domain.InterventionKindInterrupt || request.Deadline == nil {
		failed, transitionErr := service.failIntervention(intervention)
		return domain.Session{}, failed, errors.Join(
			invalidSessionService(string(request.ID), "cancellation requires an interrupt deadline"), transitionErr,
		)
	}
	session, err := service.store.Session(ctx, request.SessionID)
	if err != nil {
		failed, transitionErr := service.failIntervention(intervention)
		return domain.Session{}, failed, errors.Join(err, transitionErr)
	}
	intervention, err = service.store.TransitionIntervention(
		ctx, intervention.ID, intervention.Metadata.ResourceVersion, domain.InterventionStateForwarded,
	)
	if err != nil {
		return session, intervention, err
	}
	var cancelErr error
	if session.ActiveOperationID != nil {
		cancelErr = service.runtime.Cancel(ctx, session.RuntimePluginID, plugin.CancelParams{
			OperationID: *session.ActiveOperationID, Deadline: *request.Deadline,
		})
	}
	current, readErr := service.store.Session(context.Background(), session.ID)
	if cancelErr == nil && readErr == nil && current.RuntimeHandle != nil &&
		hasCapability(current.Capabilities, "interrupt") {
		operationID := domain.OperationID(request.ID)
		updated, setErr := service.store.SetSessionOperation(
			context.Background(), current.ID, current.Metadata.ResourceVersion, &operationID,
		)
		cancelErr = setErr
		if cancelErr == nil {
			current = updated
			handleID := *current.RuntimeHandle
			operation := plugin.OperationEnvelope{
				ID: operationID, AdapterID: current.RuntimeAdapterID,
				Port: domain.AdapterPortAgentRuntime, Operation: "agent-runtime.interrupt",
				HandleID: &handleID, Input: json.RawMessage(`{}`), Deadline: *request.Deadline,
			}
			interruptContext, stopInterrupt := context.WithDeadline(ctx, *request.Deadline)
			result, invokeErr := service.runtime.Invoke(interruptContext, current.RuntimePluginID, operation)
			stopInterrupt()
			if invokeErr != nil || result.State != domain.OperationStateSucceeded {
				forcedErr := service.runtime.Cancel(context.Background(), current.RuntimePluginID, plugin.CancelParams{
					OperationID: operationID, Deadline: *request.Deadline,
				})
				if forcedErr != nil {
					cancelErr = errors.Join(invokeErr, forcedErr)
				}
			}
			current, readErr = service.store.SetSessionOperation(
				context.Background(), current.ID, current.Metadata.ResourceVersion, nil,
			)
		}
	}
	if readErr == nil && !terminalSession(current.State) {
		target := domain.SessionStateCancelled
		if cancelErr != nil {
			target = domain.SessionStateOrphaned
		}
		current, readErr = service.store.TransitionSession(context.Background(), sqlite.SessionTransitionRequest{
			SessionID: current.ID, ExpectedVersion: current.Metadata.ResourceVersion,
			State: target,
		})
	}
	interventionState := domain.InterventionStateCompleted
	if cancelErr != nil || readErr != nil {
		interventionState = domain.InterventionStateFailed
	}
	completed, interventionErr := service.store.TransitionIntervention(
		context.Background(), intervention.ID, intervention.Metadata.ResourceVersion,
		interventionState,
	)
	return current, completed, errors.Join(cancelErr, readErr, interventionErr)
}

func (service *SessionService) RecoverSessions(ctx context.Context) ([]domain.Session, error) {
	active, err := service.store.RecoverableSessions(ctx)
	if err != nil {
		return nil, err
	}
	reconciled := make([]domain.Session, 0, len(active))
	var recoveryErr error
	for _, session := range active {
		contract, contractErr := service.store.NodeExecutionContract(ctx, session.NodeRunID)
		if contractErr == nil {
			var pluginID domain.PluginID
			var capabilities []string
			pluginID, capabilities, contractErr = service.runtime.ResolveAdapter(
				domain.AdapterPortAgentRuntime, contract.Adapter,
			)
			if contractErr == nil && (!hasCapabilities(capabilities, contract.RequiredCapabilities) ||
				!hasCapability(capabilities, "job-policy")) {
				contractErr = invalidSessionService(
					string(session.ID), "runtime lacks a capability required by the pinned node",
				)
			}
			if contractErr == nil {
				_, runtimeAdapterID := domain.ParseAdapterSelector(contract.Adapter)
				session, contractErr = service.store.RefreshSessionContract(
					ctx, session.ID, session.Metadata.ResourceVersion,
					pluginID, runtimeAdapterID, capabilities,
				)
			}
		}
		if contractErr != nil {
			updated, reconcileErr := service.store.ReconcileSession(
				ctx, session.ID, session.Metadata.ResourceVersion, domain.SessionReconciliationOrphaned,
			)
			if reconcileErr == nil {
				reconciled = append(reconciled, updated)
			}
			recoveryErr = errors.Join(recoveryErr, contractErr, reconcileErr)
			continue
		}
		state := domain.SessionReconciliationOrphaned
		if session.RuntimeHandle != nil {
			handle, handleErr := service.store.AdapterHandle(ctx, *session.RuntimeHandle)
			if handleErr != nil {
				updated, reconcileErr := service.store.ReconcileSession(
					ctx, session.ID, session.Metadata.ResourceVersion, state,
				)
				if reconcileErr != nil {
					recoveryErr = errors.Join(recoveryErr, reconcileErr)
					continue
				}
				reconciled = append(reconciled, updated)
				continue
			}
			results, err := service.runtime.Reconcile(ctx, session.RuntimePluginID, []plugin.HandleDescriptor{{
				ID: handle.ID, PluginID: handle.PluginID, Port: handle.Port, AdapterID: handle.AdapterID,
				FormatVersion: handle.FormatVersion,
				OpaqueValue:   append(json.RawMessage(nil), handle.OpaqueValue...),
			}})
			if err == nil && len(results) == 1 && results[0].HandleID == *session.RuntimeHandle {
				state = results[0].State
			}
		}
		updated, err := service.store.ReconcileSession(ctx, session.ID, session.Metadata.ResourceVersion, state)
		if err != nil {
			recoveryErr = errors.Join(recoveryErr, err)
			continue
		}
		reconciled = append(reconciled, updated)
	}
	return reconciled, recoveryErr
}

func (service *SessionService) SyncSession(
	ctx context.Context,
	request SyncSessionRequest,
) (SyncSessionResult, error) {
	if err := request.SessionID.Validate(); err != nil {
		return SyncSessionResult{}, err
	}
	if err := request.OperationID.Validate(); err != nil {
		return SyncSessionResult{}, err
	}
	if request.Deadline.IsZero() || request.Maximum > 500 {
		return SyncSessionResult{}, invalidSessionService(string(request.SessionID), "sync request is invalid")
	}
	if request.Maximum == 0 {
		request.Maximum = 200
	}
	session, err := service.store.Session(ctx, request.SessionID)
	if err != nil {
		return SyncSessionResult{}, err
	}
	if session.RuntimeHandle == nil || !hasCapability(session.Capabilities, "normalized-events") {
		return SyncSessionResult{}, invalidSessionService(string(session.ID), "runtime does not expose normalized events")
	}
	handleID := *session.RuntimeHandle
	input, err := json.Marshal(struct {
		Cursor    uint64 `json:"cursor"`
		MaxEvents uint32 `json:"maxEvents"`
	}{Cursor: session.RuntimeEventCursor, MaxEvents: request.Maximum})
	if err != nil {
		return SyncSessionResult{}, err
	}
	session, err = service.store.SetSessionOperation(
		ctx, session.ID, session.Metadata.ResourceVersion, &request.OperationID,
	)
	if err != nil {
		return SyncSessionResult{}, err
	}
	operation := plugin.OperationEnvelope{
		ID: request.OperationID, AdapterID: session.RuntimeAdapterID,
		Port: domain.AdapterPortAgentRuntime, Operation: "agent-runtime.reconcile",
		HandleID: &handleID, Input: input, Deadline: request.Deadline,
	}
	result, invokeErr := service.runtime.Invoke(ctx, session.RuntimePluginID, operation)
	cleared, clearErr := service.store.SetSessionOperation(
		context.Background(), session.ID, session.Metadata.ResourceVersion, nil,
	)
	if invokeErr != nil || clearErr != nil || result.State != domain.OperationStateSucceeded {
		if invokeErr == nil && result.State != domain.OperationStateSucceeded {
			invokeErr = invalidSessionService(string(session.ID), "runtime event sync failed")
		}
		return SyncSessionResult{Session: cleared}, errors.Join(invokeErr, clearErr)
	}
	var batch domain.RuntimeEventBatch
	if err := json.Unmarshal(result.Output, &batch); err != nil {
		return SyncSessionResult{Session: cleared}, invalidSessionService(string(session.ID), "runtime event batch is invalid")
	}
	if len(batch.Events) == 0 {
		if batch.Cursor != cleared.RuntimeEventCursor {
			return SyncSessionResult{Session: cleared}, invalidSessionService(
				string(session.ID), "empty runtime event batch changed its cursor",
			)
		}
		if batch.More {
			return SyncSessionResult{Session: cleared}, invalidSessionService(
				string(session.ID), "runtime event batch promises more events without progress",
			)
		}
		updated, err := service.applyRuntimeBatchState(ctx, cleared, batch.State)
		return SyncSessionResult{Session: updated, More: batch.More}, err
	}
	if batch.Cursor != batch.Events[len(batch.Events)-1].Sequence {
		return SyncSessionResult{Session: cleared}, invalidSessionService(
			string(session.ID), "runtime event batch cursor does not match its events",
		)
	}
	updated, err := service.store.RecordSessionRuntimeEvents(
		ctx, cleared.ID, cleared.Metadata.ResourceVersion, batch.Events,
	)
	if err != nil {
		return SyncSessionResult{Session: cleared}, err
	}
	updated, err = service.applyRuntimeBatchState(ctx, updated, batch.State)
	return SyncSessionResult{Session: updated, Events: batch.Events, More: batch.More}, err
}

func (service *SessionService) SyncActiveSessions(ctx context.Context) error {
	sessions, err := service.store.ActiveSessions(ctx)
	if err != nil {
		return err
	}
	var syncErr error
	for _, session := range sessions {
		if session.RuntimeHandle == nil || !hasCapability(session.Capabilities, "normalized-events") {
			continue
		}
		for {
			digest := sha256.Sum256([]byte(fmt.Sprintf(
				"%s\x00%d", session.ID, session.RuntimeEventCursor,
			)))
			result, err := service.SyncSession(ctx, SyncSessionRequest{
				SessionID: session.ID, OperationID: domain.OperationID(fmt.Sprintf("sync-%x", digest[:12])),
				Maximum: 500, Deadline: time.Now().Add(5 * time.Second),
			})
			if err != nil {
				syncErr = errors.Join(syncErr, err)
				break
			}
			session = result.Session
			if !result.More {
				break
			}
		}
	}
	return syncErr
}

func (service *SessionService) RunEventSync(ctx context.Context, interval time.Duration) error {
	if interval < 10*time.Millisecond || interval > time.Minute {
		return invalidSessionService("event sync", "sync interval is outside its limits")
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		if err := service.SyncActiveSessions(ctx); err != nil {
			if recordErr := service.recordRuntimeSyncError(ctx, err); recordErr != nil {
				return recordErr
			}
		} else {
			service.clearRuntimeSyncError()
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-ticker.C:
		}
	}
}

func (service *SessionService) recordRuntimeSyncError(ctx context.Context, syncErr error) error {
	message := syncErr.Error()
	service.syncMu.Lock()
	if service.lastSyncError == message {
		service.syncMu.Unlock()
		return nil
	}
	service.lastSyncError = message
	service.syncMu.Unlock()
	payload, err := json.Marshal(struct {
		Error string `json:"error"`
	}{Error: message})
	if err != nil {
		return err
	}
	_, err = service.store.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: time.Now().UTC(),
		Aggregate: domain.ResourceReference{Kind: "broker", ID: "runtime-sync"},
		Type:      "broker.runtime-sync.failed", Payload: payload,
	})
	return err
}

func (service *SessionService) clearRuntimeSyncError() {
	service.syncMu.Lock()
	service.lastSyncError = ""
	service.syncMu.Unlock()
}

func (service *SessionService) applyRuntimeBatchState(
	ctx context.Context,
	session domain.Session,
	runtimeState string,
) (domain.Session, error) {
	target := domain.SessionState("")
	switch runtimeState {
	case string(domain.SessionStateCompleted):
		target = domain.SessionStateCompleted
	case string(domain.SessionStateFailed):
		target = domain.SessionStateFailed
	default:
		return session, nil
	}
	if terminalSession(session.State) {
		return session, nil
	}
	return service.store.TransitionSession(ctx, sqlite.SessionTransitionRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion, State: target,
	})
}

func (service *SessionService) failSession(session domain.Session) (domain.Session, error) {
	return service.store.TransitionSession(context.Background(), sqlite.SessionTransitionRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		State: domain.SessionStateFailed,
	})
}

func (service *SessionService) failIntervention(
	intervention domain.Intervention,
) (domain.Intervention, error) {
	return service.store.TransitionIntervention(
		context.Background(), intervention.ID, intervention.Metadata.ResourceVersion,
		domain.InterventionStateFailed,
	)
}

func validateInterventionOperation(
	session domain.Session,
	request ForwardInterventionRequest,
) error {
	if session.RuntimeHandle == nil || request.Operation.HandleID == nil ||
		*request.Operation.HandleID != *session.RuntimeHandle ||
		request.Operation.AdapterID != session.RuntimeAdapterID ||
		request.Operation.Port != domain.AdapterPortAgentRuntime {
		return invalidSessionService(string(session.ID), "intervention does not target the session runtime handle")
	}
	if request.Intervention.Kind == domain.InterventionKindPolicy {
		if request.Operation.Operation != "agent-runtime.policy" || request.Operation.JobPolicy == nil {
			return invalidSessionService(string(session.ID), "policy intervention requires a validated runtime policy operation")
		}
		if err := request.Operation.JobPolicy.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func validateAttachmentOperation(session domain.Session, request ForwardAttachmentRequest) error {
	if request.Operation.Port != domain.AdapterPortAttachment {
		return invalidSessionService(string(request.Intervention.SessionID), "attachment operation uses the wrong port")
	}
	switch request.Intervention.Kind {
	case domain.InterventionKindAttach:
		if request.Operation.Operation != "attachment.open" {
			return invalidSessionService(string(request.Intervention.SessionID), "attach requires attachment.open")
		}
	case domain.InterventionKindDetach:
		if request.Operation.Operation != "attachment.close" {
			return invalidSessionService(string(request.Intervention.SessionID), "detach requires attachment.close")
		}
	default:
		return invalidSessionService(string(request.Intervention.SessionID), "attachment intervention kind is invalid")
	}
	var target struct {
		SessionID string `json:"sessionId"`
	}
	if err := json.Unmarshal(request.Operation.Input, &target); err != nil || target.SessionID != string(session.ID) {
		return invalidSessionService(string(session.ID), "attachment input does not target the broker session")
	}
	return nil
}

func hasCapability(capabilities []string, target string) bool {
	for _, capability := range capabilities {
		if capability == target {
			return true
		}
	}
	return false
}

func hasCapabilities(capabilities []string, required []string) bool {
	for _, capability := range required {
		if !hasCapability(capabilities, capability) {
			return false
		}
	}
	return true
}

func terminalSession(state domain.SessionState) bool {
	return state == domain.SessionStateCompleted || state == domain.SessionStateFailed ||
		state == domain.SessionStateCancelled
}

func invalidSessionService(resource string, message string) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "manage session", Resource: resource, Message: message,
	}
}
