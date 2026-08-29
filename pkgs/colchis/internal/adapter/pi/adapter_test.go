package pi

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

type fakeFactory struct {
	file     string
	options  []SessionOptions
	sessions []*fakeSession
}

func (factory *fakeFactory) Start(_ context.Context, options SessionOptions) (RPCSession, error) {
	factory.options = append(factory.options, options)
	sessionID := options.SessionID
	if sessionID == "" {
		sessionID = "pi-resumed"
	}
	session := &fakeSession{
		snapshot: SessionSnapshot{State: "idle", SessionID: sessionID, SessionFile: factory.file},
		batch: EventBatch{
			State: "idle", Cursor: 2, FirstAvailableCursor: 1,
			Events: []Event{
				{Sequence: 1, Kind: "turn", ProviderEventType: "turn_start", OccurredAt: time.Now().UTC(), Data: json.RawMessage(`{}`)},
				{Sequence: 2, Kind: "model_call", ProviderEventType: "message_end", OccurredAt: time.Now().UTC(), Data: json.RawMessage(`{"role":"assistant"}`)},
			},
		},
	}
	factory.sessions = append(factory.sessions, session)
	return session, nil
}

type fakeSession struct {
	snapshot SessionSnapshot
	batch    EventBatch
	commands []string
	closed   bool
}

func (session *fakeSession) Command(
	_ context.Context,
	commandType string,
	message string,
) (rpcResponse, error) {
	session.commands = append(session.commands, commandType+"\x00"+message)
	return rpcResponse{Type: "response", Command: commandType, Success: true}, nil
}

func (session *fakeSession) Snapshot(_ context.Context) (SessionSnapshot, error) {
	return session.snapshot, nil
}

func (session *fakeSession) Events(cursor uint64, maximum uint32) (EventBatch, error) {
	batch := session.batch
	batch.Events = append([]Event(nil), batch.Events...)
	if cursor > 0 {
		kept := make([]Event, 0, len(batch.Events))
		for _, event := range batch.Events {
			if event.Sequence > cursor {
				kept = append(kept, event)
			}
		}
		batch.Events = kept
	}
	if maximum > 0 && len(batch.Events) > int(maximum) {
		batch.Events = batch.Events[:maximum]
		batch.Cursor = batch.Events[len(batch.Events)-1].Sequence
		batch.More = true
	}
	return batch, nil
}

func (session *fakeSession) Close() error {
	session.closed = true
	return nil
}

func TestAdapterControlsSessionAndReturnsNormalizedEvents(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	sessionFile := filepath.Join(directory, "session.jsonl")
	if err := os.WriteFile(sessionFile, []byte("{}\n"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	factory := &fakeFactory{file: sessionFile}
	adapter, err := New(Config{Directory: directory, SessionDirectory: directory, Factory: factory})
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	startEnvelope := plugin.OperationEnvelope{
		ID: "operation-start", AdapterID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationStart, Input: json.RawMessage(`{"sessionId":"session-1","approveProject":false}`),
		JobPolicy: piTestJobPolicy(), Deadline: time.Now().Add(time.Minute),
	}
	startResult, err := adapter.Invoke(context.Background(), startEnvelope, nil)
	if err != nil {
		t.Fatalf("start Invoke() returned %v", err)
	}
	validateResult(t, startEnvelope, startResult)
	if startResult.Handle == nil || startResult.Handle.FormatVersion != 2 || len(factory.sessions) != 1 {
		t.Fatalf("start result = %#v, sessions = %d", startResult, len(factory.sessions))
	}
	var storedHandle handleValue
	if err := json.Unmarshal(startResult.Handle.OpaqueValue, &storedHandle); err != nil ||
		storedHandle.Workspace != directory {
		t.Fatalf("stored handle = %#v, %v", storedHandle, err)
	}
	if startResult.TraceSessionID == "" || startResult.TraceSessionID != storedHandle.PiSessionID {
		t.Fatalf("trace session = %q, handle = %#v", startResult.TraceSessionID, storedHandle)
	}
	handleID := domain.AdapterHandleID("handle-1")
	handle := plugin.HandleDescriptor{
		ID: handleID, PluginID: "fixture", Port: domain.AdapterPortAgentRuntime,
		AdapterID: RuntimeAdapterID, FormatVersion: startResult.Handle.FormatVersion,
		OpaqueValue: startResult.Handle.OpaqueValue,
	}
	inputEnvelope := plugin.OperationEnvelope{
		ID: "operation-input", AdapterID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationInput, HandleID: &handleID, Handle: &handle,
		Input:    json.RawMessage(`{"message":"Inspect the change.","behavior":"prompt"}`),
		Deadline: time.Now().Add(time.Minute),
	}
	inputResult, err := adapter.Invoke(context.Background(), inputEnvelope, nil)
	if err != nil {
		t.Fatalf("input Invoke() returned %v", err)
	}
	validateResult(t, inputEnvelope, inputResult)
	if len(factory.sessions[0].commands) != 1 || factory.sessions[0].commands[0] != "prompt\x00Inspect the change." {
		t.Fatalf("commands = %#v", factory.sessions[0].commands)
	}
	reconcileEnvelope := plugin.OperationEnvelope{
		ID: "operation-reconcile", AdapterID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationReconcile, HandleID: &handleID, Handle: &handle,
		Input: json.RawMessage(`{"cursor":0,"maxEvents":10}`), Deadline: time.Now().Add(time.Minute),
	}
	reconcileResult, err := adapter.Invoke(context.Background(), reconcileEnvelope, nil)
	if err != nil {
		t.Fatalf("reconcile Invoke() returned %v", err)
	}
	var batch EventBatch
	if err := json.Unmarshal(reconcileResult.Output, &batch); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if len(batch.Events) != 2 || batch.Events[1].Kind != "model_call" {
		t.Fatalf("event batch = %#v", batch)
	}
	validateResult(t, reconcileEnvelope, reconcileResult)
	attachmentEnvelope := plugin.OperationEnvelope{
		ID: "operation-attach", AdapterID: AttachmentAdapterID, Port: domain.AdapterPortAttachment,
		Operation: OperationAttachmentOpen, Input: json.RawMessage(`{"sessionId":"session-1","cursor":2}`),
		Deadline: time.Now().Add(time.Minute),
	}
	attachment, err := adapter.Invoke(context.Background(), attachmentEnvelope, nil)
	if err != nil {
		t.Fatalf("attachment Invoke() returned %v", err)
	}
	validateResult(t, attachmentEnvelope, attachment)
	var opened attachmentResult
	if err := json.Unmarshal(attachment.Output, &opened); err != nil {
		t.Fatalf("Unmarshal() attachment returned %v", err)
	}
	wrongCloseEnvelope := plugin.OperationEnvelope{
		ID: "operation-close-wrong-session", AdapterID: AttachmentAdapterID, Port: domain.AdapterPortAttachment,
		Operation: OperationAttachmentClose,
		Input:     json.RawMessage(`{"attachmentId":"` + opened.AttachmentID + `","sessionId":"session-2"}`),
		Deadline:  time.Now().Add(time.Minute),
	}
	wrongClose, err := adapter.Invoke(context.Background(), wrongCloseEnvelope, nil)
	if err != nil {
		t.Fatalf("wrong-session close Invoke() returned %v", err)
	}
	var wrongCloseResult closeResult
	if err := json.Unmarshal(wrongClose.Output, &wrongCloseResult); err != nil || wrongCloseResult.Closed {
		t.Fatalf("wrong-session close result = %#v, %v", wrongCloseResult, err)
	}
	closeEnvelope := wrongCloseEnvelope
	closeEnvelope.ID = "operation-close"
	closeEnvelope.Input = json.RawMessage(`{"attachmentId":"` + opened.AttachmentID + `","sessionId":"session-1"}`)
	closed, err := adapter.Invoke(context.Background(), closeEnvelope, nil)
	if err != nil {
		t.Fatalf("close Invoke() returned %v", err)
	}
	var decodedClose closeResult
	if err := json.Unmarshal(closed.Output, &decodedClose); err != nil || !decodedClose.Closed {
		t.Fatalf("close result = %#v, %v", decodedClose, err)
	}
	interruptEnvelope := plugin.OperationEnvelope{
		ID: "operation-interrupt", AdapterID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationInterrupt, HandleID: &handleID, Handle: &handle,
		Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
	}
	interruptResult, err := adapter.Invoke(context.Background(), interruptEnvelope, nil)
	if err != nil {
		t.Fatalf("interrupt Invoke() returned %v", err)
	}
	validateResult(t, interruptEnvelope, interruptResult)
	if factory.sessions[0].commands[1] != "abort\x00" || !factory.sessions[0].closed {
		t.Fatalf("commands = %#v", factory.sessions[0].commands)
	}
}

func TestAdapterRejectsUnsupportedJobPolicy(t *testing.T) {
	t.Parallel()

	policy := domain.JobPolicy{
		Approvals:  domain.ApprovalPolicyNever,
		Filesystem: domain.FilesystemPolicyDangerFullAccess,
		Network:    domain.NetworkPolicyAllow,
	}
	if err := validateJobPolicy(&policy, false); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("validateJobPolicy() error = %v", err)
	}
	if err := validateJobPolicy(&policy, true); err != nil {
		t.Fatalf("dangerous validateJobPolicy() error = %v", err)
	}
}

func piTestJobPolicy() *domain.JobPolicy {
	return &domain.JobPolicy{
		Approvals:  domain.ApprovalPolicyNever,
		Filesystem: domain.FilesystemPolicyWorkspaceWrite,
		Network:    domain.NetworkPolicyDeny,
	}
}

func TestPluginReconciliationRehydratesSessionFile(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	sessionFile := filepath.Join(directory, "session.jsonl")
	if err := os.WriteFile(sessionFile, []byte("{}\n"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	factory := &fakeFactory{file: sessionFile}
	adapter, err := New(Config{Directory: directory, SessionDirectory: directory, Factory: factory})
	if err != nil {
		t.Fatalf("New() returned %v", err)
	}
	opaque, err := json.Marshal(handleValue{
		BrokerSessionID: "session-1", PiSessionID: "pi-1", SessionFile: sessionFile,
		Workspace: directory,
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	handle := plugin.HandleDescriptor{
		ID: "handle-1", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime,
		AdapterID: RuntimeAdapterID, FormatVersion: 2, OpaqueValue: opaque,
	}
	results, err := adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{handle})
	if err != nil {
		t.Fatalf("Reconcile() returned %v", err)
	}
	if len(results) != 1 || results[0].State != plugin.ReconcileStateRehydrated ||
		len(factory.options) != 1 || factory.options[0].SessionFile != sessionFile ||
		factory.options[0].Directory != directory ||
		factory.options[0].EventFile != filepath.Join(directory, "session-1.events.jsonl") {
		t.Fatalf("reconciliation = %#v, options = %#v", results, factory.options)
	}
	legacyOpaque, err := json.Marshal(struct {
		BrokerSessionID string `json:"brokerSessionId"`
		PiSessionID     string `json:"piSessionId"`
		SessionFile     string `json:"sessionFile"`
	}{BrokerSessionID: "session-legacy", PiSessionID: "pi-legacy", SessionFile: sessionFile})
	if err != nil {
		t.Fatalf("Marshal(legacy) returned %v", err)
	}
	legacyFactory := &fakeFactory{file: sessionFile}
	legacyAdapter, err := New(Config{
		Directory: directory, SessionDirectory: directory, Factory: legacyFactory,
	})
	if err != nil {
		t.Fatalf("legacy New() returned %v", err)
	}
	legacyHandle := handle
	legacyHandle.ID = "handle-legacy"
	legacyHandle.FormatVersion = 1
	legacyHandle.OpaqueValue = legacyOpaque
	legacyResults, err := legacyAdapter.Reconcile(context.Background(), []plugin.HandleDescriptor{legacyHandle})
	if err != nil || len(legacyResults) != 1 || legacyResults[0].State != plugin.ReconcileStateRehydrated ||
		len(legacyFactory.options) != 1 || legacyFactory.options[0].Directory != directory {
		t.Fatalf("legacy reconciliation = %#v, options = %#v, error = %v", legacyResults, legacyFactory.options, err)
	}
	handleID := handle.ID
	envelope := plugin.OperationEnvelope{
		ID: "operation-after-rehydrate", AdapterID: RuntimeAdapterID, Port: domain.AdapterPortAgentRuntime,
		Operation: OperationReconcile, HandleID: &handleID, Handle: &handle,
		Input: json.RawMessage(`{"cursor":50,"maxEvents":10}`), Deadline: time.Now().Add(time.Minute),
	}
	operation, err := adapter.Invoke(context.Background(), envelope, nil)
	if err != nil {
		t.Fatalf("Invoke() returned %v", err)
	}
	var batch EventBatch
	if err := json.Unmarshal(operation.Output, &batch); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if batch.Cursor != 52 || len(batch.Events) != 2 || batch.Events[0].Sequence != 51 {
		t.Fatalf("rebased events = %#v", batch)
	}
	replacementFactory := &fakeFactory{file: sessionFile}
	replacementDirectory := t.TempDir()
	replacement, err := New(Config{
		Directory: replacementDirectory, SessionDirectory: directory, Factory: replacementFactory,
	})
	if err != nil {
		t.Fatalf("replacement New() returned %v", err)
	}
	if _, err := replacement.Reconcile(context.Background(), []plugin.HandleDescriptor{handle}); err != nil {
		t.Fatalf("replacement Reconcile() returned %v", err)
	}
	if len(replacementFactory.options) != 1 || replacementFactory.options[0].Directory != directory {
		t.Fatalf("replacement options = %#v", replacementFactory.options)
	}
	replacementOperation := envelope
	replacementOperation.ID = "operation-after-second-rehydrate"
	replacementOperation.Input = json.RawMessage(`{"cursor":52,"maxEvents":10}`)
	operation, err = replacement.Invoke(context.Background(), replacementOperation, nil)
	if err != nil {
		t.Fatalf("replacement Invoke() returned %v", err)
	}
	if err := json.Unmarshal(operation.Output, &batch); err != nil {
		t.Fatalf("replacement Unmarshal() returned %v", err)
	}
	if batch.Cursor != 52 || len(batch.Events) != 0 {
		t.Fatalf("replacement rebased events = %#v", batch)
	}
	missingOpaque, err := json.Marshal(handleValue{
		BrokerSessionID: "session-missing", PiSessionID: "pi-missing",
		SessionFile: filepath.Join(directory, "missing.jsonl"), Workspace: directory,
	})
	if err != nil {
		t.Fatalf("Marshal(missing) returned %v", err)
	}
	missing := handle
	missing.ID = "handle-missing"
	missing.OpaqueValue = missingOpaque
	orphaned, err := adapter.Reconcile(context.Background(), []plugin.HandleDescriptor{missing})
	if err != nil {
		t.Fatalf("Reconcile(missing) returned %v", err)
	}
	if len(orphaned) != 1 || orphaned[0].State != plugin.ReconcileStateOrphaned {
		t.Fatalf("orphan reconciliation = %#v", orphaned)
	}
}

func TestEventJournalSurvivesProcessReplacement(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "session.events.jsonl")
	journal, err := os.OpenFile(path, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0o600)
	if err != nil {
		t.Fatalf("OpenFile() returned %v", err)
	}
	process := &rpcProcess{journal: journal, state: "idle"}
	if !process.consume([]byte(`{"type":"agent_start"}`)) ||
		!process.consume([]byte(`{"type":"agent_settled"}`)) {
		t.Fatal("consume() rejected fixture events")
	}
	if err := process.closeJournal(); err != nil {
		t.Fatalf("closeJournal() returned %v", err)
	}
	lastSequence, size, err := loadEventJournal(path, 1<<20)
	if err != nil {
		t.Fatalf("loadEventJournal() returned %v", err)
	}
	if lastSequence != 2 || size == 0 {
		t.Fatalf("reloaded last sequence = %d, size = %d", lastSequence, size)
	}
}

func TestEventJournalRetainsEventsBeyondFormerMemoryLimit(t *testing.T) {
	t.Parallel()

	path := filepath.Join(t.TempDir(), "session.events.jsonl")
	var fixture bytes.Buffer
	encoder := json.NewEncoder(&fixture)
	for sequence := uint64(1); sequence <= 4097; sequence++ {
		event := Event{
			Sequence: sequence, Kind: "turn", ProviderEventType: "turn_start",
			OccurredAt: time.Unix(int64(sequence), 0).UTC(), Data: json.RawMessage(`{}`),
		}
		if err := encoder.Encode(event); err != nil {
			t.Fatalf("Encode() returned %v", err)
		}
	}
	if err := os.WriteFile(path, fixture.Bytes(), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	lastSequence, _, err := loadEventJournal(path, 1<<20)
	if err != nil {
		t.Fatalf("loadEventJournal() returned %v", err)
	}
	batch, err := readEventJournalBatch(path, "idle", 0, 500, 1<<20)
	if err != nil {
		t.Fatalf("readEventJournalBatch() returned %v", err)
	}
	if lastSequence != 4097 || len(batch.Events) != 500 || batch.Events[0].Sequence != 1 || !batch.More {
		t.Fatalf("reloaded sequence = %d, batch = %#v", lastSequence, batch)
	}
}

func TestNormalizeEventDropsMessageContent(t *testing.T) {
	t.Parallel()

	event, err := normalizeEvent(json.RawMessage(`{
  "type":"message_end",
  "message":{"role":"assistant","id":"message-1","content":[{"type":"text","text":"private result"}]}
}`))
	if err != nil {
		t.Fatalf("normalizeEvent() returned %v", err)
	}
	if event.Kind != "model_call" || event.ProviderID != "message-1" ||
		stringsContains(string(event.Data), "private result") {
		t.Fatalf("event = %#v", event)
	}
}

func TestLocalProcessStartsOfflineRPCSession(t *testing.T) {
	if os.Getenv("COLCHIS_TEST_PI_RPC") == "" {
		t.Skip("COLCHIS_TEST_PI_RPC is unset")
	}
	directory := t.TempDir()
	factory, err := NewProcessFactory(ProcessFactoryConfig{
		Directory: directory, SessionDirectory: directory,
		Environment: os.Environ(), Offline: true, MaxMessageBytes: 1 << 20,
	})
	if err != nil {
		t.Fatalf("NewProcessFactory() returned %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	session, err := factory.Start(ctx, SessionOptions{SessionID: "colchis-live-pi"})
	if err != nil {
		t.Fatalf("Start() returned %v", err)
	}
	defer session.Close()
	snapshot, err := session.Snapshot(ctx)
	if err != nil {
		t.Fatalf("Snapshot() returned %v", err)
	}
	if snapshot.SessionID == "" || !filepath.IsAbs(snapshot.SessionFile) || snapshot.State != "idle" {
		t.Fatalf("snapshot = %#v", snapshot)
	}
}

func validateResult(t *testing.T, envelope plugin.OperationEnvelope, result plugin.OperationResult) {
	t.Helper()
	manifests, err := Manifests()
	if err != nil {
		t.Fatalf("Manifests() returned %v", err)
	}
	var manifest plugin.AdapterManifest
	for _, candidate := range manifests {
		if candidate.ID == envelope.AdapterID && candidate.Port == envelope.Port {
			manifest = candidate
		}
	}
	if err := plugin.ValidateOperationEnvelope(envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationEnvelope() returned %v", err)
	}
	if err := plugin.ValidateOperationResult(result, envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationResult() returned %v", err)
	}
}

func stringsContains(value string, fragment string) bool {
	for index := 0; index+len(fragment) <= len(value); index++ {
		if value[index:index+len(fragment)] == fragment {
			return true
		}
	}
	return false
}
