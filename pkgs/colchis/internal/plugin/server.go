package plugin

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"io"
	"sync"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const defaultMaxConcurrentOperations uint32 = 64

type EventEmitter func(kind string, payload json.RawMessage) error

type InvocationHandler func(
	context.Context,
	OperationEnvelope,
	EventEmitter,
) (OperationResult, error)

type ReconcileHandler func(context.Context, []HandleDescriptor) ([]ReconcileResult, error)

type ServerConfig struct {
	PluginID                domain.PluginID
	Adapters                []AdapterManifest
	Invoke                  InvocationHandler
	Reconcile               ReconcileHandler
	MaxConcurrentOperations uint32
}

type Server struct {
	config ServerConfig

	writeMu sync.Mutex
	stateMu sync.Mutex
	limits  WireLimits
	active  map[domain.OperationID]*activeOperation
	closed  bool
	count   uint32
}

type activeOperation struct {
	cancel context.CancelFunc
	done   chan struct{}
}

func NewServer(config ServerConfig) (*Server, error) {
	if err := config.PluginID.Validate(); err != nil {
		return nil, err
	}
	if len(config.Adapters) == 0 || config.Invoke == nil {
		return nil, invalidProtocol(string(config.PluginID), "plugin server adapters and invocation handler are required")
	}
	manifest := InitializeResult{
		PluginID: config.PluginID, ProtocolVersion: ProtocolVersion, Adapters: config.Adapters,
	}
	if err := ValidateInitializeResult(manifest, nil); err != nil {
		return nil, err
	}
	if config.MaxConcurrentOperations == 0 {
		config.MaxConcurrentOperations = defaultMaxConcurrentOperations
	}
	return &Server{config: config, active: make(map[domain.OperationID]*activeOperation)}, nil
}

func (server *Server) Serve(ctx context.Context, input io.Reader, output io.Writer) error {
	if input == nil || output == nil {
		return invalidProtocol(string(server.config.PluginID), "plugin server streams are required")
	}
	scanner := bufio.NewScanner(input)
	scanner.Buffer(make([]byte, 4096), maxProtocolJSONBytes)
	var operations sync.WaitGroup
	for scanner.Scan() {
		line := append([]byte(nil), scanner.Bytes()...)
		var request Request
		if err := json.Unmarshal(line, &request); err != nil {
			return invalidProtocol(string(server.config.PluginID), "JSON-RPC request cannot be decoded")
		}
		if request.JSONRPC != JSONRPCVersion || request.ID == "" || request.Method == "" || !json.Valid(request.Params) {
			return invalidProtocol(request.ID, "JSON-RPC request envelope is invalid")
		}
		if request.Method == MethodInvoke {
			operations.Add(1)
			go func() {
				defer operations.Done()
				server.handleInvoke(ctx, output, request)
			}()
			continue
		}
		stop := server.handleControl(ctx, output, request)
		if stop {
			break
		}
	}
	if err := scanner.Err(); err != nil {
		server.cancelAll()
		operations.Wait()
		return err
	}
	server.cancelAll()
	operations.Wait()
	return nil
}

func (server *Server) handleControl(
	ctx context.Context,
	output io.Writer,
	request Request,
) bool {
	var result json.RawMessage
	var err error
	stop := false
	switch request.Method {
	case MethodInitialize:
		result, err = server.initialize(request.Params)
	case MethodCancel:
		result, err = server.cancel(request.Params)
	case MethodReconcile:
		result, err = server.reconcile(ctx, request.Params)
	case MethodAdoptHandles:
		result, err = server.adopt(request.Params)
	case MethodShutdown:
		result = json.RawMessage(`{"shutdown":true}`)
		server.stateMu.Lock()
		server.closed = true
		server.stateMu.Unlock()
		stop = true
	default:
		err = invalidProtocol(request.Method, "plugin method is unknown")
	}
	_ = server.writeResponse(output, request.ID, result, err)
	return stop
}

func (server *Server) initialize(payload json.RawMessage) (json.RawMessage, error) {
	var params InitializeParams
	if err := json.Unmarshal(payload, &params); err != nil {
		return nil, invalidProtocol("initialize", "initialization parameters cannot be decoded")
	}
	if err := ValidateInitializeParams(params); err != nil {
		return nil, err
	}
	supported := false
	for _, version := range params.SupportedProtocolVersions {
		if version == ProtocolVersion {
			supported = true
			break
		}
	}
	if !supported {
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Resource: string(server.config.PluginID),
			Message: "plugin protocol version is unsupported",
		}
	}
	server.stateMu.Lock()
	alreadyInitialized := server.limits.MaxMessageBytes != 0
	server.stateMu.Unlock()
	if alreadyInitialized {
		return nil, &domain.Error{
			Code: domain.ErrorCodeConflict, Resource: string(server.config.PluginID),
			Message: "plugin server is already initialized",
		}
	}
	adoption := server.adoptionDecisions(params.ActiveHandles)
	result := InitializeResult{
		PluginID: server.config.PluginID, ProtocolVersion: ProtocolVersion,
		Adapters: server.config.Adapters, HandleAdoption: adoption,
	}
	if err := ValidateInitializeResult(result, params.ActiveHandles); err != nil {
		return nil, err
	}
	server.stateMu.Lock()
	server.limits = params.Limits
	server.stateMu.Unlock()
	return marshalServerResult(result)
}

func (server *Server) handleInvoke(ctx context.Context, output io.Writer, request Request) {
	var envelope OperationEnvelope
	if err := json.Unmarshal(request.Params, &envelope); err != nil {
		_ = server.writeResponse(output, request.ID, nil, invalidProtocol(request.ID, "operation envelope cannot be decoded"))
		return
	}
	manifest, found := server.manifest(envelope.AdapterID, envelope.Port)
	if !found {
		_ = server.writeResponse(output, request.ID, nil, invalidProtocol(envelope.AdapterID, "adapter is not declared"))
		return
	}
	if err := ValidateOperationEnvelope(envelope, manifest); err != nil {
		_ = server.writeResponse(output, request.ID, nil, err)
		return
	}
	if envelope.Handle != nil && envelope.Handle.PluginID != server.config.PluginID {
		_ = server.writeResponse(
			output, request.ID, nil,
			invalidProtocol(string(envelope.ID), "operation handle belongs to another plugin"),
		)
		return
	}
	operationContext, active, err := server.beginOperation(ctx, envelope)
	if err != nil {
		_ = server.writeResponse(output, request.ID, nil, err)
		return
	}
	defer server.endOperation(envelope.ID, active)
	sequence := uint64(0)
	emit := func(kind string, payload json.RawMessage) error {
		sequence++
		event := OperationEvent{
			OperationID: envelope.ID, Sequence: sequence, Kind: kind,
			Payload: payload, OccurredAt: time.Now().UTC(),
		}
		if err := ValidateOperationEvent(event, sequence-1); err != nil {
			return err
		}
		encoded, err := json.Marshal(event)
		if err != nil {
			return err
		}
		return server.writeNotification(output, Notification{
			JSONRPC: JSONRPCVersion, Method: MethodEvent, Params: encoded,
		})
	}
	result, invokeErr := server.config.Invoke(operationContext, envelope, emit)
	if invokeErr == nil {
		if result.ID == "" {
			result.ID = envelope.ID
		}
		if result.State == "" {
			result.State = domain.OperationStateSucceeded
		}
		invokeErr = ValidateOperationResult(result, envelope, manifest)
	}
	payload, marshalErr := marshalServerResult(result)
	if marshalErr != nil {
		invokeErr = errors.Join(invokeErr, marshalErr)
	}
	_ = server.writeResponse(output, request.ID, payload, invokeErr)
}

func (server *Server) beginOperation(
	ctx context.Context,
	envelope OperationEnvelope,
) (context.Context, *activeOperation, error) {
	server.stateMu.Lock()
	defer server.stateMu.Unlock()
	if server.limits.MaxMessageBytes == 0 || server.closed {
		return nil, nil, invalidProtocol(string(envelope.ID), "plugin server is not active")
	}
	if server.count >= server.config.MaxConcurrentOperations {
		return nil, nil, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Resource: string(envelope.ID),
			Message: "plugin operation limit is reached",
		}
	}
	if _, found := server.active[envelope.ID]; found {
		return nil, nil, &domain.Error{
			Code: domain.ErrorCodeConflict, Resource: string(envelope.ID),
			Message: "plugin operation is already active",
		}
	}
	operationContext, cancel := operationDeadline(ctx, envelope.Deadline, server.limits)
	active := &activeOperation{cancel: cancel, done: make(chan struct{})}
	server.active[envelope.ID] = active
	server.count++
	return operationContext, active, nil
}

func (server *Server) endOperation(id domain.OperationID, active *activeOperation) {
	active.cancel()
	server.stateMu.Lock()
	delete(server.active, id)
	if server.count > 0 {
		server.count--
	}
	close(active.done)
	server.stateMu.Unlock()
}

func (server *Server) cancel(payload json.RawMessage) (json.RawMessage, error) {
	var params CancelParams
	if err := json.Unmarshal(payload, &params); err != nil || params.OperationID.Validate() != nil || params.Deadline.IsZero() {
		return nil, invalidProtocol("cancel", "cancellation parameters are invalid")
	}
	server.stateMu.Lock()
	active := server.active[params.OperationID]
	server.stateMu.Unlock()
	if active == nil {
		return json.RawMessage(`{"cancelled":false}`), nil
	}
	active.cancel()
	timer := time.NewTimer(time.Until(params.Deadline))
	defer timer.Stop()
	select {
	case <-active.done:
		return json.RawMessage(`{"cancelled":true}`), nil
	case <-timer.C:
		return nil, context.DeadlineExceeded
	}
}

func (server *Server) reconcile(ctx context.Context, payload json.RawMessage) (json.RawMessage, error) {
	var params ReconcileParams
	if err := json.Unmarshal(payload, &params); err != nil {
		return nil, invalidProtocol("reconcile", "reconciliation parameters cannot be decoded")
	}
	if err := server.validateHandles(params.Handles); err != nil {
		return nil, err
	}
	if server.config.Reconcile != nil {
		result, err := server.config.Reconcile(ctx, params.Handles)
		if err != nil {
			return nil, err
		}
		return marshalServerResult(result)
	}
	result := make([]ReconcileResult, 0, len(params.Handles))
	for _, handle := range params.Handles {
		result = append(result, ReconcileResult{HandleID: handle.ID, State: ReconcileStateOrphaned})
	}
	return marshalServerResult(result)
}

func (server *Server) adopt(payload json.RawMessage) (json.RawMessage, error) {
	var params ReconcileParams
	if err := json.Unmarshal(payload, &params); err != nil {
		return nil, invalidProtocol("adopt handles", "handle parameters cannot be decoded")
	}
	if err := server.validateHandles(params.Handles); err != nil {
		return nil, err
	}
	return marshalServerResult(server.adoptionDecisions(params.Handles))
}

func (server *Server) validateHandles(handles []HandleDescriptor) error {
	seen := make(map[domain.AdapterHandleID]struct{}, len(handles))
	for _, handle := range handles {
		if err := validateHandleDescriptor(handle); err != nil {
			return err
		}
		if handle.PluginID != server.config.PluginID {
			return invalidProtocol(string(handle.ID), "handle belongs to another plugin")
		}
		if !manifestSupportsHandle(server.config.Adapters, handle) {
			return invalidProtocol(string(handle.ID), "handle is not supported by a declared adapter")
		}
		if _, found := seen[handle.ID]; found {
			return invalidProtocol(string(handle.ID), "handles must be unique")
		}
		seen[handle.ID] = struct{}{}
	}
	return nil
}

func (server *Server) adoptionDecisions(handles []HandleDescriptor) []HandleAdoption {
	result := make([]HandleAdoption, 0, len(handles))
	for _, handle := range handles {
		adopted := handle.PluginID == server.config.PluginID && manifestSupportsHandle(server.config.Adapters, handle)
		reason := ""
		if !adopted {
			reason = "handle is incompatible with this plugin"
		}
		result = append(result, HandleAdoption{HandleID: handle.ID, Adopted: adopted, Reason: reason})
	}
	return result
}

func (server *Server) manifest(id string, port domain.AdapterPort) (AdapterManifest, bool) {
	for _, manifest := range server.config.Adapters {
		if manifest.ID == id && manifest.Port == port {
			return manifest, true
		}
	}
	return AdapterManifest{}, false
}

func (server *Server) cancelAll() {
	server.stateMu.Lock()
	for _, active := range server.active {
		active.cancel()
	}
	server.closed = true
	server.stateMu.Unlock()
}

func (server *Server) writeResponse(
	output io.Writer,
	id string,
	result json.RawMessage,
	responseErr error,
) error {
	response := Response{JSONRPC: JSONRPCVersion, ID: id, Result: result}
	if responseErr != nil {
		response.Result = nil
		response.Error = rpcError(responseErr)
	}
	server.writeMu.Lock()
	defer server.writeMu.Unlock()
	return json.NewEncoder(output).Encode(response)
}

func (server *Server) writeNotification(output io.Writer, notification Notification) error {
	server.writeMu.Lock()
	defer server.writeMu.Unlock()
	return json.NewEncoder(output).Encode(notification)
}

func rpcError(err error) *RPCError {
	code := -32603
	var domainError *domain.Error
	data := json.RawMessage(nil)
	if errors.As(err, &domainError) {
		switch domainError.Code {
		case domain.ErrorCodeInvalidArgument:
			code = -32602
		case domain.ErrorCodeNotFound:
			code = -32601
		case domain.ErrorCodeConflict:
			code = -32009
		case domain.ErrorCodeUnsupportedVersion:
			code = -32010
		case domain.ErrorCodeBudgetExhausted:
			code = -32011
		case domain.ErrorCodeUnauthorized:
			code = -32012
		case domain.ErrorCodeIndeterminate:
			code = -32013
		case domain.ErrorCodeInternal:
			code = -32603
		}
		data, _ = json.Marshal(domainError)
	}
	return &RPCError{Code: code, Message: err.Error(), Data: data}
}

type serverResult interface {
	InitializeResult | OperationResult | []ReconcileResult | []HandleAdoption
}

func marshalServerResult[Value serverResult](value Value) (json.RawMessage, error) {
	encoded, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	return encoded, nil
}
