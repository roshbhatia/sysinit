package sqlite

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"path/filepath"
	"sync"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestDecodeLegacyWorkflowAppliesSafeJobPolicy(t *testing.T) {
	t.Parallel()

	document := independentWorkflowDocument(t, 1, "legacy")
	var legacy map[string]json.RawMessage
	if err := json.Unmarshal(document, &legacy); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	legacy["schemaVersion"] = json.RawMessage(`"colchis.workflow/v1"`)
	legacy["evaluatorVersion"] = json.RawMessage(`"cue-0.17"`)
	delete(legacy, "jobDefaults")
	encoded, err := json.Marshal(legacy)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	digest := sha256.Sum256(encoded)
	definition, err := decodeResolvedDefinition(domain.WorkflowDefinition{
		ID: "legacy-definition", DefinitionSchemaVersion: workflowmodel.LegacyDefinitionSchemaVersion,
		EvaluatorVersion: workflowmodel.LegacyEvaluatorVersion,
		DefinitionDigest: fmt.Sprintf("sha256:%x", digest), ResolvedDocument: encoded,
	})
	if err != nil {
		t.Fatalf("decodeResolvedDefinition() returned %v", err)
	}
	if definition.SchemaVersion != workflowmodel.DefinitionSchemaVersion ||
		definition.JobDefaults != workflowmodel.SafeJobPolicy() ||
		definition.Nodes["legacy"].Policy != workflowmodel.SafeJobPolicy() {
		t.Fatalf("upgraded definition = %#v", definition)
	}
}

func TestWorkflowDefinitionIsImmutableAndSurvivesRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	document := independentWorkflowDocument(t, 1, "alpha")
	resolved := resolveWorkflowForStoreTest(t, document)
	created, err := store.CreateWorkflowDefinition(ctx, "definition-1", nil, document, resolved)
	if err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-1", nil, document, resolved); !domain.IsErrorCode(
		err, domain.ErrorCodeConflict,
	) {
		t.Fatalf("duplicate CreateWorkflowDefinition() error = %v", err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	restored, err := store.WorkflowDefinition(ctx, created.ID)
	if err != nil {
		t.Fatalf("WorkflowDefinition() returned %v", err)
	}
	if restored.DefinitionDigest != created.DefinitionDigest ||
		restored.DefinitionSchemaVersion != workflowmodel.DefinitionSchemaVersion ||
		restored.EvaluatorVersion != workflowmodel.EvaluatorVersion {
		t.Fatalf("restored workflow definition = %#v", restored)
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(restored.ResolvedDocument, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if definition.Templates["task"].MaxAttempts != 1 || definition.Nodes["alpha"].Budget.MaxAttempts != 1 {
		t.Fatalf("resolved defaults were not persisted: %#v", definition)
	}
}

func TestSchedulerReservesReadyNodesInStableOrder(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxConcurrentNodes = 2
	budgets.MaxConcurrentProcesses = 2
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := OpenWithBudgets(ctx, path, budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	document := independentWorkflowDocument(t, 3, "charlie", "alpha", "bravo")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-order", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-order", "definition-order", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, "run-order", AdapterCapacity{"fixture": 3})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	if len(reserved) != 2 || reserved[0].NodeKey != "alpha" || reserved[1].NodeKey != "bravo" {
		t.Fatalf("reserved nodes = %#v", reserved)
	}
	if reserved[0].Attempt != 1 || reserved[1].Attempt != 1 {
		t.Fatalf("reserved attempts = %d, %d", reserved[0].Attempt, reserved[1].Attempt)
	}
	second, err := store.ReserveReadyNodes(ctx, "run-order", AdapterCapacity{"fixture": 3})
	if err != nil {
		t.Fatalf("second ReserveReadyNodes() returned %v", err)
	}
	if len(second) != 0 {
		t.Fatalf("second reservation = %#v", second)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = OpenWithBudgets(ctx, path, budgets)
	if err != nil {
		t.Fatalf("second OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	run, nodes, err := store.WorkflowRun(ctx, "run-order")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if run.State != domain.WorkflowRunStateRunning || len(nodes) != 3 ||
		nodes[0].State != domain.NodeRunStateRunning || nodes[1].State != domain.NodeRunStateRunning ||
		nodes[2].State != domain.NodeRunStateReady {
		t.Fatalf("persisted schedule = %#v, %#v", run, nodes)
	}
}

func TestSchedulerReservesAdapterCapacity(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	document := independentWorkflowDocument(t, 3, "charlie", "alpha", "bravo")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-adapter", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-adapter", "definition-adapter", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, "run-adapter", AdapterCapacity{"fixture": 1})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	if len(reserved) != 1 || reserved[0].NodeKey != "alpha" {
		t.Fatalf("reserved nodes = %#v", reserved)
	}
}

func TestSchedulerReservesWorkflowCapacity(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	document := independentWorkflowDocument(t, 1, "bravo", "alpha")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-workflow", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-workflow", "definition-workflow", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, "run-workflow", AdapterCapacity{"fixture": 2})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	if len(reserved) != 1 || reserved[0].NodeKey != "alpha" {
		t.Fatalf("reserved nodes = %#v", reserved)
	}
}

func TestSchedulerReservesCapacityAtomically(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	budgets := domain.DefaultBudgets()
	budgets.MaxConcurrentNodes = 2
	budgets.MaxConcurrentProcesses = 2
	store, err := OpenWithBudgets(ctx, filepath.Join(t.TempDir(), "colchis.db"), budgets)
	if err != nil {
		t.Fatalf("OpenWithBudgets() returned %v", err)
	}
	defer store.Close()
	document := independentWorkflowDocument(t, 3, "charlie", "alpha", "bravo")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-atomic", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-atomic", "definition-atomic", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}

	start := make(chan struct{})
	results := make(chan []domain.NodeRun, 2)
	errors := make(chan error, 2)
	var wait sync.WaitGroup
	for range 2 {
		wait.Add(1)
		go func() {
			defer wait.Done()
			<-start
			reserved, reserveErr := store.ReserveReadyNodes(ctx, "run-atomic", AdapterCapacity{"fixture": 3})
			results <- reserved
			errors <- reserveErr
		}()
	}
	close(start)
	wait.Wait()
	close(results)
	close(errors)
	for reserveErr := range errors {
		if reserveErr != nil {
			t.Fatalf("ReserveReadyNodes() returned %v", reserveErr)
		}
	}
	total := 0
	for reserved := range results {
		total += len(reserved)
	}
	if total != 2 {
		t.Fatalf("atomic reservation count = %d", total)
	}
}

func TestSchedulerRecoversUnboundReservationsAfterRestart(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	path := filepath.Join(t.TempDir(), "colchis.db")
	store, err := Open(ctx, path)
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	document := independentWorkflowDocument(t, 1, "alpha")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-recovery", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-recovery", "definition-recovery", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, "run-recovery", AdapterCapacity{"fixture": 1})
	if err != nil || len(reserved) != 1 || reserved[0].Attempt != 1 {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	if err := store.Close(); err != nil {
		t.Fatalf("Close() returned %v", err)
	}

	store, err = Open(ctx, path)
	if err != nil {
		t.Fatalf("second Open() returned %v", err)
	}
	defer store.Close()
	recovered, err := store.RecoverUnboundNodeReservations(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.NodeRunStateReady || recovered[0].Attempt != 0 {
		t.Fatalf("RecoverUnboundNodeReservations() = %#v, %v", recovered, err)
	}
	reserved, err = store.ReserveReadyNodes(ctx, "run-recovery", AdapterCapacity{"fixture": 1})
	if err != nil || len(reserved) != 1 || reserved[0].Attempt != 1 {
		t.Fatalf("recovered ReserveReadyNodes() = %#v, %v", reserved, err)
	}
}

func resolveWorkflowForStoreTest(
	t *testing.T,
	document json.RawMessage,
) workflowmodel.ResolvedDefinition {
	t.Helper()
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, workflowmodel.CapabilityMap{
		"fixture": {"structured-result"},
	})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	return resolved
}

func independentWorkflowDocument(t *testing.T, workflowLimit uint32, nodeKeys ...string) json.RawMessage {
	t.Helper()
	type testCapabilities struct {
		Required []string `json:"required"`
	}
	type testTemplate struct {
		Kind               string           `json:"kind"`
		InputSchema        json.RawMessage  `json:"inputSchema"`
		InputSchemaDigest  string           `json:"inputSchemaDigest"`
		OutputSchema       json.RawMessage  `json:"outputSchema"`
		OutputSchemaDigest string           `json:"outputSchemaDigest"`
		Capabilities       testCapabilities `json:"capabilities"`
	}
	nodes := make(map[string]struct {
		Template string `json:"template"`
		Adapter  string `json:"adapter"`
	}, len(nodeKeys))
	for _, key := range nodeKeys {
		nodes[key] = struct {
			Template string `json:"template"`
			Adapter  string `json:"adapter"`
		}{Template: "task", Adapter: "fixture"}
	}
	digest := "sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88"
	document := struct {
		SchemaVersion    string                          `json:"schemaVersion"`
		EvaluatorVersion string                          `json:"evaluatorVersion"`
		Name             string                          `json:"name"`
		Budgets          workflowmodel.DefinitionBudgets `json:"budgets"`
		Templates        map[string]testTemplate         `json:"templates"`
		Nodes            map[string]struct {
			Template string `json:"template"`
			Adapter  string `json:"adapter"`
		} `json:"nodes"`
		Edges []workflowmodel.Edge `json:"edges"`
	}{
		SchemaVersion:    workflowmodel.DefinitionSchemaVersion,
		EvaluatorVersion: workflowmodel.EvaluatorVersion,
		Name:             fmt.Sprintf("independent-%d", len(nodeKeys)),
		Budgets: workflowmodel.DefinitionBudgets{
			MaxConcurrentNodes: workflowLimit, MaxConcurrentProcesses: workflowLimit,
			MaxMaterializedSnapshots: 1, MaxSnapshotBytes: 1024, MaxVerificationSeconds: 10,
		},
		Templates: map[string]testTemplate{
			"task": {
				Kind:               "task",
				InputSchema:        json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema"}`),
				InputSchemaDigest:  digest,
				OutputSchema:       json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema"}`),
				OutputSchemaDigest: digest,
				Capabilities:       testCapabilities{Required: []string{"structured-result"}},
			},
		},
		Nodes: nodes,
		Edges: []workflowmodel.Edge{},
	}
	encoded, err := json.Marshal(document)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	return encoded
}
