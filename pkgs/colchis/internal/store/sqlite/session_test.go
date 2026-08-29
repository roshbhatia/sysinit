package sqlite

import (
	"context"
	"encoding/json"
	"path/filepath"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestSessionHistorySurvivesRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, node := createSessionTestRun(t, ctx, path, "run-session")
	session, err := store.CreateSession(ctx, CreateSessionRequest{
		ID: "session-1", WorkflowRunID: "run-session", NodeRunID: node.ID,
		RuntimePluginID: "pi-plugin", RuntimeAdapterID: "pi-runtime",
		Capabilities: []string{"live-input", "resume"},
	})
	if err != nil {
		t.Fatalf("CreateSession() returned %v", err)
	}
	session, handle, err := store.BindSessionHandle(ctx, BindSessionHandleRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		HandleID: "handle-session-1", FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"runtimeSession":"private-1"}`), TraceSessionID: "trace-session-1",
	})
	if err != nil {
		t.Fatalf("BindSessionHandle() returned %v", err)
	}
	intervention, err := store.RecordIntervention(ctx, InterventionRequest{
		ID: "intervention-1", SessionID: session.ID, Kind: domain.InterventionKindMessage,
		Payload: json.RawMessage(`{"text":"Check the failing test."}`), Source: "owner-terminal",
	})
	if err != nil {
		t.Fatalf("RecordIntervention() returned %v", err)
	}
	intervention, err = store.TransitionIntervention(
		ctx, intervention.ID, intervention.Metadata.ResourceVersion, domain.InterventionStateQueued,
	)
	if err != nil {
		t.Fatalf("TransitionIntervention() returned %v", err)
	}
	events, err := store.EventsAfter(ctx, 0, 100)
	if err != nil || len(events) == 0 {
		t.Fatalf("EventsAfter() = %#v, %v", events, err)
	}
	checkpoint, err := store.CreateCheckpoint(ctx, CheckpointRequest{
		ID: "checkpoint-1", SessionID: session.ID, WorkflowVersion: 1,
		EventCursor:         events[len(events)-1].Cursor,
		OpenNodeRunIDs:      []domain.NodeRunID{node.ID},
		ActiveHandleIDs:     []domain.AdapterHandleID{handle.ID},
		InterventionIDs:     []domain.InterventionID{intervention.ID},
		UnresolvedDecisions: []string{"choose-test-fix"}, State: json.RawMessage(`{"summary":"open"}`),
	})
	if err != nil {
		t.Fatalf("CreateCheckpoint() returned %v", err)
	}
	session, err = store.TransitionSession(ctx, SessionTransitionRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		State: domain.SessionStateCompleted, CheckpointID: &checkpoint.ID,
	})
	if err != nil {
		t.Fatalf("TransitionSession() returned %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	history, err := store.SessionHistory(ctx, session.ID)
	if err != nil {
		t.Fatalf("SessionHistory() returned %v", err)
	}
	if history.Session.State != domain.SessionStateCompleted || len(history.Checkpoints) != 1 ||
		len(history.Interventions) != 1 || history.Interventions[0].State != domain.InterventionStateQueued ||
		history.Session.TraceSessionID != "trace-session-1" {
		t.Fatalf("session history = %#v", history)
	}
	restoredHandle, err := store.AdapterHandle(ctx, handle.ID)
	if err != nil {
		t.Fatalf("AdapterHandle() returned %v", err)
	}
	if string(restoredHandle.OpaqueValue) != `{"runtimeSession":"private-1"}` {
		t.Fatalf("restored handle = %#v", restoredHandle)
	}
	recoverableHandles, err := store.RecoverableAdapterHandles(ctx)
	if err != nil || len(recoverableHandles) != 0 {
		t.Fatalf("RecoverableAdapterHandles() = %#v, %v", recoverableHandles, err)
	}
	_, nodes, err := store.WorkflowRun(ctx, "run-session")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if restored := nodeByKey(t, nodes, node.NodeKey); restored.State != domain.NodeRunStateWaiting ||
		restored.SessionID == nil || *restored.SessionID != session.ID {
		t.Fatalf("restored node = %#v", restored)
	}
}

func TestRefreshSessionContractRepairsLegacyPolicyAndCapabilities(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-legacy-session")
	defer store.Close()
	session, err := store.CreateSession(ctx, CreateSessionRequest{
		ID: "legacy-session", WorkflowRunID: "run-legacy-session", NodeRunID: node.ID,
		RuntimePluginID: "old-plugin", RuntimeAdapterID: "fixture", Capabilities: []string{"old"},
	})
	if err != nil {
		t.Fatalf("CreateSession() returned %v", err)
	}
	session.JobPolicy = domain.JobPolicy{}
	session.Capabilities = nil
	encoded, err := json.Marshal(session)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	if _, err := store.db.ExecContext(
		ctx, "UPDATE records SET payload = ? WHERE kind = ? AND id = ?",
		encoded, sessionRecordKind, string(session.ID),
	); err != nil {
		t.Fatalf("update legacy session returned %v", err)
	}
	updated, err := store.RefreshSessionContract(
		ctx, session.ID, session.Metadata.ResourceVersion, "old-plugin", "fixture",
		[]string{"structured-result", "job-policy"},
	)
	if err != nil {
		t.Fatalf("RefreshSessionContract() returned %v", err)
	}
	if err := updated.JobPolicy.Validate(); err != nil || updated.RuntimePluginID != "old-plugin" ||
		len(updated.Capabilities) != 2 {
		t.Fatalf("refreshed session = %#v, %v", updated, err)
	}
}

func TestRuntimeEventsAdvanceSessionCursorAtomically(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-events")
	defer store.Close()
	session := createBoundSession(t, ctx, store, node, "run-events", "session-events")
	now := time.Now().UTC()
	events := []domain.RuntimeEvent{
		{Sequence: 1, Kind: "turn", ProviderEventType: "turn_start", OccurredAt: now, Data: json.RawMessage(`{}`)},
		{Sequence: 2, Kind: "model_call", ProviderEventType: "message_end", OccurredAt: now, Data: json.RawMessage(`{"role":"assistant"}`)},
	}
	updated, err := store.RecordSessionRuntimeEvents(
		ctx, session.ID, session.Metadata.ResourceVersion, events,
	)
	if err != nil {
		t.Fatalf("RecordSessionRuntimeEvents() returned %v", err)
	}
	if updated.RuntimeEventCursor != 2 {
		t.Fatalf("runtime event cursor = %d", updated.RuntimeEventCursor)
	}
	history, err := store.SessionHistory(ctx, updated.ID)
	if err != nil || len(history.RuntimeEvents) != 2 || history.RuntimeEvents[1].ProviderEventType != "message_end" {
		t.Fatalf("SessionHistory() runtime events = %#v, %v", history.RuntimeEvents, err)
	}
	if _, err := store.RecordSessionRuntimeEvents(
		ctx, updated.ID, updated.Metadata.ResourceVersion, events,
	); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("duplicate RecordSessionRuntimeEvents() error = %v", err)
	}
}

func TestActivityLineageBindsPromptToModelCall(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-lineage")
	defer store.Close()
	session := createBoundSession(t, ctx, store, node, "run-lineage", "session-lineage")
	prompt, err := store.StorePromptArtifact(
		ctx, "text/plain", "sha256:template", []string{"MODEL_TOKEN"}, []byte("Review the implementation."),
	)
	if err != nil {
		t.Fatalf("StorePromptArtifact() returned %v", err)
	}
	root := recordTestActivity(t, ctx, store, domain.Activity{
		ID: "activity-run", Kind: domain.ActivityKindWorkflowRun, WorkflowRunID: "run-lineage",
		Basis: domain.ProvenanceBasisBrokerObserved, Authority: domain.AuthorityHarness, StartedAt: time.Now().UTC(),
	})
	nodeActivity := recordTestActivity(t, ctx, store, domain.Activity{
		ID: "activity-node", Kind: domain.ActivityKindNodeAttempt, ParentID: &root.ID,
		WorkflowRunID: "run-lineage", NodeRunID: &node.ID,
		Basis: domain.ProvenanceBasisBrokerObserved, Authority: domain.AuthorityHarness, StartedAt: time.Now().UTC(),
	})
	sessionActivity := recordTestActivity(t, ctx, store, domain.Activity{
		ID: "activity-session", Kind: domain.ActivityKindSession, ParentID: &nodeActivity.ID,
		WorkflowRunID: "run-lineage", NodeRunID: &node.ID, SessionID: &session.ID,
		Basis: domain.ProvenanceBasisBrokerObserved, Authority: domain.AuthorityHarness, StartedAt: time.Now().UTC(),
	})
	turn := recordTestActivity(t, ctx, store, domain.Activity{
		ID: "activity-turn", Kind: domain.ActivityKindTurn, ParentID: &sessionActivity.ID,
		WorkflowRunID: "run-lineage", NodeRunID: &node.ID, SessionID: &session.ID,
		Basis: domain.ProvenanceBasisBrokerObserved, Authority: domain.AuthorityHarness, StartedAt: time.Now().UTC(),
	})
	model := recordTestActivity(t, ctx, store, domain.Activity{
		ID: "activity-model", Kind: domain.ActivityKindModelCall, ParentID: &turn.ID,
		WorkflowRunID: "run-lineage", NodeRunID: &node.ID, SessionID: &session.ID,
		PromptArtifactID: &prompt.ID, Provider: "fixture", ProviderID: "request-private",
		Basis: domain.ProvenanceBasisAdapterReported, Authority: domain.AuthorityAdvisory,
		Source: "fixture-runtime", SourceID: "call-private", StartedAt: time.Now().UTC(),
	})
	if _, err := store.CompleteActivity(
		ctx, model.ID, model.Metadata.ResourceVersion, time.Now().Add(time.Second).UTC(),
	); err != nil {
		t.Fatalf("CompleteActivity() returned %v", err)
	}
	history, err := store.SessionHistory(ctx, session.ID)
	if err != nil {
		t.Fatalf("SessionHistory() returned %v", err)
	}
	if len(history.Activities) != 3 {
		t.Fatalf("session activity count = %d", len(history.Activities))
	}
	restoredPrompt, err := store.PromptArtifact(ctx, prompt.ID)
	if err != nil || string(restoredPrompt.Content) != "Review the implementation." {
		t.Fatalf("PromptArtifact() = %#v, %v", restoredPrompt, err)
	}
}

func TestActivityRejectsElevatedAdapterAuthority(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _ := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-authority")
	defer store.Close()
	_, err := store.RecordActivity(ctx, domain.Activity{
		ID: "activity-elevated", Kind: domain.ActivityKindWorkflowRun, WorkflowRunID: "run-authority",
		Basis: domain.ProvenanceBasisAdapterReported, Authority: domain.AuthorityHarness,
		StartedAt: time.Now().UTC(),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("RecordActivity() error = %v", err)
	}
}

func TestSessionReconciliationRecordsExplicitState(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, node := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-reconcile")
	defer store.Close()
	session := createBoundSession(t, ctx, store, node, "run-reconcile", "session-reconcile")
	active, err := store.ActiveSessions(ctx)
	if err != nil || len(active) != 1 {
		t.Fatalf("ActiveSessions() = %#v, %v", active, err)
	}
	session, err = store.ReconcileSession(
		ctx, session.ID, session.Metadata.ResourceVersion, domain.SessionReconciliationOrphaned,
	)
	if err != nil {
		t.Fatalf("ReconcileSession() returned %v", err)
	}
	if session.State != domain.SessionStateOrphaned {
		t.Fatalf("session state = %q", session.State)
	}
	active, err = store.ActiveSessions(ctx)
	if err != nil || len(active) != 0 {
		t.Fatalf("ActiveSessions() after orphan = %#v, %v", active, err)
	}
	recoverable, err := store.RecoverableSessions(ctx)
	if err != nil || len(recoverable) != 1 || recoverable[0].ID != session.ID {
		t.Fatalf("RecoverableSessions() = %#v, %v", recoverable, err)
	}
	recoverableHandles, err := store.RecoverableAdapterHandles(ctx)
	if err != nil || len(recoverableHandles) != 1 || recoverableHandles[0].ID != *session.RuntimeHandle {
		t.Fatalf("RecoverableAdapterHandles() = %#v, %v", recoverableHandles, err)
	}
}

func TestStorePersistsGenericAdapterHandles(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _ := createSessionTestRun(t, ctx, filepath.Join(t.TempDir(), "colchis.db"), "run-generic")
	defer store.Close()
	created, err := store.CreateAdapterHandle(ctx, domain.AdapterHandle{
		ID: "environment-handle", Owner: domain.ResourceReference{Kind: workflowRunRecordKind, ID: "run-generic"},
		PluginID: "sysinit", Port: domain.AdapterPortEnvironment,
		AdapterID: "nix-environment", FormatVersion: 2,
		OpaqueValue: json.RawMessage(`{"environment":"dev"}`),
	})
	if err != nil {
		t.Fatalf("CreateAdapterHandle() returned %v", err)
	}
	handles, err := store.AdapterHandles(ctx)
	if err != nil || len(handles) != 1 || handles[0].ID != created.ID ||
		handles[0].Port != domain.AdapterPortEnvironment {
		t.Fatalf("AdapterHandles() = %#v, %v", handles, err)
	}
	recoverable, err := store.RecoverableAdapterHandles(ctx)
	if err != nil || len(recoverable) != 1 || recoverable[0].ID != created.ID {
		t.Fatalf("RecoverableAdapterHandles() = %#v, %v", recoverable, err)
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		run, found, err := transaction.workflowRun(ctx, "run-generic")
		if err != nil || !found {
			return err
		}
		expectedVersion := run.Metadata.ResourceVersion
		run.State = domain.WorkflowRunStateSucceeded
		run.Metadata.ResourceVersion++
		run.Metadata.UpdatedAt = time.Now().UTC()
		payload, err := json.Marshal(run)
		if err != nil {
			return err
		}
		return transaction.updateRecord(
			ctx, workflowRunRecordKind, string(run.ID), expectedVersion, run.Metadata, payload,
		)
	})
	if err != nil {
		t.Fatalf("complete workflow run: %v", err)
	}
	recoverable, err = store.RecoverableAdapterHandles(ctx)
	if err != nil || len(recoverable) != 0 {
		t.Fatalf("RecoverableAdapterHandles() after completion = %#v, %v", recoverable, err)
	}
}

func createSessionTestRun(
	t *testing.T,
	ctx context.Context,
	path string,
	runID domain.WorkflowRunID,
) (*Store, domain.NodeRun) {
	t.Helper()
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	document := independentWorkflowDocument(t, 1, "task")
	resolved := resolveWorkflowForStoreTest(t, document)
	definitionID := domain.WorkflowDefinitionID("definition-" + string(runID))
	if _, err := store.CreateWorkflowDefinition(ctx, definitionID, nil, document, resolved); err != nil {
		store.Close()
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, runID, definitionID, nil); err != nil {
		store.Close()
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, runID, AdapterCapacity{"fixture": 1})
	if err != nil || len(reserved) != 1 {
		store.Close()
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	return store, reserved[0]
}

func createBoundSession(
	t *testing.T,
	ctx context.Context,
	store *Store,
	node domain.NodeRun,
	runID domain.WorkflowRunID,
	sessionID domain.SessionID,
) domain.Session {
	t.Helper()
	session, err := store.CreateSession(ctx, CreateSessionRequest{
		ID: sessionID, WorkflowRunID: runID, NodeRunID: node.ID,
		RuntimePluginID: "pi-plugin", RuntimeAdapterID: "pi-runtime", Capabilities: []string{"live-input"},
	})
	if err != nil {
		t.Fatalf("CreateSession() returned %v", err)
	}
	session, _, err = store.BindSessionHandle(ctx, BindSessionHandleRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		HandleID: domain.AdapterHandleID("handle-" + string(sessionID)), FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"runtimeSession":"private"}`),
	})
	if err != nil {
		t.Fatalf("BindSessionHandle() returned %v", err)
	}
	return session
}

func recordTestActivity(
	t *testing.T,
	ctx context.Context,
	store *Store,
	activity domain.Activity,
) domain.Activity {
	t.Helper()
	recorded, err := store.RecordActivity(ctx, activity)
	if err != nil {
		t.Fatalf("RecordActivity(%s) returned %v", activity.ID, err)
	}
	return recorded
}
