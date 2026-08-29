package sqlite

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"sort"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const (
	sessionRecordKind        = "session"
	interventionRecordKind   = "intervention"
	checkpointRecordKind     = "checkpoint"
	activityRecordKind       = "activity"
	promptArtifactRecordKind = "prompt-artifact"
	adapterHandleRecordKind  = "adapter-handle"
)

type CreateSessionRequest struct {
	ID               domain.SessionID
	WorkflowRunID    domain.WorkflowRunID
	NodeRunID        domain.NodeRunID
	RuntimePluginID  domain.PluginID
	RuntimeAdapterID string
	Capabilities     []string
}

type NodeExecutionContract struct {
	Adapter              string
	RequiredCapabilities []string
	JobPolicy            domain.JobPolicy
}

type BindSessionHandleRequest struct {
	SessionID       domain.SessionID
	ExpectedVersion domain.ResourceVersion
	HandleID        domain.AdapterHandleID
	FormatVersion   uint32
	OpaqueValue     json.RawMessage
	State           domain.SessionState
}

type SessionTransitionRequest struct {
	SessionID       domain.SessionID
	ExpectedVersion domain.ResourceVersion
	State           domain.SessionState
	CheckpointID    *domain.CheckpointID
	ActiveOperation *domain.OperationID
}

type CheckpointRequest struct {
	ID                  domain.CheckpointID
	SessionID           domain.SessionID
	WorkflowVersion     uint64
	EventCursor         domain.EventCursor
	OpenNodeRunIDs      []domain.NodeRunID
	ActiveHandleIDs     []domain.AdapterHandleID
	InterventionIDs     []domain.InterventionID
	UnresolvedDecisions []string
	State               json.RawMessage
}

type InterventionRequest struct {
	ID        domain.InterventionID
	SessionID domain.SessionID
	Kind      domain.InterventionKind
	Payload   json.RawMessage
	Source    string
	Deadline  *time.Time
}

type SessionHistory struct {
	Session       domain.Session        `json:"session"`
	Activities    []domain.Activity     `json:"activities"`
	Checkpoints   []domain.Checkpoint   `json:"checkpoints"`
	Interventions []domain.Intervention `json:"interventions"`
	RuntimeEvents []domain.RuntimeEvent `json:"runtimeEvents"`
}

func (store *Store) CreateSession(
	ctx context.Context,
	request CreateSessionRequest,
) (domain.Session, error) {
	if err := validateCreateSessionRequest(request); err != nil {
		return domain.Session{}, err
	}
	var created domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return conflict("create session", string(request.ID), "session already exists")
		}
		node, found, err := transaction.nodeRun(ctx, request.NodeRunID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("create session", string(request.NodeRunID), "node run does not exist")
		}
		if node.WorkflowRunID != request.WorkflowRunID || node.State != domain.NodeRunStateRunning || node.SessionID != nil {
			return conflict("create session", string(node.ID), "node run cannot accept a session")
		}
		jobPolicy, err := transaction.nodeJobPolicy(ctx, node)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		created = domain.Session{
			Metadata: newRecordMetadata(now), ID: request.ID,
			WorkflowRunID: request.WorkflowRunID, NodeRunID: request.NodeRunID,
			RuntimePluginID: request.RuntimePluginID, RuntimeAdapterID: request.RuntimeAdapterID,
			State: domain.SessionStateStarting, Capabilities: append([]string(nil), request.Capabilities...),
			JobPolicy: jobPolicy,
		}
		encoded, err := json.Marshal(created)
		if err != nil {
			return wrap("encode session", string(created.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(ctx, sessionRecordKind, string(created.ID), created.Metadata, encoded); err != nil {
			return err
		}
		node.SessionID = &created.ID
		if err := transaction.transitionNodeRun(ctx, &node, node.State, now); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(created.ID), "session.created", struct {
			WorkflowRunID domain.WorkflowRunID `json:"workflowRunId"`
			NodeRunID     domain.NodeRunID     `json:"nodeRunId"`
		}{WorkflowRunID: created.WorkflowRunID, NodeRunID: created.NodeRunID})
	})
	return created, err
}

func (store *Store) NodeExecutionContract(
	ctx context.Context,
	nodeRunID domain.NodeRunID,
) (NodeExecutionContract, error) {
	if err := nodeRunID.Validate(); err != nil {
		return NodeExecutionContract{}, err
	}
	var contract NodeExecutionContract
	err := store.Transaction(ctx, func(transaction *Tx) error {
		node, found, err := transaction.nodeRun(ctx, nodeRunID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("resolve node contract", string(nodeRunID), "node run does not exist")
		}
		run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("resolve node contract", string(node.WorkflowRunID), "workflow run does not exist")
		}
		definitionRecord, err := transaction.workflowDefinitionAtVersion(
			ctx, run.WorkflowDefinition, node.DefinitionVersion,
		)
		if err != nil {
			return err
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		nodeDefinition, found := definition.Nodes[node.NodeKey]
		if !found {
			return notFound("resolve node contract", string(node.NodeKey), "node definition does not exist")
		}
		template, found := definition.Templates[nodeDefinition.Template]
		if !found {
			return notFound("resolve node contract", string(nodeDefinition.Template), "stage template does not exist")
		}
		contract = NodeExecutionContract{
			Adapter:              nodeDefinition.Adapter,
			RequiredCapabilities: append([]string(nil), template.Capabilities.Required...),
			JobPolicy:            nodeDefinition.Policy,
		}
		return contract.JobPolicy.Validate()
	})
	return contract, err
}

func (store *Store) RefreshSessionContract(
	ctx context.Context,
	sessionID domain.SessionID,
	expectedVersion domain.ResourceVersion,
	pluginID domain.PluginID,
	adapterID string,
	capabilities []string,
) (domain.Session, error) {
	current, err := store.Session(ctx, sessionID)
	if err != nil {
		return domain.Session{}, err
	}
	contract, err := store.NodeExecutionContract(ctx, current.NodeRunID)
	if err != nil {
		return domain.Session{}, err
	}
	_, contractAdapterID := domain.ParseAdapterSelector(contract.Adapter)
	if contractAdapterID != adapterID || !capabilitiesContain(capabilities, contract.RequiredCapabilities) ||
		!capabilitiesContain(capabilities, []string{"job-policy"}) {
		return domain.Session{}, invalidSessionArgument(
			"refresh session contract", string(sessionID), "runtime does not satisfy the pinned node contract",
		)
	}
	if current.RuntimePluginID != "" && current.RuntimePluginID != pluginID {
		return domain.Session{}, invalidSessionArgument(
			"refresh session contract", string(sessionID), "runtime plugin cannot change while its handle remains active",
		)
	}
	var updated domain.Session
	err = store.Transaction(ctx, func(transaction *Tx) error {
		session, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(sessionID))
		if err != nil {
			return err
		}
		if !found {
			return notFound("refresh session contract", string(sessionID), "session does not exist")
		}
		if session.Metadata.ResourceVersion != expectedVersion {
			return conflict("refresh session contract", string(sessionID), "session version changed")
		}
		previousVersion := session.Metadata.ResourceVersion
		now := time.Now().UTC()
		session.RuntimePluginID = pluginID
		session.RuntimeAdapterID = adapterID
		session.Capabilities = append([]string(nil), capabilities...)
		session.JobPolicy = contract.JobPolicy
		session.Metadata.ResourceVersion++
		session.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(session)
		if err != nil {
			return wrap("encode refreshed session", string(sessionID), err)
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(sessionID), previousVersion, session.Metadata, encoded,
		); err != nil {
			return err
		}
		updated = session
		return appendRecordEvent(
			transaction, ctx, now, sessionRecordKind, string(sessionID), "session.contract-refreshed",
			struct {
				Adapter string `json:"adapter"`
			}{Adapter: adapterID},
		)
	})
	return updated, err
}

func capabilitiesContain(capabilities []string, required []string) bool {
	available := make(map[string]struct{}, len(capabilities))
	for _, capability := range capabilities {
		available[capability] = struct{}{}
	}
	for _, capability := range required {
		if _, found := available[capability]; !found {
			return false
		}
	}
	return true
}

func (transaction *Tx) nodeJobPolicy(ctx context.Context, node domain.NodeRun) (domain.JobPolicy, error) {
	run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
	if err != nil {
		return domain.JobPolicy{}, err
	}
	if !found {
		return domain.JobPolicy{}, notFound("resolve job policy", string(node.WorkflowRunID), "workflow run does not exist")
	}
	definitionRecord, err := transaction.workflowDefinitionAtVersion(ctx, run.WorkflowDefinition, node.DefinitionVersion)
	if err != nil {
		return domain.JobPolicy{}, err
	}
	definition, err := decodeResolvedDefinition(definitionRecord)
	if err != nil {
		return domain.JobPolicy{}, err
	}
	nodeDefinition, found := definition.Nodes[node.NodeKey]
	if !found {
		return domain.JobPolicy{}, notFound("resolve job policy", string(node.NodeKey), "node definition does not exist")
	}
	if err := nodeDefinition.Policy.Validate(); err != nil {
		return domain.JobPolicy{}, err
	}
	return nodeDefinition.Policy, nil
}

func (store *Store) BindSessionHandle(
	ctx context.Context,
	request BindSessionHandleRequest,
) (domain.Session, domain.AdapterHandle, error) {
	if err := validateBindSessionHandleRequest(request); err != nil {
		return domain.Session{}, domain.AdapterHandle{}, err
	}
	var updated domain.Session
	var handle domain.AdapterHandle
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](
			transaction, ctx, sessionRecordKind, string(request.SessionID),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("bind session handle", string(request.SessionID), "session does not exist")
		}
		if current.Metadata.ResourceVersion != request.ExpectedVersion || current.State != domain.SessionStateStarting ||
			current.RuntimeHandle != nil {
			return conflict("bind session handle", string(current.ID), "session version or state changed")
		}
		if _, found, err := typedRecord[domain.AdapterHandle](
			transaction, ctx, adapterHandleRecordKind, string(request.HandleID),
		); err != nil {
			return err
		} else if found {
			return conflict("bind session handle", string(request.HandleID), "adapter handle already exists")
		}
		now := time.Now().UTC()
		handle = domain.AdapterHandle{
			Metadata: newRecordMetadata(now), ID: request.HandleID, PluginID: current.RuntimePluginID,
			Owner: domain.ResourceReference{Kind: sessionRecordKind, ID: string(current.ID)},
			Port:  domain.AdapterPortAgentRuntime, AdapterID: current.RuntimeAdapterID,
			FormatVersion: request.FormatVersion,
			OpaqueValue:   append(json.RawMessage(nil), request.OpaqueValue...),
		}
		handlePayload, err := json.Marshal(handle)
		if err != nil {
			return wrap("encode adapter handle", string(handle.ID), err)
		}
		updated = current
		updated.RuntimeHandle = &handle.ID
		updated.HandleFormatVersion = handle.FormatVersion
		updated.State = request.State
		if updated.State == "" {
			updated.State = domain.SessionStateRunning
		}
		updated.ActiveOperationID = nil
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = now
		sessionPayload, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode session handle", string(updated.ID), err)
		}
		if err := transaction.reserveRecordBytes(
			ctx, uint64(len(handlePayload)+len(sessionPayload)), 2,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, adapterHandleRecordKind, string(handle.ID), handle.Metadata, handlePayload,
		); err != nil {
			return err
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(updated.ID), request.ExpectedVersion, updated.Metadata, sessionPayload,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(updated.ID), "session.handle.bound", struct {
			HandleID      domain.AdapterHandleID `json:"handleId"`
			FormatVersion uint32                 `json:"formatVersion"`
		}{HandleID: handle.ID, FormatVersion: handle.FormatVersion})
	})
	return updated, handle, err
}

func (store *Store) AdapterHandle(
	ctx context.Context,
	id domain.AdapterHandleID,
) (domain.AdapterHandle, error) {
	if err := id.Validate(); err != nil {
		return domain.AdapterHandle{}, err
	}
	var handle domain.AdapterHandle
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		handle, found, err = typedRecord[domain.AdapterHandle](
			transaction, ctx, adapterHandleRecordKind, string(id),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("read adapter handle", string(id), "adapter handle does not exist")
		}
		return nil
	})
	return handle, err
}

func (store *Store) CreateAdapterHandle(
	ctx context.Context,
	handle domain.AdapterHandle,
) (domain.AdapterHandle, error) {
	if err := validateAdapterHandle(handle); err != nil {
		return domain.AdapterHandle{}, err
	}
	var created domain.AdapterHandle
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.AdapterHandle](
			transaction, ctx, adapterHandleRecordKind, string(handle.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("create adapter handle", string(handle.ID), "adapter handle already exists")
		}
		now := time.Now().UTC()
		created = handle
		created.Metadata = newRecordMetadata(now)
		created.OpaqueValue = append(json.RawMessage(nil), handle.OpaqueValue...)
		payload, err := json.Marshal(created)
		if err != nil {
			return wrap("encode adapter handle", string(created.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, payload); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, adapterHandleRecordKind, string(created.ID), created.Metadata, payload,
		); err != nil {
			return err
		}
		return appendRecordEvent(
			transaction, ctx, now, adapterHandleRecordKind, string(created.ID), "adapter-handle.created",
			struct {
				HandleID      domain.AdapterHandleID `json:"handleId"`
				FormatVersion uint32                 `json:"formatVersion"`
			}{HandleID: created.ID, FormatVersion: created.FormatVersion},
		)
	})
	return created, err
}

func (store *Store) AdapterHandles(ctx context.Context) ([]domain.AdapterHandle, error) {
	var handles []domain.AdapterHandle
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		handles, err = typedRecords[domain.AdapterHandle](transaction, ctx, adapterHandleRecordKind)
		return err
	})
	return handles, err
}

func (store *Store) RecoverableAdapterHandles(ctx context.Context) ([]domain.AdapterHandle, error) {
	var handles []domain.AdapterHandle
	err := store.Transaction(ctx, func(transaction *Tx) error {
		stored, err := typedRecords[domain.AdapterHandle](transaction, ctx, adapterHandleRecordKind)
		if err != nil {
			return err
		}
		sessions, err := typedRecords[domain.Session](transaction, ctx, sessionRecordKind)
		if err != nil {
			return err
		}
		sessionHandles := make(map[domain.AdapterHandleID]bool)
		sessionStates := make(map[domain.SessionID]domain.SessionState, len(sessions))
		for _, session := range sessions {
			sessionStates[session.ID] = session.State
			if session.RuntimeHandle == nil {
				continue
			}
			recoverable := session.State == domain.SessionStateStarting ||
				session.State == domain.SessionStateRunning || session.State == domain.SessionStateWaiting ||
				session.State == domain.SessionStateOrphaned
			sessionHandles[*session.RuntimeHandle] = recoverable
		}
		runs, err := typedRecords[domain.WorkflowRun](transaction, ctx, workflowRunRecordKind)
		if err != nil {
			return err
		}
		runStates := make(map[domain.WorkflowRunID]domain.WorkflowRunState, len(runs))
		for _, run := range runs {
			runStates[run.ID] = run.State
		}
		for _, handle := range stored {
			recoverable, belongsToSession := sessionHandles[handle.ID]
			if belongsToSession && recoverable {
				handles = append(handles, handle)
				continue
			}
			if belongsToSession {
				continue
			}
			switch handle.Owner.Kind {
			case sessionRecordKind:
				state, found := sessionStates[domain.SessionID(handle.Owner.ID)]
				if found && !terminalSessionState(state) {
					handles = append(handles, handle)
				}
			case workflowRunRecordKind:
				state, found := runStates[domain.WorkflowRunID(handle.Owner.ID)]
				if found && !workflowRunIsTerminal(state) {
					handles = append(handles, handle)
				}
			}
		}
		return nil
	})
	return handles, err
}

func (store *Store) TransitionSession(
	ctx context.Context,
	request SessionTransitionRequest,
) (domain.Session, error) {
	if err := validateSessionTransitionRequest(request); err != nil {
		return domain.Session{}, err
	}
	var updated domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](
			transaction, ctx, sessionRecordKind, string(request.SessionID),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("transition session", string(request.SessionID), "session does not exist")
		}
		if current.Metadata.ResourceVersion != request.ExpectedVersion || !validSessionTransition(current.State, request.State) {
			return conflict("transition session", string(current.ID), "session version or transition changed")
		}
		if request.CheckpointID != nil {
			checkpoint, found, err := typedRecord[domain.Checkpoint](
				transaction, ctx, checkpointRecordKind, string(*request.CheckpointID),
			)
			if err != nil {
				return err
			}
			if !found || checkpoint.SessionID != current.ID {
				return conflict("transition session", string(*request.CheckpointID), "checkpoint does not belong to session")
			}
		}
		now := time.Now().UTC()
		updated = current
		updated.State = request.State
		updated.CheckpointID = request.CheckpointID
		updated.ActiveOperationID = request.ActiveOperation
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode session transition", string(updated.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(updated.ID), request.ExpectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		if err := transaction.updateNodeForSessionState(ctx, updated, now); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(updated.ID), "session.state.changed", struct {
			State domain.SessionState `json:"state"`
		}{State: updated.State})
	})
	return updated, err
}

func (store *Store) SetSessionOperation(
	ctx context.Context,
	id domain.SessionID,
	expectedVersion domain.ResourceVersion,
	operationID *domain.OperationID,
) (domain.Session, error) {
	if err := id.Validate(); err != nil {
		return domain.Session{}, err
	}
	if expectedVersion == 0 {
		return domain.Session{}, invalidSessionArgument("set session operation", string(id), "version is required")
	}
	if operationID != nil {
		if err := operationID.Validate(); err != nil {
			return domain.Session{}, err
		}
	}
	var updated domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("set session operation", string(id), "session does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion || terminalSessionState(current.State) ||
			(current.ActiveOperationID != nil && operationID != nil) {
			return conflict("set session operation", string(id), "session version, state, or active operation changed")
		}
		updated = current
		updated.ActiveOperationID = operationID
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = time.Now().UTC()
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode session operation", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(
			transaction, ctx, updated.Metadata.UpdatedAt, sessionRecordKind, string(id),
			"session.operation.changed", struct {
				OperationID *domain.OperationID `json:"operationId,omitempty"`
			}{OperationID: operationID},
		)
	})
	return updated, err
}

func (store *Store) SetSessionJobPolicy(
	ctx context.Context,
	id domain.SessionID,
	expectedVersion domain.ResourceVersion,
	policy domain.JobPolicy,
) (domain.Session, error) {
	if err := id.Validate(); err != nil {
		return domain.Session{}, err
	}
	if expectedVersion == 0 {
		return domain.Session{}, invalidSessionArgument("set session job policy", string(id), "version is required")
	}
	if err := policy.Validate(); err != nil {
		return domain.Session{}, err
	}
	var updated domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("set session job policy", string(id), "session does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion || terminalSessionState(current.State) ||
			current.ActiveOperationID != nil {
			return conflict("set session job policy", string(id), "session version, state, or operation changed")
		}
		updated = current
		updated.JobPolicy = policy
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = time.Now().UTC()
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode session job policy", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(
			transaction, ctx, updated.Metadata.UpdatedAt, sessionRecordKind, string(id),
			"session.job-policy.changed", policy,
		)
	})
	return updated, err
}

func (store *Store) RecordSessionRuntimeEvents(
	ctx context.Context,
	id domain.SessionID,
	expectedVersion domain.ResourceVersion,
	events []domain.RuntimeEvent,
) (domain.Session, error) {
	if err := id.Validate(); err != nil {
		return domain.Session{}, err
	}
	if expectedVersion == 0 || len(events) == 0 {
		return domain.Session{}, invalidSessionArgument(
			"record runtime events", string(id), "version and events are required",
		)
	}
	var updated domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("record runtime events", string(id), "session does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion {
			return conflict("record runtime events", string(id), "session version changed")
		}
		nextSequence := current.RuntimeEventCursor + 1
		for _, event := range events {
			if !validRuntimeEvent(event, nextSequence) {
				return invalidSessionArgument(
					"record runtime events", string(id), "runtime events are invalid or out of order",
				)
			}
			nextSequence++
		}
		now := time.Now().UTC()
		updated = current
		updated.RuntimeEventCursor = events[len(events)-1].Sequence
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode runtime event cursor", string(id), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		for _, event := range events {
			if err := appendRecordEvent(
				transaction, ctx, event.OccurredAt.UTC(), sessionRecordKind, string(id),
				"session.runtime.event", event,
			); err != nil {
				return err
			}
		}
		return nil
	})
	return updated, err
}

func validRuntimeEvent(event domain.RuntimeEvent, expectedSequence uint64) bool {
	return event.Sequence == expectedSequence && event.Kind != "" && event.ProviderEventType != "" &&
		!event.OccurredAt.IsZero() && json.Valid(event.Data)
}

func (store *Store) Session(ctx context.Context, id domain.SessionID) (domain.Session, error) {
	if err := id.Validate(); err != nil {
		return domain.Session{}, err
	}
	var session domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		session, found, err = typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("read session", string(id), "session does not exist")
		}
		return nil
	})
	return session, err
}

func (store *Store) Sessions(ctx context.Context) ([]domain.Session, error) {
	var sessions []domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		sessions, err = typedRecords[domain.Session](transaction, ctx, sessionRecordKind)
		return err
	})
	if err != nil {
		return nil, err
	}
	sort.Slice(sessions, func(first int, second int) bool {
		return sessions[first].Metadata.UpdatedAt.After(sessions[second].Metadata.UpdatedAt)
	})
	return sessions, nil
}

func (store *Store) ActiveSessions(ctx context.Context) ([]domain.Session, error) {
	return store.sessionsForRecovery(ctx, false)
}

func (store *Store) RecoverableSessions(ctx context.Context) ([]domain.Session, error) {
	return store.sessionsForRecovery(ctx, true)
}

func (store *Store) sessionsForRecovery(
	ctx context.Context,
	includeOrphaned bool,
) ([]domain.Session, error) {
	var sessions []domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		sessions, err = typedRecords[domain.Session](transaction, ctx, sessionRecordKind)
		return err
	})
	if err != nil {
		return nil, err
	}
	active := sessions[:0]
	for _, session := range sessions {
		if session.State == domain.SessionStateStarting || session.State == domain.SessionStateRunning ||
			session.State == domain.SessionStateWaiting || includeOrphaned && session.State == domain.SessionStateOrphaned {
			active = append(active, session)
		}
	}
	return active, nil
}

func (transaction *Tx) updateNodeForSessionState(
	ctx context.Context,
	session domain.Session,
	now time.Time,
) error {
	node, found, err := transaction.nodeRun(ctx, session.NodeRunID)
	if err != nil {
		return err
	}
	if !found || node.SessionID == nil || *node.SessionID != session.ID {
		return &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "transition session", Resource: string(session.ID),
			Message: "session node lineage is unavailable",
		}
	}
	target := node.State
	switch session.State {
	case domain.SessionStateRunning:
		target = domain.NodeRunStateRunning
	case domain.SessionStateWaiting, domain.SessionStateCompleted, domain.SessionStateOrphaned:
		target = domain.NodeRunStateWaiting
	case domain.SessionStateFailed:
		target = domain.NodeRunStateFailed
	case domain.SessionStateCancelled:
		target = domain.NodeRunStateCancelled
	}
	if target == node.State {
		return nil
	}
	return transaction.transitionNodeRun(ctx, &node, target, now)
}

func (store *Store) ReconcileSession(
	ctx context.Context,
	id domain.SessionID,
	expectedVersion domain.ResourceVersion,
	state domain.SessionReconciliationState,
) (domain.Session, error) {
	if err := id.Validate(); err != nil {
		return domain.Session{}, err
	}
	if expectedVersion == 0 || !state.Valid() {
		return domain.Session{}, invalidSessionArgument("reconcile session", string(id), "version and reconciliation state are required")
	}
	target := domain.SessionState("")
	switch state {
	case domain.SessionReconciliationAdopted, domain.SessionReconciliationRehydrated:
		target = domain.SessionStateRunning
	case domain.SessionReconciliationCompleted:
		target = domain.SessionStateCompleted
	case domain.SessionReconciliationOrphaned:
		target = domain.SessionStateOrphaned
	default:
		return domain.Session{}, invalidSessionArgument("reconcile session", string(id), "reconciliation state is invalid")
	}
	var updated domain.Session
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("reconcile session", string(id), "session does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion || terminalSessionState(current.State) {
			return conflict("reconcile session", string(id), "session version or state changed")
		}
		if current.State != target && !validSessionTransition(current.State, target) {
			return conflict("reconcile session", string(id), "reconciled session transition is invalid")
		}
		now := time.Now().UTC()
		updated = current
		updated.State = target
		updated.ActiveOperationID = nil
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode reconciled session", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, sessionRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		if err := transaction.updateNodeForSessionState(ctx, updated, now); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			Outcome domain.SessionReconciliationState `json:"outcome"`
			State   domain.SessionState               `json:"state"`
		}{Outcome: state, State: target})
		if err != nil {
			return wrap("encode session reconciliation", string(id), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: sessionRecordKind, ID: string(id)},
			Type:      "session.reconciled", Payload: payload,
		})
		return err
	})
	return updated, err
}

func (store *Store) StorePromptArtifact(
	ctx context.Context,
	mediaType string,
	templateDigest string,
	secretNames []string,
	content []byte,
) (domain.PromptArtifact, error) {
	if mediaType == "" || len(content) == 0 || !uniqueNonemptyStrings(secretNames) {
		return domain.PromptArtifact{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "store prompt", Resource: mediaType,
			Message: "media type, content, and unique secret names are required",
		}
	}
	contentDigest := sha256.Sum256(content)
	digest := fmt.Sprintf("sha256:%x", contentDigest[:])
	id := domain.PromptArtifactID("prompt-" + fmt.Sprintf("%x", contentDigest[:]))
	var artifact domain.PromptArtifact
	err := store.Transaction(ctx, func(transaction *Tx) error {
		existing, found, err := typedRecord[domain.PromptArtifact](
			transaction, ctx, promptArtifactRecordKind, string(id),
		)
		if err != nil {
			return err
		}
		if found {
			if existing.Digest != digest || existing.MediaType != mediaType ||
				existing.TemplateDigest != templateDigest || !equalStrings(existing.SecretNames, secretNames) ||
				!bytes.Equal(existing.Content, content) {
				return conflict("store prompt", string(id), "prompt metadata differs for existing content")
			}
			artifact = existing
			return nil
		}
		now := time.Now().UTC()
		artifact = domain.PromptArtifact{
			Metadata: newRecordMetadata(now), ID: id, Digest: digest, TemplateDigest: templateDigest,
			MediaType: mediaType, ByteSize: uint64(len(content)),
			SecretNames: append([]string(nil), secretNames...), Content: append([]byte(nil), content...),
		}
		encoded, err := json.Marshal(artifact)
		if err != nil {
			return wrap("encode prompt artifact", string(id), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, promptArtifactRecordKind, string(id), artifact.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, promptArtifactRecordKind, string(id), "prompt.stored", struct {
			Digest   string `json:"digest"`
			ByteSize uint64 `json:"byteSize"`
		}{Digest: digest, ByteSize: artifact.ByteSize})
	})
	return artifact, err
}

func (store *Store) PromptArtifact(
	ctx context.Context,
	id domain.PromptArtifactID,
) (domain.PromptArtifact, error) {
	if err := id.Validate(); err != nil {
		return domain.PromptArtifact{}, err
	}
	var artifact domain.PromptArtifact
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		artifact, found, err = typedRecord[domain.PromptArtifact](
			transaction, ctx, promptArtifactRecordKind, string(id),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("read prompt artifact", string(id), "prompt artifact does not exist")
		}
		return nil
	})
	return artifact, err
}

func (store *Store) RecordActivity(ctx context.Context, activity domain.Activity) (domain.Activity, error) {
	if err := validateActivityInput(activity); err != nil {
		return domain.Activity{}, err
	}
	var recorded domain.Activity
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.Activity](
			transaction, ctx, activityRecordKind, string(activity.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("record activity", string(activity.ID), "activity already exists")
		}
		if err := transaction.validateActivityLineage(ctx, activity); err != nil {
			return err
		}
		now := time.Now().UTC()
		recorded = activity
		recorded.Metadata = newRecordMetadata(now)
		encoded, err := json.Marshal(recorded)
		if err != nil {
			return wrap("encode activity", string(recorded.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, activityRecordKind, string(recorded.ID), recorded.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, activityRecordKind, string(recorded.ID), "activity.recorded", struct {
			Kind      domain.ActivityKind `json:"kind"`
			SessionID *domain.SessionID   `json:"sessionId,omitempty"`
		}{Kind: recorded.Kind, SessionID: recorded.SessionID})
	})
	return recorded, err
}

func (store *Store) CompleteActivity(
	ctx context.Context,
	id domain.ActivityID,
	expectedVersion domain.ResourceVersion,
	endedAt time.Time,
) (domain.Activity, error) {
	if err := id.Validate(); err != nil {
		return domain.Activity{}, err
	}
	if expectedVersion == 0 || endedAt.IsZero() {
		return domain.Activity{}, invalidSessionArgument("complete activity", string(id), "version and end time are required")
	}
	var updated domain.Activity
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Activity](transaction, ctx, activityRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("complete activity", string(id), "activity does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion || current.EndedAt != nil || endedAt.Before(current.StartedAt) {
			return conflict("complete activity", string(id), "activity version, state, or end time is invalid")
		}
		updated = current
		ended := endedAt.UTC()
		updated.EndedAt = &ended
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = time.Now().UTC()
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode completed activity", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, activityRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(
			transaction, ctx, updated.Metadata.UpdatedAt, activityRecordKind, string(id),
			"activity.completed", struct {
				EndedAt time.Time `json:"endedAt"`
			}{EndedAt: ended},
		)
	})
	return updated, err
}

func (store *Store) CreateCheckpoint(
	ctx context.Context,
	request CheckpointRequest,
) (domain.Checkpoint, error) {
	if err := validateCheckpointRequest(request); err != nil {
		return domain.Checkpoint{}, err
	}
	var checkpoint domain.Checkpoint
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.Checkpoint](
			transaction, ctx, checkpointRecordKind, string(request.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("create checkpoint", string(request.ID), "checkpoint already exists")
		}
		session, found, err := typedRecord[domain.Session](
			transaction, ctx, sessionRecordKind, string(request.SessionID),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("create checkpoint", string(request.SessionID), "session does not exist")
		}
		if err := transaction.validateCheckpointReferences(ctx, session, request); err != nil {
			return err
		}
		now := time.Now().UTC()
		checkpoint = domain.Checkpoint{
			Metadata: newRecordMetadata(now), ID: request.ID, SessionID: request.SessionID,
			WorkflowVersion: request.WorkflowVersion, EventCursor: request.EventCursor,
			OpenNodeRunIDs:      append([]domain.NodeRunID(nil), request.OpenNodeRunIDs...),
			ActiveHandleIDs:     append([]domain.AdapterHandleID(nil), request.ActiveHandleIDs...),
			InterventionIDs:     append([]domain.InterventionID(nil), request.InterventionIDs...),
			UnresolvedDecisions: append([]string(nil), request.UnresolvedDecisions...),
			State:               append(json.RawMessage(nil), request.State...),
		}
		encoded, err := json.Marshal(checkpoint)
		if err != nil {
			return wrap("encode checkpoint", string(checkpoint.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, checkpointRecordKind, string(checkpoint.ID), checkpoint.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(session.ID), "session.checkpoint.created", struct {
			CheckpointID domain.CheckpointID `json:"checkpointId"`
			EventCursor  domain.EventCursor  `json:"eventCursor"`
		}{CheckpointID: checkpoint.ID, EventCursor: checkpoint.EventCursor})
	})
	return checkpoint, err
}

func (store *Store) RecordIntervention(
	ctx context.Context,
	request InterventionRequest,
) (domain.Intervention, error) {
	if err := validateInterventionRequest(request); err != nil {
		return domain.Intervention{}, err
	}
	var intervention domain.Intervention
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := typedRecord[domain.Intervention](
			transaction, ctx, interventionRecordKind, string(request.ID),
		); err != nil {
			return err
		} else if found {
			return conflict("record intervention", string(request.ID), "intervention already exists")
		}
		if _, found, err := typedRecord[domain.Session](
			transaction, ctx, sessionRecordKind, string(request.SessionID),
		); err != nil {
			return err
		} else if !found {
			return notFound("record intervention", string(request.SessionID), "session does not exist")
		}
		now := time.Now().UTC()
		intervention = domain.Intervention{
			Metadata: newRecordMetadata(now), ID: request.ID, SessionID: request.SessionID,
			Kind: request.Kind, State: domain.InterventionStateRecorded,
			Payload: append(json.RawMessage(nil), request.Payload...), Source: request.Source,
			Authority: domain.AuthorityOwner, Deadline: request.Deadline, RecordedAt: now,
		}
		encoded, err := json.Marshal(intervention)
		if err != nil {
			return wrap("encode intervention", string(intervention.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, interventionRecordKind, string(intervention.ID), intervention.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(request.SessionID), "session.intervention.recorded", struct {
			InterventionID domain.InterventionID   `json:"interventionId"`
			Kind           domain.InterventionKind `json:"kind"`
		}{InterventionID: intervention.ID, Kind: intervention.Kind})
	})
	return intervention, err
}

func (store *Store) TransitionIntervention(
	ctx context.Context,
	id domain.InterventionID,
	expectedVersion domain.ResourceVersion,
	state domain.InterventionState,
) (domain.Intervention, error) {
	if err := id.Validate(); err != nil {
		return domain.Intervention{}, err
	}
	if expectedVersion == 0 || !state.Valid() {
		return domain.Intervention{}, invalidSessionArgument(
			"transition intervention", string(id), "version and state are required",
		)
	}
	var updated domain.Intervention
	err := store.Transaction(ctx, func(transaction *Tx) error {
		current, found, err := typedRecord[domain.Intervention](
			transaction, ctx, interventionRecordKind, string(id),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("transition intervention", string(id), "intervention does not exist")
		}
		if current.Metadata.ResourceVersion != expectedVersion || !validInterventionTransition(current.State, state) {
			return conflict("transition intervention", string(id), "intervention version or transition changed")
		}
		now := time.Now().UTC()
		updated = current
		updated.State = state
		updated.Metadata.ResourceVersion++
		updated.Metadata.UpdatedAt = now
		if state == domain.InterventionStateForwarded {
			updated.ForwardedAt = &now
		}
		if state == domain.InterventionStateCompleted || state == domain.InterventionStateFailed {
			updated.CompletedAt = &now
		}
		encoded, err := json.Marshal(updated)
		if err != nil {
			return wrap("encode intervention transition", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, interventionRecordKind, string(id), expectedVersion, updated.Metadata, encoded,
		); err != nil {
			return err
		}
		return appendRecordEvent(transaction, ctx, now, sessionRecordKind, string(updated.SessionID), "session.intervention.changed", struct {
			InterventionID domain.InterventionID    `json:"interventionId"`
			State          domain.InterventionState `json:"state"`
		}{InterventionID: id, State: state})
	})
	return updated, err
}

func (store *Store) SessionHistory(ctx context.Context, id domain.SessionID) (SessionHistory, error) {
	if err := id.Validate(); err != nil {
		return SessionHistory{}, err
	}
	var history SessionHistory
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		history.Session, found, err = typedRecord[domain.Session](transaction, ctx, sessionRecordKind, string(id))
		if err != nil {
			return err
		}
		if !found {
			return notFound("read session history", string(id), "session does not exist")
		}
		activities, err := typedRecords[domain.Activity](transaction, ctx, activityRecordKind)
		if err != nil {
			return err
		}
		for _, activity := range activities {
			if activity.SessionID != nil && *activity.SessionID == id {
				history.Activities = append(history.Activities, activity)
			}
		}
		checkpoints, err := typedRecords[domain.Checkpoint](transaction, ctx, checkpointRecordKind)
		if err != nil {
			return err
		}
		for _, checkpoint := range checkpoints {
			if checkpoint.SessionID == id {
				history.Checkpoints = append(history.Checkpoints, checkpoint)
			}
		}
		interventions, err := typedRecords[domain.Intervention](transaction, ctx, interventionRecordKind)
		if err != nil {
			return err
		}
		for _, intervention := range interventions {
			if intervention.SessionID == id {
				history.Interventions = append(history.Interventions, intervention)
			}
		}
		rows, err := transaction.tx.QueryContext(
			ctx,
			"SELECT payload FROM events WHERE aggregate_kind = ? AND aggregate_id = ? AND event_type = ? ORDER BY cursor",
			sessionRecordKind, string(id), "session.runtime.event",
		)
		if err != nil {
			return wrap("read session runtime events", string(id), err)
		}
		defer rows.Close()
		for rows.Next() {
			var payload []byte
			if err := rows.Scan(&payload); err != nil {
				return wrap("scan session runtime event", string(id), err)
			}
			var event domain.RuntimeEvent
			if err := json.Unmarshal(payload, &event); err != nil {
				return wrap("decode session runtime event", string(id), err)
			}
			history.RuntimeEvents = append(history.RuntimeEvents, event)
		}
		if err := rows.Err(); err != nil {
			return wrap("iterate session runtime events", string(id), err)
		}
		return nil
	})
	return history, err
}

type sessionStoredRecord interface {
	domain.Session | domain.WorkflowRun | domain.AdapterHandle | domain.PromptArtifact | domain.Activity |
		domain.Checkpoint | domain.Intervention | domain.CommitObservation |
		domain.ProvenanceRelation | domain.Annotation | domain.AnnotationReply | domain.RestartPoint | domain.RunFork
}

func typedRecord[Record sessionStoredRecord](
	transaction *Tx,
	ctx context.Context,
	kind string,
	id string,
) (Record, bool, error) {
	var record Record
	payload, found, err := transaction.recordPayload(ctx, kind, id)
	if err != nil || !found {
		return record, found, err
	}
	if err := json.Unmarshal(payload, &record); err != nil {
		return record, false, wrap("decode record", kind+":"+id, err)
	}
	return record, true, nil
}

func typedRecords[Record sessionStoredRecord](
	transaction *Tx,
	ctx context.Context,
	kind string,
) ([]Record, error) {
	rows, err := transaction.tx.QueryContext(
		ctx, "SELECT payload FROM records WHERE kind = ? ORDER BY created_at, id", kind,
	)
	if err != nil {
		return nil, wrap("read records", kind, err)
	}
	defer rows.Close()
	records := make([]Record, 0)
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return nil, wrap("scan record", kind, err)
		}
		var record Record
		if err := json.Unmarshal(payload, &record); err != nil {
			return nil, wrap("decode record", kind, err)
		}
		records = append(records, record)
	}
	if err := rows.Err(); err != nil {
		return nil, wrap("iterate records", kind, err)
	}
	return records, nil
}

func appendRecordEvent[Payload jsonRecordPayload](
	transaction *Tx,
	ctx context.Context,
	now time.Time,
	kind string,
	id string,
	eventType string,
	value Payload,
) error {
	payload, err := json.Marshal(value)
	if err != nil {
		return wrap("encode event", eventType, err)
	}
	_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
		Aggregate: domain.ResourceReference{Kind: kind, ID: id}, Type: eventType, Payload: payload,
	})
	return err
}

type jsonRecordPayload interface {
	struct {
		WorkflowRunID domain.WorkflowRunID `json:"workflowRunId"`
		NodeRunID     domain.NodeRunID     `json:"nodeRunId"`
	} | struct {
		HandleID      domain.AdapterHandleID `json:"handleId"`
		FormatVersion uint32                 `json:"formatVersion"`
	} | struct {
		State domain.SessionState `json:"state"`
	} | struct {
		OperationID *domain.OperationID `json:"operationId,omitempty"`
	} | struct {
		Digest   string `json:"digest"`
		ByteSize uint64 `json:"byteSize"`
	} | struct {
		Kind      domain.ActivityKind `json:"kind"`
		SessionID *domain.SessionID   `json:"sessionId,omitempty"`
	} | struct {
		EndedAt time.Time `json:"endedAt"`
	} | struct {
		CheckpointID domain.CheckpointID `json:"checkpointId"`
		EventCursor  domain.EventCursor  `json:"eventCursor"`
	} | struct {
		InterventionID domain.InterventionID   `json:"interventionId"`
		Kind           domain.InterventionKind `json:"kind"`
	} | struct {
		InterventionID domain.InterventionID    `json:"interventionId"`
		State          domain.InterventionState `json:"state"`
	} | struct {
		Adapter string `json:"adapter"`
	} | domain.JobPolicy | domain.RuntimeEvent
}

func (transaction *Tx) validateActivityLineage(ctx context.Context, activity domain.Activity) error {
	run, found, err := transaction.workflowRun(ctx, activity.WorkflowRunID)
	if err != nil {
		return err
	}
	if !found {
		return notFound("record activity", string(activity.WorkflowRunID), "workflow run does not exist")
	}
	_ = run
	if activity.NodeRunID != nil {
		node, found, err := transaction.nodeRun(ctx, *activity.NodeRunID)
		if err != nil {
			return err
		}
		if !found || node.WorkflowRunID != activity.WorkflowRunID {
			return conflict("record activity", string(*activity.NodeRunID), "node activity lineage is invalid")
		}
	}
	if activity.SessionID != nil {
		session, found, err := typedRecord[domain.Session](
			transaction, ctx, sessionRecordKind, string(*activity.SessionID),
		)
		if err != nil {
			return err
		}
		if !found || session.WorkflowRunID != activity.WorkflowRunID || activity.NodeRunID == nil ||
			session.NodeRunID != *activity.NodeRunID {
			return conflict("record activity", string(*activity.SessionID), "session activity lineage is invalid")
		}
	}
	var parent *domain.Activity
	if activity.ParentID != nil {
		record, found, err := typedRecord[domain.Activity](
			transaction, ctx, activityRecordKind, string(*activity.ParentID),
		)
		if err != nil {
			return err
		}
		if !found {
			return notFound("record activity", string(*activity.ParentID), "parent activity does not exist")
		}
		parent = &record
	}
	if !validActivityParent(activity, parent) {
		return conflict("record activity", string(activity.ID), "activity parent does not match its kind")
	}
	if activity.PromptArtifactID != nil {
		if _, found, err := typedRecord[domain.PromptArtifact](
			transaction, ctx, promptArtifactRecordKind, string(*activity.PromptArtifactID),
		); err != nil {
			return err
		} else if !found {
			return notFound("record activity", string(*activity.PromptArtifactID), "prompt artifact does not exist")
		}
	}
	return nil
}

func (transaction *Tx) validateCheckpointReferences(
	ctx context.Context,
	session domain.Session,
	request CheckpointRequest,
) error {
	run, found, err := transaction.workflowRun(ctx, session.WorkflowRunID)
	if err != nil {
		return err
	}
	if !found || run.DefinitionVersion != request.WorkflowVersion {
		return conflict("create checkpoint", string(request.ID), "workflow version does not match session run")
	}
	var lastCursor domain.EventCursor
	if err := transaction.tx.QueryRowContext(
		ctx, "SELECT COALESCE(MAX(cursor), 0) FROM events",
	).Scan(&lastCursor); err != nil {
		return wrap("read checkpoint event cursor", string(request.ID), err)
	}
	if request.EventCursor > lastCursor {
		return conflict("create checkpoint", string(request.ID), "checkpoint event cursor is in the future")
	}
	for _, nodeID := range request.OpenNodeRunIDs {
		node, found, err := transaction.nodeRun(ctx, nodeID)
		if err != nil {
			return err
		}
		if !found || node.WorkflowRunID != session.WorkflowRunID || terminalNodeState(node.State) {
			return conflict("create checkpoint", string(nodeID), "open node reference is invalid")
		}
	}
	for _, handleID := range request.ActiveHandleIDs {
		handle, found, err := typedRecord[domain.AdapterHandle](
			transaction, ctx, adapterHandleRecordKind, string(handleID),
		)
		if err != nil {
			return err
		}
		if !found || handle.PluginID != session.RuntimePluginID {
			return conflict("create checkpoint", string(handleID), "active handle reference is invalid")
		}
	}
	for _, interventionID := range request.InterventionIDs {
		intervention, found, err := typedRecord[domain.Intervention](
			transaction, ctx, interventionRecordKind, string(interventionID),
		)
		if err != nil {
			return err
		}
		if !found || intervention.SessionID != session.ID {
			return conflict("create checkpoint", string(interventionID), "intervention reference is invalid")
		}
	}
	return nil
}

func validateCreateSessionRequest(request CreateSessionRequest) error {
	for _, err := range []error{
		request.ID.Validate(), request.WorkflowRunID.Validate(), request.NodeRunID.Validate(), request.RuntimePluginID.Validate(),
	} {
		if err != nil {
			return err
		}
	}
	if request.RuntimeAdapterID == "" || !uniqueNonemptyStrings(request.Capabilities) {
		return invalidSessionArgument(
			"create session", string(request.ID), "runtime adapter and unique capabilities are required",
		)
	}
	if err := (domain.ResourceReference{Kind: "runtime-adapter", ID: request.RuntimeAdapterID}).Validate(); err != nil {
		return err
	}
	return nil
}

func validateBindSessionHandleRequest(request BindSessionHandleRequest) error {
	for _, err := range []error{request.SessionID.Validate(), request.HandleID.Validate()} {
		if err != nil {
			return err
		}
	}
	if request.ExpectedVersion == 0 || request.FormatVersion == 0 || !json.Valid(request.OpaqueValue) {
		return invalidSessionArgument(
			"bind session handle", string(request.SessionID), "version, handle format, and opaque JSON are required",
		)
	}
	if request.State != "" && request.State != domain.SessionStateRunning &&
		request.State != domain.SessionStateWaiting && request.State != domain.SessionStateCompleted {
		return invalidSessionArgument(
			"bind session handle", string(request.SessionID), "initial session state is invalid",
		)
	}
	return nil
}

func validateAdapterHandle(handle domain.AdapterHandle) error {
	for _, err := range []error{handle.ID.Validate(), handle.PluginID.Validate(), handle.Owner.Validate()} {
		if err != nil {
			return err
		}
	}
	if !handle.Port.Valid() || handle.AdapterID == "" || handle.FormatVersion == 0 ||
		!json.Valid(handle.OpaqueValue) {
		return invalidSessionArgument(
			"create adapter handle", string(handle.ID),
			"plugin, port, adapter, format, and opaque JSON are required",
		)
	}
	if err := (domain.ResourceReference{Kind: "adapter", ID: handle.AdapterID}).Validate(); err != nil {
		return err
	}
	return nil
}

func validateSessionTransitionRequest(request SessionTransitionRequest) error {
	if err := request.SessionID.Validate(); err != nil {
		return err
	}
	if request.ExpectedVersion == 0 || !request.State.Valid() {
		return invalidSessionArgument(
			"transition session", string(request.SessionID), "version and state are required",
		)
	}
	if request.CheckpointID != nil {
		if err := request.CheckpointID.Validate(); err != nil {
			return err
		}
	}
	if request.ActiveOperation != nil {
		if err := request.ActiveOperation.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func validateActivityInput(activity domain.Activity) error {
	if err := activity.ID.Validate(); err != nil {
		return err
	}
	if err := activity.WorkflowRunID.Validate(); err != nil {
		return err
	}
	if !activity.Kind.Valid() || !activity.Basis.Valid() || !activity.Authority.Valid() || activity.StartedAt.IsZero() {
		return invalidSessionArgument("record activity", string(activity.ID), "activity kind, provenance, authority, and start time are required")
	}
	if activity.EndedAt != nil && activity.EndedAt.Before(activity.StartedAt) {
		return invalidSessionArgument("record activity", string(activity.ID), "activity end time precedes its start")
	}
	if activity.Basis == domain.ProvenanceBasisAdapterReported && activity.Authority != domain.AuthorityAdvisory {
		return invalidSessionArgument("record activity", string(activity.ID), "adapter-reported activity must remain advisory")
	}
	if !validExternalSource(activity.Source, activity.SourceID) ||
		activity.Basis == domain.ProvenanceBasisAdapterReported && activity.Source == "" {
		return invalidSessionArgument("record activity", string(activity.ID), "activity source and source identifier are incomplete")
	}
	if activity.ParentID != nil {
		if err := activity.ParentID.Validate(); err != nil {
			return err
		}
	}
	if activity.NodeRunID != nil {
		if err := activity.NodeRunID.Validate(); err != nil {
			return err
		}
	}
	if activity.SessionID != nil {
		if err := activity.SessionID.Validate(); err != nil {
			return err
		}
	}
	if activity.PromptArtifactID != nil {
		if err := activity.PromptArtifactID.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func validActivityParent(activity domain.Activity, parent *domain.Activity) bool {
	switch activity.Kind {
	case domain.ActivityKindWorkflowRun:
		return parent == nil && activity.NodeRunID == nil && activity.SessionID == nil
	case domain.ActivityKindNodeAttempt:
		return parent != nil && parent.Kind == domain.ActivityKindWorkflowRun &&
			parent.WorkflowRunID == activity.WorkflowRunID && activity.NodeRunID != nil && activity.SessionID == nil
	case domain.ActivityKindSession:
		return parent != nil && parent.Kind == domain.ActivityKindNodeAttempt &&
			parent.WorkflowRunID == activity.WorkflowRunID && sameNode(parent.NodeRunID, activity.NodeRunID) &&
			activity.NodeRunID != nil && activity.SessionID != nil
	case domain.ActivityKindTurn:
		return parent != nil && parent.Kind == domain.ActivityKindSession &&
			parent.WorkflowRunID == activity.WorkflowRunID && sameNode(parent.NodeRunID, activity.NodeRunID) &&
			sameSession(parent.SessionID, activity.SessionID)
	case domain.ActivityKindModelCall:
		return parent != nil && parent.Kind == domain.ActivityKindTurn &&
			parent.WorkflowRunID == activity.WorkflowRunID && sameNode(parent.NodeRunID, activity.NodeRunID) &&
			sameSession(parent.SessionID, activity.SessionID)
	case domain.ActivityKindToolCall:
		return parent != nil && (parent.Kind == domain.ActivityKindTurn || parent.Kind == domain.ActivityKindModelCall) &&
			parent.WorkflowRunID == activity.WorkflowRunID && sameNode(parent.NodeRunID, activity.NodeRunID) &&
			sameSession(parent.SessionID, activity.SessionID)
	default:
		return false
	}
}

func sameNode(first *domain.NodeRunID, second *domain.NodeRunID) bool {
	return first != nil && second != nil && *first == *second
}

func sameSession(first *domain.SessionID, second *domain.SessionID) bool {
	return first != nil && second != nil && *first == *second
}

func validateCheckpointRequest(request CheckpointRequest) error {
	for _, err := range []error{request.ID.Validate(), request.SessionID.Validate()} {
		if err != nil {
			return err
		}
	}
	if request.WorkflowVersion == 0 || request.EventCursor == 0 || !json.Valid(request.State) ||
		!uniqueNodeRunIDs(request.OpenNodeRunIDs) || !uniqueHandleIDs(request.ActiveHandleIDs) ||
		!uniqueInterventionIDs(request.InterventionIDs) || !uniqueNonemptyStrings(request.UnresolvedDecisions) {
		return invalidSessionArgument("create checkpoint", string(request.ID), "checkpoint fields or references are invalid")
	}
	return nil
}

func validateInterventionRequest(request InterventionRequest) error {
	for _, err := range []error{request.ID.Validate(), request.SessionID.Validate()} {
		if err != nil {
			return err
		}
	}
	if !request.Kind.Valid() || !json.Valid(request.Payload) || request.Source == "" {
		return invalidSessionArgument("record intervention", string(request.ID), "kind, payload, and source are required")
	}
	if request.Kind == domain.InterventionKindInterrupt &&
		(request.Deadline == nil || request.Deadline.IsZero() || !request.Deadline.After(time.Now())) {
		return invalidSessionArgument("record intervention", string(request.ID), "interrupt deadline is required")
	}
	return nil
}

func validSessionTransition(current domain.SessionState, target domain.SessionState) bool {
	if current == target {
		return false
	}
	switch current {
	case domain.SessionStateStarting:
		return target == domain.SessionStateRunning || target == domain.SessionStateWaiting ||
			target == domain.SessionStateCompleted || target == domain.SessionStateFailed ||
			target == domain.SessionStateCancelled || target == domain.SessionStateOrphaned
	case domain.SessionStateRunning:
		return target == domain.SessionStateWaiting || target == domain.SessionStateCompleted ||
			target == domain.SessionStateFailed || target == domain.SessionStateCancelled ||
			target == domain.SessionStateOrphaned
	case domain.SessionStateWaiting:
		return target == domain.SessionStateRunning || target == domain.SessionStateCompleted ||
			target == domain.SessionStateFailed || target == domain.SessionStateCancelled ||
			target == domain.SessionStateOrphaned
	case domain.SessionStateOrphaned:
		return target == domain.SessionStateRunning || target == domain.SessionStateCompleted ||
			target == domain.SessionStateFailed || target == domain.SessionStateCancelled
	default:
		return false
	}
}

func validInterventionTransition(current domain.InterventionState, target domain.InterventionState) bool {
	switch current {
	case domain.InterventionStateRecorded:
		return target == domain.InterventionStateQueued || target == domain.InterventionStateForwarded ||
			target == domain.InterventionStateFailed
	case domain.InterventionStateQueued:
		return target == domain.InterventionStateForwarded || target == domain.InterventionStateFailed
	case domain.InterventionStateForwarded:
		return target == domain.InterventionStateCompleted || target == domain.InterventionStateFailed
	default:
		return false
	}
}

func terminalNodeState(state domain.NodeRunState) bool {
	return state == domain.NodeRunStateSucceeded || state == domain.NodeRunStateFailed ||
		state == domain.NodeRunStateCancelled || state == domain.NodeRunStateCapped
}

func terminalSessionState(state domain.SessionState) bool {
	return state == domain.SessionStateCompleted || state == domain.SessionStateFailed ||
		state == domain.SessionStateCancelled
}

func uniqueNonemptyStrings(values []string) bool {
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		if value == "" {
			return false
		}
		if _, found := seen[value]; found {
			return false
		}
		seen[value] = struct{}{}
	}
	return true
}

func validExternalSource(source string, sourceID string) bool {
	return source == "" && sourceID == "" || source != "" && sourceID != ""
}

func equalStrings(first []string, second []string) bool {
	if len(first) != len(second) {
		return false
	}
	firstCopy := append([]string(nil), first...)
	secondCopy := append([]string(nil), second...)
	sort.Strings(firstCopy)
	sort.Strings(secondCopy)
	for index := range firstCopy {
		if firstCopy[index] != secondCopy[index] {
			return false
		}
	}
	return true
}

func uniqueNodeRunIDs(values []domain.NodeRunID) bool {
	seen := make(map[domain.NodeRunID]struct{}, len(values))
	for _, value := range values {
		if value.Validate() != nil {
			return false
		}
		if _, found := seen[value]; found {
			return false
		}
		seen[value] = struct{}{}
	}
	return true
}

func uniqueHandleIDs(values []domain.AdapterHandleID) bool {
	seen := make(map[domain.AdapterHandleID]struct{}, len(values))
	for _, value := range values {
		if value.Validate() != nil {
			return false
		}
		if _, found := seen[value]; found {
			return false
		}
		seen[value] = struct{}{}
	}
	return true
}

func uniqueInterventionIDs(values []domain.InterventionID) bool {
	seen := make(map[domain.InterventionID]struct{}, len(values))
	for _, value := range values {
		if value.Validate() != nil {
			return false
		}
		if _, found := seen[value]; found {
			return false
		}
		seen[value] = struct{}{}
	}
	return true
}

func conflict(operation string, resource string, message string) error {
	return &domain.Error{Code: domain.ErrorCodeConflict, Op: operation, Resource: resource, Message: message}
}

func notFound(operation string, resource string, message string) error {
	return &domain.Error{Code: domain.ErrorCodeNotFound, Op: operation, Resource: resource, Message: message}
}

func invalidSessionArgument(operation string, resource string, message string) error {
	return &domain.Error{Code: domain.ErrorCodeInvalidArgument, Op: operation, Resource: resource, Message: message}
}
