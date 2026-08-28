package plugin

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	resultmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/result"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	ProtocolVersion uint32 = 1
	JSONRPCVersion         = "2.0"

	MethodInitialize     = "plugin.initialize"
	MethodInvoke         = "plugin.invoke"
	MethodCancel         = "plugin.cancel"
	MethodEvent          = "plugin.event"
	MethodReconcile      = "plugin.reconcile"
	MethodAdoptHandles   = "plugin.adopt-handles"
	MethodShutdown       = "plugin.shutdown"
	maxProtocolJSONBytes = 1 << 20
)

var StandardOperations = map[domain.AdapterPort][]string{
	domain.AdapterPortPlanning: {
		"planning.discover", "planning.snapshot", "planning.action",
	},
	domain.AdapterPortWorkspace: {
		"workspace.create", "workspace.add-repository", "workspace.remove-repository", "workspace.snapshot",
	},
	domain.AdapterPortEnvironment: {
		"environment.resolve", "environment.execute", "environment.check",
	},
	domain.AdapterPortAgentRuntime: {
		"agent-runtime.start", "agent-runtime.input", "agent-runtime.interrupt", "agent-runtime.resume",
		"agent-runtime.reconcile",
	},
	domain.AdapterPortAttachment: {
		"attachment.open", "attachment.close",
	},
	domain.AdapterPortActivity: {
		"activity.import", "activity.observe",
	},
	domain.AdapterPortAnnotation: {
		"annotation.sync", "annotation.answer",
	},
	domain.AdapterPortEffect: {
		"effect.observe",
	},
}

type Request struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      string          `json:"id"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params"`
}

type Response struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      string          `json:"id"`
	Result  json.RawMessage `json:"result,omitempty"`
	Error   *RPCError       `json:"error,omitempty"`
}

type Notification struct {
	JSONRPC string          `json:"jsonrpc"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params"`
}

type RPCError struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data,omitempty"`
}

type WireLimits struct {
	MaxMessageBytes     uint64 `json:"maxMessageBytes"`
	MaxEventsPerSecond  uint32 `json:"maxEventsPerSecond"`
	MaxOperationSeconds uint32 `json:"maxOperationSeconds"`
}

type InitializeParams struct {
	SupportedProtocolVersions []uint32           `json:"supportedProtocolVersions"`
	ActiveHandles             []HandleDescriptor `json:"activeHandles"`
	Limits                    WireLimits         `json:"limits"`
}

type InitializeResult struct {
	PluginID        domain.PluginID   `json:"pluginId"`
	ProtocolVersion uint32            `json:"protocolVersion"`
	Adapters        []AdapterManifest `json:"adapters"`
	HandleAdoption  []HandleAdoption  `json:"handleAdoption"`
}

type AdapterManifest struct {
	ID             string                    `json:"id"`
	Port           domain.AdapterPort        `json:"port"`
	Capabilities   []string                  `json:"capabilities"`
	HandleVersions []uint32                  `json:"handleVersions"`
	Operations     map[string]SchemaContract `json:"operations"`
}

type SchemaContract struct {
	RequestSchema        json.RawMessage `json:"requestSchema"`
	RequestSchemaDigest  string          `json:"requestSchemaDigest"`
	ResponseSchema       json.RawMessage `json:"responseSchema"`
	ResponseSchemaDigest string          `json:"responseSchemaDigest"`
	Retryable            bool            `json:"retryable"`
	Idempotent           bool            `json:"idempotent"`
}

func NewSchemaContract(
	requestSchema json.RawMessage,
	responseSchema json.RawMessage,
	retryable bool,
	idempotent bool,
) (SchemaContract, error) {
	requestDigest, err := workflowmodel.JSONSchemaDigest(requestSchema)
	if err != nil {
		return SchemaContract{}, err
	}
	responseDigest, err := workflowmodel.JSONSchemaDigest(responseSchema)
	if err != nil {
		return SchemaContract{}, err
	}
	contract := SchemaContract{
		RequestSchema: requestSchema, RequestSchemaDigest: requestDigest,
		ResponseSchema: responseSchema, ResponseSchemaDigest: responseDigest,
		Retryable: retryable, Idempotent: idempotent,
	}
	if err := ValidateSchemaContract("schema contract", contract); err != nil {
		return SchemaContract{}, err
	}
	return contract, nil
}

type HandleDescriptor struct {
	ID            domain.AdapterHandleID `json:"id"`
	PluginID      domain.PluginID        `json:"pluginId"`
	Port          domain.AdapterPort     `json:"port"`
	AdapterID     string                 `json:"adapterId"`
	FormatVersion uint32                 `json:"formatVersion"`
	OpaqueValue   json.RawMessage        `json:"opaqueValue"`
}

type HandleAdoption struct {
	HandleID domain.AdapterHandleID `json:"handleId"`
	Adopted  bool                   `json:"adopted"`
	Reason   string                 `json:"reason,omitempty"`
}

type OperationEnvelope struct {
	ID        domain.OperationID      `json:"id"`
	AdapterID string                  `json:"adapterId"`
	Port      domain.AdapterPort      `json:"port"`
	Operation string                  `json:"operation"`
	HandleID  *domain.AdapterHandleID `json:"handleId,omitempty"`
	Handle    *HandleDescriptor       `json:"handle,omitempty"`
	JobPolicy *domain.JobPolicy       `json:"jobPolicy,omitempty"`
	Input     json.RawMessage         `json:"input"`
	Deadline  time.Time               `json:"deadline"`
}

type OperationResult struct {
	ID           domain.OperationID    `json:"id"`
	State        domain.OperationState `json:"state"`
	SessionState domain.SessionState   `json:"sessionState,omitempty"`
	Output       json.RawMessage       `json:"output,omitempty"`
	Handle       *AdapterHandleValue   `json:"handle,omitempty"`
	Error        *RPCError             `json:"error,omitempty"`
}

type AdapterHandleValue struct {
	FormatVersion uint32          `json:"formatVersion"`
	OpaqueValue   json.RawMessage `json:"opaqueValue"`
}

type OperationEvent struct {
	OperationID domain.OperationID `json:"operationId"`
	Sequence    uint64             `json:"sequence"`
	Kind        string             `json:"kind"`
	Payload     json.RawMessage    `json:"payload"`
	OccurredAt  time.Time          `json:"occurredAt"`
}

type CancelParams struct {
	OperationID domain.OperationID `json:"operationId"`
	Deadline    time.Time          `json:"deadline"`
}

type ReconcileParams struct {
	Handles []HandleDescriptor `json:"handles"`
}

type ReconcileState = domain.SessionReconciliationState

const (
	ReconcileStateAdopted    = domain.SessionReconciliationAdopted
	ReconcileStateCompleted  = domain.SessionReconciliationCompleted
	ReconcileStateOrphaned   = domain.SessionReconciliationOrphaned
	ReconcileStateRehydrated = domain.SessionReconciliationRehydrated
)

type ReconcileResult struct {
	HandleID domain.AdapterHandleID `json:"handleId"`
	State    ReconcileState         `json:"state"`
	Output   json.RawMessage        `json:"output,omitempty"`
}

func ValidateInitializeParams(params InitializeParams) error {
	if len(params.SupportedProtocolVersions) == 0 || params.Limits.MaxMessageBytes == 0 ||
		params.Limits.MaxEventsPerSecond == 0 || params.Limits.MaxOperationSeconds == 0 {
		return invalidProtocol("initialize", "protocol versions and wire limits are required")
	}
	seenVersions := make(map[uint32]struct{}, len(params.SupportedProtocolVersions))
	for _, version := range params.SupportedProtocolVersions {
		if version == 0 {
			return invalidProtocol("initialize", "protocol version must be positive")
		}
		if _, found := seenVersions[version]; found {
			return invalidProtocol("initialize", "protocol versions must be unique")
		}
		seenVersions[version] = struct{}{}
	}
	seenHandles := make(map[domain.AdapterHandleID]struct{}, len(params.ActiveHandles))
	for _, handle := range params.ActiveHandles {
		if err := validateHandleDescriptor(handle); err != nil {
			return err
		}
		if _, found := seenHandles[handle.ID]; found {
			return invalidProtocol("initialize", "active handles must be unique")
		}
		seenHandles[handle.ID] = struct{}{}
	}
	return nil
}

func ValidateInitializeResult(result InitializeResult, activeHandles []HandleDescriptor) error {
	if err := result.PluginID.Validate(); err != nil {
		return err
	}
	if result.ProtocolVersion != ProtocolVersion {
		return &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "initialize plugin", Resource: string(result.PluginID),
			Message: "plugin protocol version is unsupported",
		}
	}
	if len(result.Adapters) == 0 {
		return invalidProtocol(string(result.PluginID), "plugin declares no adapter ports")
	}
	seenAdapters := make(map[string]struct{}, len(result.Adapters))
	for _, adapter := range result.Adapters {
		if err := validateAdapterManifest(adapter); err != nil {
			return err
		}
		if _, found := seenAdapters[adapter.ID]; found {
			return invalidProtocol(adapter.ID, "adapter identifiers must be unique")
		}
		seenAdapters[adapter.ID] = struct{}{}
	}
	adoption := make(map[domain.AdapterHandleID]HandleAdoption, len(result.HandleAdoption))
	for _, decision := range result.HandleAdoption {
		if err := decision.HandleID.Validate(); err != nil {
			return err
		}
		if _, found := adoption[decision.HandleID]; found {
			return invalidProtocol(string(decision.HandleID), "handle adoption decisions must be unique")
		}
		adoption[decision.HandleID] = decision
	}
	for _, handle := range activeHandles {
		if handle.PluginID != result.PluginID {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "initialize plugin", Resource: string(handle.ID),
				Message: "active handle belongs to another plugin",
			}
		}
		decision, found := adoption[handle.ID]
		if !found {
			return invalidProtocol(string(handle.ID), "plugin omitted an active handle adoption decision")
		}
		if decision.Adopted && !manifestSupportsHandle(result.Adapters, handle) {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "initialize plugin", Resource: string(handle.ID),
				Message: "plugin adopted a handle outside its manifest",
			}
		}
		if !decision.Adopted && decision.Reason == "" {
			return invalidProtocol(string(handle.ID), "rejected handle adoption requires a reason")
		}
	}
	if len(adoption) != len(activeHandles) {
		return invalidProtocol(string(result.PluginID), "plugin returned adoption decisions for unknown handles")
	}
	return nil
}

func manifestSupportsHandle(adapters []AdapterManifest, handle HandleDescriptor) bool {
	for _, adapter := range adapters {
		if adapter.ID != handle.AdapterID || adapter.Port != handle.Port {
			continue
		}
		for _, version := range adapter.HandleVersions {
			if version == handle.FormatVersion {
				return true
			}
		}
	}
	return false
}

func validateAdapterManifest(adapter AdapterManifest) error {
	if adapter.ID == "" || !adapter.Port.Valid() {
		return invalidProtocol(adapter.ID, "adapter identifier and port are required")
	}
	if strings.Contains(adapter.ID, "::") {
		return invalidProtocol(adapter.ID, "adapter identifier contains the selector delimiter")
	}
	if len(adapter.HandleVersions) == 0 || len(adapter.Operations) == 0 {
		return invalidProtocol(adapter.ID, "handle versions and operations are required")
	}
	if err := validateUniqueStrings(adapter.Capabilities, adapter.ID+" capabilities"); err != nil {
		return err
	}
	versions := append([]uint32(nil), adapter.HandleVersions...)
	sort.Slice(versions, func(first int, second int) bool { return versions[first] < versions[second] })
	for index, version := range versions {
		if version == 0 || index > 0 && versions[index-1] == version {
			return invalidProtocol(adapter.ID, "handle versions must be positive and unique")
		}
	}
	prefix := string(adapter.Port) + "."
	for operation, contract := range adapter.Operations {
		if !strings.HasPrefix(operation, prefix) || len(operation) == len(prefix) {
			return invalidProtocol(operation, "operation does not belong to its adapter port")
		}
		if err := ValidateSchemaContract(operation, contract); err != nil {
			return err
		}
	}
	return nil
}

func ValidateSchemaContract(operation string, contract SchemaContract) error {
	for _, schema := range []struct {
		document json.RawMessage
		digest   string
		name     string
	}{
		{document: contract.RequestSchema, digest: contract.RequestSchemaDigest, name: "request"},
		{document: contract.ResponseSchema, digest: contract.ResponseSchemaDigest, name: "response"},
	} {
		computed, err := workflowmodel.JSONSchemaDigest(schema.document)
		if err != nil {
			return err
		}
		if computed != schema.digest {
			return invalidProtocol(operation, schema.name+" schema digest does not match")
		}
		if _, err := resultmodel.NewValidator(schema.document, schema.digest, 0, maxProtocolJSONBytes); err != nil {
			return invalidProtocol(operation, schema.name+" schema is invalid")
		}
	}
	return nil
}

func ValidateOperationEnvelope(envelope OperationEnvelope, manifest AdapterManifest) error {
	if err := envelope.ID.Validate(); err != nil {
		return err
	}
	if envelope.AdapterID != manifest.ID || envelope.Port != manifest.Port {
		return invalidProtocol(string(envelope.ID), "operation adapter does not match its negotiated manifest")
	}
	contract, found := manifest.Operations[envelope.Operation]
	if !found {
		return invalidProtocol(string(envelope.ID), "operation was not negotiated")
	}
	if envelope.Deadline.IsZero() || !json.Valid(envelope.Input) {
		return invalidProtocol(string(envelope.ID), "operation deadline and JSON input are required")
	}
	if envelope.JobPolicy != nil {
		if err := envelope.JobPolicy.Validate(); err != nil {
			return err
		}
	}
	if (envelope.HandleID == nil) != (envelope.Handle == nil) {
		return invalidProtocol(string(envelope.ID), "operation handle identifier and value must appear together")
	}
	if envelope.Handle != nil {
		if err := validateHandleDescriptor(*envelope.Handle); err != nil {
			return err
		}
		if envelope.Handle.ID != *envelope.HandleID || envelope.Handle.Port != envelope.Port ||
			envelope.Handle.AdapterID != envelope.AdapterID {
			return invalidProtocol(string(envelope.ID), "operation handle does not match its envelope")
		}
	}
	validator, err := resultmodel.NewValidator(
		contract.RequestSchema, contract.RequestSchemaDigest, 0, maxProtocolJSONBytes,
	)
	if err != nil {
		return err
	}
	if decision := validator.Validate(envelope.Input, 0); !decision.Accepted {
		return invalidProtocol(string(envelope.ID), "operation input violates its negotiated schema")
	}
	return nil
}

func ValidateOperationResult(result OperationResult, envelope OperationEnvelope, manifest AdapterManifest) error {
	if result.ID != envelope.ID || !result.State.Valid() {
		return invalidProtocol(string(envelope.ID), "operation result identity or state is invalid")
	}
	if result.State == domain.OperationStateSucceeded {
		contract := manifest.Operations[envelope.Operation]
		validator, err := resultmodel.NewValidator(
			contract.ResponseSchema, contract.ResponseSchemaDigest, 0, maxProtocolJSONBytes,
		)
		if err != nil {
			return err
		}
		if decision := validator.Validate(result.Output, 0); !decision.Accepted {
			return invalidProtocol(string(result.ID), "operation output violates its negotiated schema")
		}
	}
	if result.Handle != nil {
		if result.SessionState != "" && result.SessionState != domain.SessionStateRunning &&
			result.SessionState != domain.SessionStateWaiting && result.SessionState != domain.SessionStateCompleted {
			return invalidProtocol(string(result.ID), "operation returned an invalid session state")
		}
		if result.Handle.FormatVersion == 0 || !json.Valid(result.Handle.OpaqueValue) {
			return invalidProtocol(string(result.ID), "operation returned an invalid opaque handle")
		}
		supported := false
		for _, version := range manifest.HandleVersions {
			if version == result.Handle.FormatVersion {
				supported = true
				break
			}
		}
		if !supported {
			return invalidProtocol(string(result.ID), "operation returned an unnegotiated handle format")
		}
	}
	return nil
}

func ValidateOperationEvent(event OperationEvent, previousSequence uint64) error {
	if err := event.OperationID.Validate(); err != nil {
		return err
	}
	if event.Sequence != previousSequence+1 || event.Kind == "" || event.OccurredAt.IsZero() ||
		!json.Valid(event.Payload) {
		return invalidProtocol(string(event.OperationID), "operation event is invalid or out of order")
	}
	return nil
}

func validateHandleDescriptor(handle HandleDescriptor) error {
	if err := handle.ID.Validate(); err != nil {
		return err
	}
	if err := handle.PluginID.Validate(); err != nil {
		return err
	}
	if !handle.Port.Valid() || handle.AdapterID == "" || handle.FormatVersion == 0 ||
		len(handle.OpaqueValue) > maxProtocolJSONBytes ||
		!json.Valid(handle.OpaqueValue) {
		return invalidProtocol(
			string(handle.ID), "handle adapter, port, format version, and opaque value are required",
		)
	}
	return nil
}

func validateUniqueStrings(values []string, resource string) error {
	seen := make(map[string]struct{}, len(values))
	for _, value := range values {
		if value == "" {
			return invalidProtocol(resource, "values must not be empty")
		}
		if _, found := seen[value]; found {
			return invalidProtocol(resource, "values must be unique")
		}
		seen[value] = struct{}{}
	}
	return nil
}

func invalidProtocol(resource string, message string) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "validate plugin protocol", Resource: resource,
		Message: message,
	}
}

func NewRequest(id string, method string, params json.RawMessage) (Request, error) {
	if id == "" || method == "" || !json.Valid(params) {
		return Request{}, invalidProtocol(id, "JSON-RPC request is invalid")
	}
	return Request{JSONRPC: JSONRPCVersion, ID: id, Method: method, Params: params}, nil
}

func DecodeResponse(payload []byte, expectedID string) (Response, error) {
	var response Response
	if err := json.Unmarshal(payload, &response); err != nil {
		return Response{}, invalidProtocol(expectedID, fmt.Sprintf("JSON-RPC response cannot be decoded: %v", err))
	}
	if response.JSONRPC != JSONRPCVersion || response.ID != expectedID ||
		(response.Error == nil) == (len(response.Result) == 0) {
		return Response{}, invalidProtocol(expectedID, "JSON-RPC response envelope is invalid")
	}
	return response, nil
}
