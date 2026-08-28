package plugin

import (
	"encoding/json"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestInitializeNegotiatesEightTypedPorts(t *testing.T) {
	t.Parallel()

	adapters := make([]AdapterManifest, 0, len(StandardOperations))
	for port, operations := range StandardOperations {
		contracts := make(map[string]SchemaContract, len(operations))
		for _, operation := range operations {
			contracts[operation] = testSchemaContract(t)
		}
		adapters = append(adapters, AdapterManifest{
			ID: string(port) + "-fixture", Port: port, Capabilities: []string{"fixture"},
			HandleVersions: []uint32{1}, Operations: contracts,
		})
	}
	result := InitializeResult{
		PluginID: "fixture", ProtocolVersion: ProtocolVersion, Adapters: adapters,
		HandleAdoption: []HandleAdoption{{HandleID: "handle-1", Adopted: true}},
	}
	active := []HandleDescriptor{{
		ID: "handle-1", PluginID: "fixture", Port: domain.AdapterPortAgentRuntime,
		AdapterID: "agent-runtime-fixture", FormatVersion: 1,
		OpaqueValue: json.RawMessage(`{"session":"one"}`),
	}}
	if err := ValidateInitializeResult(result, active); err != nil {
		t.Fatalf("ValidateInitializeResult() returned %v", err)
	}
	if len(result.Adapters) != 8 {
		t.Fatalf("adapter count = %d", len(result.Adapters))
	}
	originalAdapterID := result.Adapters[0].ID
	result.Adapters[0].ID = "plugin::adapter"
	if err := ValidateInitializeResult(result, active); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("selector-delimited adapter error = %v", err)
	}
	result.Adapters[0].ID = originalAdapterID
	unsupported := active[0]
	unsupported.FormatVersion = 2
	result.HandleAdoption[0] = HandleAdoption{
		HandleID: unsupported.ID, Adopted: false, Reason: "handle format is unsupported",
	}
	if err := ValidateInitializeResult(result, []HandleDescriptor{unsupported}); err != nil {
		t.Fatalf("unsupported handle adoption error = %v", err)
	}
	result.HandleAdoption[0] = HandleAdoption{HandleID: unsupported.ID, Adopted: true}
	if err := ValidateInitializeResult(result, []HandleDescriptor{unsupported}); !domain.IsErrorCode(
		err, domain.ErrorCodeConflict,
	) {
		t.Fatalf("false supported handle adoption error = %v", err)
	}
}

func TestSchemaNegotiationRejectsChangedDigest(t *testing.T) {
	t.Parallel()

	contract := testSchemaContract(t)
	contract.ResponseSchemaDigest = "sha256:" + string(make([]byte, 64))
	if err := ValidateSchemaContract("planning.snapshot", contract); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("ValidateSchemaContract() error = %v", err)
	}
}

func TestOperationEnvelopeAndResultUseNegotiatedSchemas(t *testing.T) {
	t.Parallel()

	manifest := AdapterManifest{
		ID: "runtime", Port: domain.AdapterPortAgentRuntime, HandleVersions: []uint32{1},
		Operations: map[string]SchemaContract{"agent-runtime.start": testSchemaContract(t)},
	}
	envelope := OperationEnvelope{
		ID: "operation-1", AdapterID: manifest.ID, Port: manifest.Port,
		Operation: "agent-runtime.start", Input: json.RawMessage(`{"value":"request"}`),
		Deadline: time.Now().Add(time.Minute),
	}
	if err := ValidateOperationEnvelope(envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationEnvelope() returned %v", err)
	}
	result := OperationResult{
		ID: envelope.ID, State: domain.OperationStateSucceeded,
		Output: json.RawMessage(`{"value":"response"}`),
	}
	if err := ValidateOperationResult(result, envelope, manifest); err != nil {
		t.Fatalf("ValidateOperationResult() returned %v", err)
	}
	result.Handle = &AdapterHandleValue{
		FormatVersion: 2, OpaqueValue: json.RawMessage(`{"private":"handle"}`),
	}
	if err := ValidateOperationResult(result, envelope, manifest); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("unnegotiated handle ValidateOperationResult() error = %v", err)
	}
	result.Handle = nil
	result.Output = json.RawMessage(`{"missing":"value"}`)
	if err := ValidateOperationResult(result, envelope, manifest); !domain.IsErrorCode(
		err, domain.ErrorCodeInvalidArgument,
	) {
		t.Fatalf("invalid ValidateOperationResult() error = %v", err)
	}
}

func TestOperationEventsRequireMonotonicSequence(t *testing.T) {
	t.Parallel()

	event := OperationEvent{
		OperationID: "operation-1", Sequence: 2, Kind: "output",
		Payload: json.RawMessage(`{"text":"value"}`), OccurredAt: time.Now(),
	}
	if err := ValidateOperationEvent(event, 0); !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("ValidateOperationEvent() error = %v", err)
	}
}

func testSchemaContract(t *testing.T) SchemaContract {
	t.Helper()
	schema := json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object",
  "properties":{"value":{"type":"string"}},
  "required":["value"],
  "additionalProperties":false
}`)
	digest, err := workflowmodel.JSONSchemaDigest(schema)
	if err != nil {
		t.Fatalf("JSONSchemaDigest() returned %v", err)
	}
	return SchemaContract{
		RequestSchema: schema, RequestSchemaDigest: digest,
		ResponseSchema: schema, ResponseSchemaDigest: digest,
	}
}
