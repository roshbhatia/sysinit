package plugin

import (
	"context"
	"encoding/json"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestMultiplexerRoutesOperationsAndReconciliation(t *testing.T) {
	t.Parallel()

	activityManifest := testMultiplexerManifest(t, "activity-fixture", domain.AdapterPortActivity, "activity.import")
	annotationManifest := testMultiplexerManifest(t, "annotation-fixture", domain.AdapterPortAnnotation, "annotation.sync")
	activityCalled := false
	multiplexer, err := NewMultiplexer([]AdapterRegistration{
		{
			Manifest: activityManifest,
			Invoke: func(
				_ context.Context, envelope OperationEnvelope, _ EventEmitter,
			) (OperationResult, error) {
				activityCalled = true
				return OperationResult{
					ID: envelope.ID, State: domain.OperationStateSucceeded, Output: json.RawMessage(`{}`),
				}, nil
			},
			Reconcile: func(_ context.Context, handles []HandleDescriptor) ([]ReconcileResult, error) {
				return []ReconcileResult{{HandleID: handles[0].ID, State: ReconcileStateAdopted}}, nil
			},
		},
		{
			Manifest: annotationManifest,
			Invoke: func(
				_ context.Context, envelope OperationEnvelope, _ EventEmitter,
			) (OperationResult, error) {
				return OperationResult{
					ID: envelope.ID, State: domain.OperationStateSucceeded, Output: json.RawMessage(`{}`),
				}, nil
			},
		},
	})
	if err != nil {
		t.Fatalf("NewMultiplexer() returned %v", err)
	}
	envelope := OperationEnvelope{
		ID: "operation-1", AdapterID: activityManifest.ID, Port: activityManifest.Port,
		Operation: "activity.import", Input: json.RawMessage(`{}`), Deadline: time.Now().Add(time.Minute),
	}
	if _, err := multiplexer.Invoke(context.Background(), envelope, nil); err != nil || !activityCalled {
		t.Fatalf("Invoke() = called %t, error %v", activityCalled, err)
	}
	handles := []HandleDescriptor{
		{ID: "handle-activity", AdapterID: activityManifest.ID, Port: activityManifest.Port},
		{ID: "handle-annotation", AdapterID: annotationManifest.ID, Port: annotationManifest.Port},
	}
	results, err := multiplexer.Reconcile(context.Background(), handles)
	if err != nil {
		t.Fatalf("Reconcile() returned %v", err)
	}
	if len(results) != 2 || results[0].State != ReconcileStateAdopted ||
		results[1].State != ReconcileStateOrphaned {
		t.Fatalf("reconciliation = %#v", results)
	}
	if len(multiplexer.Manifests()) != 2 {
		t.Fatalf("manifest count = %d, want 2", len(multiplexer.Manifests()))
	}
}

func TestMultiplexerRejectsDuplicateRegistration(t *testing.T) {
	t.Parallel()

	manifest := testMultiplexerManifest(t, "activity-fixture", domain.AdapterPortActivity, "activity.import")
	handler := func(_ context.Context, envelope OperationEnvelope, _ EventEmitter) (OperationResult, error) {
		return OperationResult{ID: envelope.ID, State: domain.OperationStateSucceeded, Output: json.RawMessage(`{}`)}, nil
	}
	_, err := NewMultiplexer([]AdapterRegistration{
		{Manifest: manifest, Invoke: handler}, {Manifest: manifest, Invoke: handler},
	})
	if err == nil {
		t.Fatal("NewMultiplexer() accepted a duplicate registration")
	}
}

func testMultiplexerManifest(
	t *testing.T,
	id string,
	port domain.AdapterPort,
	operation string,
) AdapterManifest {
	t.Helper()
	schema := json.RawMessage(`{
  "$schema":"https://json-schema.org/draft/2020-12/schema",
  "type":"object","additionalProperties":false
}`)
	contract, err := NewSchemaContract(schema, schema, true, true)
	if err != nil {
		t.Fatalf("NewSchemaContract() returned %v", err)
	}
	return AdapterManifest{
		ID: id, Port: port, Capabilities: []string{"fixture"}, HandleVersions: []uint32{1},
		Operations: map[string]SchemaContract{operation: contract},
	}
}
