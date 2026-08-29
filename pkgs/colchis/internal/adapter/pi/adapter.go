package pi

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	RuntimeAdapterID         = "pi"
	AttachmentAdapterID      = "pi.attachment"
	OperationStart           = "agent-runtime.start"
	OperationInput           = "agent-runtime.input"
	OperationInterrupt       = "agent-runtime.interrupt"
	OperationResume          = "agent-runtime.resume"
	OperationReconcile       = "agent-runtime.reconcile"
	OperationAttachmentOpen  = "attachment.open"
	OperationAttachmentClose = "attachment.close"
)

type Config struct {
	Directory           string
	SessionDirectory    string
	Factory             SessionFactory
	DangerouslyAllowAll bool
}

type Adapter struct {
	config Config

	mu          sync.Mutex
	sessions    map[string]*managedSession
	attachments map[string]string
}

type managedSession struct {
	brokerID string
	options  SessionOptions
	snapshot SessionSnapshot
	session  RPCSession

	mu         sync.Mutex
	rehydrated bool
	cursorBase uint64
	baseKnown  bool
}

type handleValue struct {
	BrokerSessionID string `json:"brokerSessionId"`
	PiSessionID     string `json:"piSessionId"`
	SessionFile     string `json:"sessionFile"`
	Workspace       string `json:"workspace"`
}

type StartRequest struct {
	SessionID      string `json:"sessionId"`
	Provider       string `json:"provider,omitempty"`
	Model          string `json:"model,omitempty"`
	Name           string `json:"name,omitempty"`
	ApproveProject bool   `json:"approveProject,omitempty"`
}

type InputRequest struct {
	Message  string `json:"message"`
	Behavior string `json:"behavior"`
}

type ReconcileRequest struct {
	Cursor    uint64 `json:"cursor,omitempty"`
	MaxEvents uint32 `json:"maxEvents,omitempty"`
}

type AttachmentOpenRequest struct {
	SessionID string `json:"sessionId"`
	Cursor    uint64 `json:"cursor,omitempty"`
}

type AttachmentCloseRequest struct {
	AttachmentID string `json:"attachmentId"`
	SessionID    string `json:"sessionId"`
}

type capabilities struct {
	LiveInput        bool `json:"liveInput"`
	QueuedInput      bool `json:"queuedInput"`
	Interrupt        bool `json:"interrupt"`
	Resume           bool `json:"resume"`
	NativeAttachment bool `json:"nativeAttachment"`
}

type sessionResult struct {
	State        string       `json:"state"`
	Capabilities capabilities `json:"capabilities"`
}

type inputResult struct {
	Accepted bool   `json:"accepted"`
	Queued   bool   `json:"queued"`
	State    string `json:"state"`
}

type interruptResult struct {
	Interrupted bool   `json:"interrupted"`
	State       string `json:"state"`
}

type attachmentResult struct {
	AttachmentID string   `json:"attachmentId"`
	Transport    string   `json:"transport"`
	ReadOnly     bool     `json:"readOnly"`
	Cursor       uint64   `json:"cursor"`
	Capabilities []string `json:"capabilities"`
}

func New(config Config) (*Adapter, error) {
	if config.Factory == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "factory", "session factory is nil", nil)
	}
	var err error
	config.Directory, err = filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "working directory is invalid", err)
	}
	config.SessionDirectory, err = filepath.Abs(config.SessionDirectory)
	if err != nil || config.SessionDirectory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "pi", "session directory is invalid", err)
	}
	return &Adapter{
		config: config, sessions: make(map[string]*managedSession), attachments: make(map[string]string),
	}, nil
}

func NewLocal(directory string, sessionDirectory string, offline bool, maxMessageBytes uint64) (*Adapter, error) {
	factory, err := NewProcessFactory(ProcessFactoryConfig{
		Directory: directory, SessionDirectory: sessionDirectory,
		Environment: os.Environ(), Offline: offline, MaxMessageBytes: maxMessageBytes,
	})
	if err != nil {
		return nil, err
	}
	return New(Config{
		Directory: directory, SessionDirectory: sessionDirectory, Factory: factory,
		DangerouslyAllowAll: os.Getenv("COLCHIS_PLUGIN_ISOLATION") == "dangerously-allow-all",
	})
}

func (adapter *Adapter) Invoke(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
	_ plugin.EventEmitter,
) (plugin.OperationResult, error) {
	if envelope.AdapterID == AttachmentAdapterID {
		return adapter.invokeAttachment(envelope)
	}
	switch envelope.Operation {
	case OperationStart:
		return adapter.start(ctx, envelope)
	case OperationInput:
		return adapter.input(ctx, envelope)
	case OperationInterrupt:
		return adapter.interrupt(ctx, envelope)
	case OperationResume:
		return adapter.resume(ctx, envelope)
	case OperationReconcile:
		return adapter.reconcileOperation(envelope)
	default:
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeNotFound, envelope.Operation, "operation is unknown", nil,
		)
	}
}

func (adapter *Adapter) start(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	if err := validateJobPolicy(envelope.JobPolicy, adapter.config.DangerouslyAllowAll); err != nil {
		return plugin.OperationResult{}, err
	}
	request, err := decodeRequest[StartRequest](envelope.Input)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if err := validateIdentifier("session", request.SessionID); err != nil {
		return plugin.OperationResult{}, err
	}
	adapter.mu.Lock()
	_, exists := adapter.sessions[request.SessionID]
	adapter.mu.Unlock()
	if exists {
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeConflict, request.SessionID, "session already exists", nil,
		)
	}
	providerSessionID, err := randomID("pi")
	if err != nil {
		return plugin.OperationResult{}, err
	}
	options := SessionOptions{
		SessionID: providerSessionID, Provider: request.Provider, Model: request.Model,
		Name: request.Name, ApproveProject: true,
		Directory: adapter.config.Directory, EventFile: adapter.eventFile(request.SessionID),
	}
	if err := createEventCursorBase(options.EventFile, 0); err != nil {
		return plugin.OperationResult{}, err
	}
	session, err := adapter.config.Factory.Start(ctx, options)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	snapshot, err := session.Snapshot(ctx)
	if err != nil {
		_ = session.Close()
		return plugin.OperationResult{}, err
	}
	managed := &managedSession{
		brokerID: request.SessionID, options: options, snapshot: snapshot, session: session,
		baseKnown: true,
	}
	handle, err := encodeHandle(managed)
	if err != nil {
		_ = session.Close()
		return plugin.OperationResult{}, err
	}
	adapter.mu.Lock()
	if _, found := adapter.sessions[request.SessionID]; found {
		adapter.mu.Unlock()
		_ = session.Close()
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeConflict, request.SessionID, "session already exists", nil,
		)
	}
	adapter.sessions[request.SessionID] = managed
	adapter.mu.Unlock()
	result, err := operationResult(
		envelope.ID, sessionResult{State: snapshot.State, Capabilities: runtimeCapabilities()}, handle,
	)
	result.SessionState = domain.SessionStateRunning
	result.TraceSessionID = snapshot.SessionID
	return result, err
}

func validateJobPolicy(policy *domain.JobPolicy, dangerouslyAllowAll bool) error {
	if policy == nil {
		return adapterError(domain.ErrorCodeInvalidArgument, "job-policy", "job policy is required", nil)
	}
	if err := policy.Validate(); err != nil {
		return err
	}
	filesystem := domain.FilesystemPolicyWorkspaceWrite
	network := domain.NetworkPolicyDeny
	if dangerouslyAllowAll {
		filesystem = domain.FilesystemPolicyDangerFullAccess
		network = domain.NetworkPolicyAllow
	}
	if policy.Approvals != domain.ApprovalPolicyNever || policy.Filesystem != filesystem || policy.Network != network {
		return adapterError(
			domain.ErrorCodeInvalidArgument, "job-policy",
			"Pi job policy exceeds or conflicts with its plugin isolation profile", nil,
		)
	}
	return nil
}

func (adapter *Adapter) input(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	request, err := decodeRequest[InputRequest](envelope.Input)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if strings.TrimSpace(request.Message) == "" {
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeInvalidArgument, "message", "message is empty", nil,
		)
	}
	if request.Behavior != "prompt" && request.Behavior != "steer" && request.Behavior != "follow_up" {
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeInvalidArgument, "behavior", "input behavior is invalid", nil,
		)
	}
	managed, err := adapter.sessionForHandle(envelope.Handle)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	priorBatch, err := managed.session.Events(0, 1)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	prior := priorBatch.State
	if _, err := managed.session.Command(ctx, request.Behavior, request.Message); err != nil {
		return plugin.OperationResult{}, err
	}
	queued := request.Behavior != "prompt" || prior == "running"
	return operationResult(envelope.ID, inputResult{Accepted: true, Queued: queued, State: "running"}, nil)
}

func (adapter *Adapter) interrupt(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	if _, err := decodeRequest[emptyRequest](envelope.Input); err != nil {
		return plugin.OperationResult{}, err
	}
	managed, err := adapter.sessionForHandle(envelope.Handle)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if _, err := managed.session.Command(ctx, "abort", ""); err != nil {
		return plugin.OperationResult{}, err
	}
	adapter.mu.Lock()
	if adapter.sessions[managed.brokerID] == managed {
		delete(adapter.sessions, managed.brokerID)
	}
	adapter.mu.Unlock()
	if err := managed.session.Close(); err != nil {
		return plugin.OperationResult{}, err
	}
	return operationResult(
		envelope.ID, interruptResult{Interrupted: true, State: "cancelled"}, nil,
	)
}

func (adapter *Adapter) resume(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
) (plugin.OperationResult, error) {
	if _, err := decodeRequest[emptyRequest](envelope.Input); err != nil {
		return plugin.OperationResult{}, err
	}
	managed, err := adapter.ensureSession(ctx, envelope.Handle)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	snapshot, err := managed.session.Snapshot(ctx)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	return operationResult(
		envelope.ID, sessionResult{State: snapshot.State, Capabilities: runtimeCapabilities()}, nil,
	)
}

func (adapter *Adapter) reconcileOperation(envelope plugin.OperationEnvelope) (plugin.OperationResult, error) {
	request, err := decodeRequest[ReconcileRequest](envelope.Input)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	managed, err := adapter.sessionForHandle(envelope.Handle)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	managed.mu.Lock()
	if managed.rehydrated && !managed.baseKnown {
		if err := createEventCursorBase(managed.options.EventFile, request.Cursor); err != nil {
			managed.mu.Unlock()
			return plugin.OperationResult{}, err
		}
		managed.cursorBase = request.Cursor
		managed.baseKnown = true
	}
	base := managed.cursorBase
	managed.mu.Unlock()
	providerCursor := uint64(0)
	if request.Cursor >= base {
		providerCursor = request.Cursor - base
	}
	batch, err := managed.session.Events(providerCursor, request.MaxEvents)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if base > 0 {
		batch.Cursor += base
		if batch.FirstAvailableCursor > 0 {
			batch.FirstAvailableCursor += base
		}
		for index := range batch.Events {
			batch.Events[index].Sequence += base
		}
	}
	return operationResult(envelope.ID, batch, nil)
}

func (adapter *Adapter) invokeAttachment(envelope plugin.OperationEnvelope) (plugin.OperationResult, error) {
	switch envelope.Operation {
	case OperationAttachmentOpen:
		request, err := decodeRequest[AttachmentOpenRequest](envelope.Input)
		if err != nil {
			return plugin.OperationResult{}, err
		}
		adapter.mu.Lock()
		managed := adapter.sessions[request.SessionID]
		adapter.mu.Unlock()
		if managed == nil {
			return plugin.OperationResult{}, adapterError(
				domain.ErrorCodeNotFound, request.SessionID, "session does not exist", nil,
			)
		}
		attachmentID, err := randomID("attachment")
		if err != nil {
			return plugin.OperationResult{}, err
		}
		adapter.mu.Lock()
		adapter.attachments[attachmentID] = request.SessionID
		adapter.mu.Unlock()
		return operationResult(envelope.ID, attachmentResult{
			AttachmentID: attachmentID, Transport: "native-event-stream", Cursor: request.Cursor,
			Capabilities: []string{"live-input", "queued-input", "interrupt", "resume"},
		}, nil)
	case OperationAttachmentClose:
		request, err := decodeRequest[AttachmentCloseRequest](envelope.Input)
		if err != nil {
			return plugin.OperationResult{}, err
		}
		adapter.mu.Lock()
		sessionID, found := adapter.attachments[request.AttachmentID]
		if found && sessionID == request.SessionID {
			delete(adapter.attachments, request.AttachmentID)
		} else {
			found = false
		}
		adapter.mu.Unlock()
		return operationResult(envelope.ID, closeResult{Closed: found}, nil)
	default:
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeNotFound, envelope.Operation, "attachment operation is unknown", nil,
		)
	}
}

func (adapter *Adapter) Reconcile(
	ctx context.Context,
	handles []plugin.HandleDescriptor,
) ([]plugin.ReconcileResult, error) {
	results := make([]plugin.ReconcileResult, 0, len(handles))
	for _, descriptor := range handles {
		value, err := decodeHandle(&descriptor, adapter.config.Directory)
		if err != nil {
			return nil, err
		}
		adapter.mu.Lock()
		managed := adapter.sessions[value.BrokerSessionID]
		adapter.mu.Unlock()
		state := plugin.ReconcileStateAdopted
		if managed == nil {
			if _, err := os.Stat(value.SessionFile); err != nil {
				results = append(results, plugin.ReconcileResult{
					HandleID: descriptor.ID, State: plugin.ReconcileStateOrphaned,
				})
				continue
			}
			if _, err := adapter.ensureSession(ctx, &descriptor); err != nil {
				return nil, err
			}
			state = plugin.ReconcileStateRehydrated
		}
		results = append(results, plugin.ReconcileResult{HandleID: descriptor.ID, State: state})
	}
	return results, nil
}

func (adapter *Adapter) Close() error {
	adapter.mu.Lock()
	sessions := make([]RPCSession, 0, len(adapter.sessions))
	for _, managed := range adapter.sessions {
		sessions = append(sessions, managed.session)
	}
	adapter.sessions = make(map[string]*managedSession)
	adapter.attachments = make(map[string]string)
	adapter.mu.Unlock()
	var closeErr error
	for _, session := range sessions {
		closeErr = errorsJoin(closeErr, session.Close())
	}
	return closeErr
}

func (adapter *Adapter) sessionForHandle(descriptor *plugin.HandleDescriptor) (*managedSession, error) {
	value, err := decodeHandle(descriptor, adapter.config.Directory)
	if err != nil {
		return nil, err
	}
	adapter.mu.Lock()
	managed := adapter.sessions[value.BrokerSessionID]
	adapter.mu.Unlock()
	if managed == nil {
		return nil, adapterError(
			domain.ErrorCodeNotFound, value.BrokerSessionID, "active session does not exist", nil,
		)
	}
	return managed, nil
}

func (adapter *Adapter) ensureSession(
	ctx context.Context,
	descriptor *plugin.HandleDescriptor,
) (*managedSession, error) {
	value, err := decodeHandle(descriptor, adapter.config.Directory)
	if err != nil {
		return nil, err
	}
	adapter.mu.Lock()
	managed := adapter.sessions[value.BrokerSessionID]
	adapter.mu.Unlock()
	if managed != nil {
		return managed, nil
	}
	options := SessionOptions{
		SessionID: value.PiSessionID, SessionFile: value.SessionFile,
		Directory: value.Workspace, EventFile: adapter.eventFile(value.BrokerSessionID),
	}
	cursorBase, baseKnown, err := loadEventCursorBase(options.EventFile)
	if err != nil {
		return nil, err
	}
	session, err := adapter.config.Factory.Start(ctx, options)
	if err != nil {
		return nil, err
	}
	snapshot, err := session.Snapshot(ctx)
	if err != nil {
		_ = session.Close()
		return nil, err
	}
	managed = &managedSession{
		brokerID: value.BrokerSessionID, options: options, snapshot: snapshot, session: session,
		rehydrated: true, cursorBase: cursorBase, baseKnown: baseKnown,
	}
	adapter.mu.Lock()
	if existing := adapter.sessions[value.BrokerSessionID]; existing != nil {
		adapter.mu.Unlock()
		_ = session.Close()
		return existing, nil
	}
	adapter.sessions[value.BrokerSessionID] = managed
	adapter.mu.Unlock()
	return managed, nil
}

func (adapter *Adapter) eventFile(brokerSessionID string) string {
	return filepath.Join(adapter.config.SessionDirectory, brokerSessionID+".events.jsonl")
}

func createEventCursorBase(eventFile string, cursor uint64) error {
	path := eventFile + ".base"
	file, err := os.OpenFile(path, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if errors.Is(err, os.ErrExist) {
		existing, found, readErr := loadEventCursorBase(eventFile)
		if readErr != nil {
			return readErr
		}
		if !found || existing != cursor {
			return adapterError(domain.ErrorCodeConflict, path, "event cursor base changed", nil)
		}
		return nil
	}
	if err != nil {
		return adapterError(domain.ErrorCodeInternal, path, "create event cursor base failed", err)
	}
	_, writeErr := fmt.Fprintf(file, "%d\n", cursor)
	syncErr := file.Sync()
	closeErr := file.Close()
	if err := errors.Join(writeErr, syncErr, closeErr); err != nil {
		return adapterError(domain.ErrorCodeInternal, path, "persist event cursor base failed", err)
	}
	return nil
}

func loadEventCursorBase(eventFile string) (uint64, bool, error) {
	path := eventFile + ".base"
	value, err := os.ReadFile(path)
	if errors.Is(err, os.ErrNotExist) {
		return 0, false, nil
	}
	if err != nil {
		return 0, false, adapterError(domain.ErrorCodeInternal, path, "read event cursor base failed", err)
	}
	cursor, err := strconv.ParseUint(strings.TrimSpace(string(value)), 10, 64)
	if err != nil {
		return 0, false, adapterError(domain.ErrorCodeInvalidArgument, path, "event cursor base is invalid", err)
	}
	return cursor, true, nil
}

func encodeHandle(managed *managedSession) (*plugin.AdapterHandleValue, error) {
	opaque, err := json.Marshal(handleValue{
		BrokerSessionID: managed.brokerID, PiSessionID: managed.snapshot.SessionID,
		SessionFile: managed.snapshot.SessionFile, Workspace: managed.options.Directory,
	})
	if err != nil {
		return nil, err
	}
	return &plugin.AdapterHandleValue{FormatVersion: 2, OpaqueValue: opaque}, nil
}

func decodeHandle(descriptor *plugin.HandleDescriptor, legacyWorkspace string) (handleValue, error) {
	if descriptor == nil || descriptor.AdapterID != RuntimeAdapterID || descriptor.Port != domain.AdapterPortAgentRuntime {
		return handleValue{}, adapterError(domain.ErrorCodeInvalidArgument, "handle", "Pi runtime handle is required", nil)
	}
	if descriptor.FormatVersion != 1 && descriptor.FormatVersion != 2 {
		return handleValue{}, adapterError(
			domain.ErrorCodeUnsupportedVersion, string(descriptor.ID), "Pi handle version is unsupported", nil,
		)
	}
	var value handleValue
	decoder := json.NewDecoder(bytes.NewReader(descriptor.OpaqueValue))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&value); err != nil {
		return handleValue{}, adapterError(domain.ErrorCodeInvalidArgument, string(descriptor.ID), "Pi handle is invalid", err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return handleValue{}, adapterError(
			domain.ErrorCodeInvalidArgument, string(descriptor.ID), "Pi handle has trailing JSON", err,
		)
	}
	if descriptor.FormatVersion == 1 {
		value.Workspace = legacyWorkspace
	}
	if value.BrokerSessionID == "" || value.PiSessionID == "" || !filepath.IsAbs(value.SessionFile) ||
		!filepath.IsAbs(value.Workspace) {
		return handleValue{}, adapterError(domain.ErrorCodeInvalidArgument, string(descriptor.ID), "Pi handle is incomplete", nil)
	}
	return value, nil
}

func runtimeCapabilities() capabilities {
	return capabilities{
		LiveInput: true, QueuedInput: true, Interrupt: true, Resume: true, NativeAttachment: true,
	}
}

func operationResult[Result resultDocument](
	id domain.OperationID,
	value Result,
	handle *plugin.AdapterHandleValue,
) (plugin.OperationResult, error) {
	output, err := json.Marshal(value)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	return plugin.OperationResult{
		ID: id, State: domain.OperationStateSucceeded, Output: output, Handle: handle,
	}, nil
}

type resultDocument interface {
	sessionResult | inputResult | interruptResult | EventBatch | attachmentResult | closeResult
}

type closeResult struct {
	Closed bool `json:"closed"`
}

type requestDocument interface {
	StartRequest | InputRequest | ReconcileRequest | AttachmentOpenRequest | AttachmentCloseRequest | emptyRequest
}

type emptyRequest struct{}

func decodeRequest[Request requestDocument](payload json.RawMessage) (Request, error) {
	var request Request
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", err.Error(), err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", "request has trailing JSON", err)
	}
	return request, nil
}

func randomID(prefix string) (string, error) {
	value := make([]byte, 16)
	if _, err := rand.Read(value); err != nil {
		return "", adapterError(domain.ErrorCodeInternal, prefix, "generate identifier failed", err)
	}
	return fmt.Sprintf("%s-%s", prefix, hex.EncodeToString(value)), nil
}

func validateIdentifier(kind string, value string) error {
	if strings.HasPrefix(value, "-") {
		return adapterError(domain.ErrorCodeInvalidArgument, value, kind+" cannot begin with a hyphen", nil)
	}
	return (domain.ResourceReference{Kind: kind, ID: value}).Validate()
}

func errorsJoin(first error, second error) error {
	if first == nil {
		return second
	}
	if second == nil {
		return first
	}
	return fmt.Errorf("%v; %w", first, second)
}

func adapterError(code domain.ErrorCode, resource string, message string, err error) error {
	return &domain.Error{Code: code, Op: "use Pi adapter", Resource: resource, Message: message, Err: err}
}
