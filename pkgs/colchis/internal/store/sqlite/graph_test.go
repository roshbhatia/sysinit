package sqlite

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestApplyGraphPatchInsertsJudgeAndExportsDefinition(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createGraphTestRun(t, ctx, store, evaluator, "definition-base", "run-patch")
	request := GraphPatchRequest{
		ID: "patch-1", RunID: "run-patch", ResultDefinitionID: "definition-patched",
		ExpectedDefinitionVersion: 1, CommandID: "command-patch",
		Operations: []domain.GraphPatchOperation{graphTestInsertOperation(t)},
	}
	definition, patch, err := store.ApplyGraphPatch(ctx, request, evaluator, graphTestCapabilities())
	if err != nil {
		t.Fatalf("ApplyGraphPatch() returned %v", err)
	}
	if definition.DefinitionVersion != 2 || patch.BaseWorkflowDefinitionID != "definition-base" ||
		patch.ResultWorkflowDefinitionID != definition.ID {
		t.Fatalf("patch result = %#v, %#v", definition, patch)
	}
	run, nodes, err := store.WorkflowRun(ctx, "run-patch")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if run.WorkflowDefinition != definition.ID || run.DefinitionVersion != 2 || len(nodes) != 3 {
		t.Fatalf("patched run = %#v, %#v", run, nodes)
	}
	exported, err := store.ExportWorkflowDefinition(ctx, definition.ID)
	if err != nil {
		t.Fatalf("ExportWorkflowDefinition() returned %v", err)
	}
	var exportedDefinition workflowmodel.Definition
	if err := json.Unmarshal(exported, &exportedDefinition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	if _, found := exportedDefinition.Nodes["critic"]; !found {
		t.Fatalf("exported definition = %#v", exportedDefinition)
	}
	if _, _, err := store.ApplyGraphPatch(ctx, request, evaluator, graphTestCapabilities()); !domain.IsErrorCode(
		err, domain.ErrorCodeConflict,
	) {
		t.Fatalf("stale ApplyGraphPatch() error = %v", err)
	}
}

func TestApplyGraphPatchReportsRestartForStartedWork(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createGraphTestRun(t, ctx, store, evaluator, "definition-started", "run-started")
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "start")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-start", "workspace-start", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	cursor := graphTestRunCursor(t, ctx, store, "run-started")
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-admission", Kind: domain.RestartPointRunAdmission,
		WorkflowRunID: "run-started", EventCursor: cursor, SnapshotID: "snapshot-start",
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	if _, err := store.ReserveReadyNodes(ctx, "run-started", AdapterCapacity{"pi": 1}); err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	target := domain.NodeKey("implement")
	templateKey := domain.StageTemplateKey("implement")
	value, err := json.Marshal(workflowmodel.StageOperationValue{
		Adapter: "pi", InputPort: "input", OutputPort: "result",
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	_, _, err = store.ApplyGraphPatch(ctx, GraphPatchRequest{
		ID: "patch-started", RunID: "run-started", ResultDefinitionID: "definition-replaced",
		ExpectedDefinitionVersion: 1, CommandID: "command-started",
		Operations: []domain.GraphPatchOperation{{
			Kind: domain.GraphPatchOperationReplace, TargetNodeKey: &target,
			StageTemplateKey: &templateKey, Value: value,
		}},
	}, evaluator, graphTestCapabilities())
	var conflict *domain.Error
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) || !strings.Contains(err.Error(), string(point.ID)) ||
		!errors.As(err, &conflict) || conflict.Details["earliestRestartPointId"] != string(point.ID) {
		t.Fatalf("ApplyGraphPatch() error = %v", err)
	}
	if _, err := store.WorkflowDefinition(ctx, "definition-replaced"); !domain.IsErrorCode(
		err, domain.ErrorCodeNotFound,
	) {
		t.Fatalf("partial workflow definition error = %v", err)
	}
}

func TestApplyGraphPatchSchedulesInsertedStageFromCurrentAdmission(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	if _, _, err := store.ApplyGraphPatch(ctx, GraphPatchRequest{
		ID: "patch-admitted", RunID: "run-admission", ResultDefinitionID: "definition-admitted-patched",
		ExpectedDefinitionVersion: 1, CommandID: "command-admitted-patch",
		Operations: []domain.GraphPatchOperation{graphTestInsertOperation(t)},
	}, evaluator, graphTestCapabilities()); err != nil {
		t.Fatalf("ApplyGraphPatch() returned %v", err)
	}
	_, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if critic := nodeByKey(t, nodes, "critic"); critic.State != domain.NodeRunStateReady {
		t.Fatalf("inserted critic node = %#v", critic)
	}
	if judge := nodeByKey(t, nodes, "judge"); judge.State != domain.NodeRunStatePending {
		t.Fatalf("downstream judge node = %#v", judge)
	}
}

func TestReplayWorkflowCreatesChildAndPreservesParent(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	parent, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-replay", "run-parent")
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "replay")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-replay", "workspace-replay", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	cursor := graphTestRunCursor(t, ctx, store, parent.ID)
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-replay", Kind: domain.RestartPointRunAdmission,
		WorkflowRunID: parent.ID, EventCursor: cursor, SnapshotID: "snapshot-replay",
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-1", ParentWorkflowRunID: parent.ID, ChildWorkflowRunID: "run-child",
		RestartPointID: point.ID, TargetDefinitionID: parent.WorkflowDefinition,
		TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion:   parent.Metadata.ResourceVersion,
		CommandID:               "command-replay", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	if child.ID != "run-child" || fork.ParentWorkflowRunID != parent.ID ||
		fork.StartingSnapshotID != point.SnapshotID || fork.TargetDefinitionVersion != 1 {
		t.Fatalf("replay result = %#v, %#v", child, fork)
	}
	restoredParent, _, err := store.WorkflowRun(ctx, parent.ID)
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if restoredParent.Metadata.ResourceVersion != parent.Metadata.ResourceVersion ||
		restoredParent.State != parent.State {
		t.Fatalf("parent changed = %#v", restoredParent)
	}
	if _, nodes, err := store.WorkflowRun(ctx, child.ID); err != nil || len(nodes) != 2 {
		t.Fatalf("child workflow run = %#v, %v", nodes, err)
	} else if root := nodeByKey(t, nodes, "implement"); len(root.InputSnapshotIDs) != 1 ||
		root.InputSnapshotIDs[0] != point.SnapshotID {
		t.Fatalf("child root inputs = %#v", root.InputSnapshotIDs)
	}
}

func TestReplayWorkflowRejectsUnrelatedDefinition(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	parent, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-parent", "run-parent-lineage")
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	predecessor := parent.WorkflowDefinition
	unrelated, err := store.CreateWorkflowDefinition(
		ctx, "definition-unrelated", &predecessor, document, resolved,
	)
	if err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "lineage")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-lineage", "workspace-lineage", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-lineage", Kind: domain.RestartPointRunAdmission,
		WorkflowRunID: parent.ID, EventCursor: graphTestRunCursor(t, ctx, store, parent.ID),
		SnapshotID: "snapshot-lineage",
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	_, _, err = store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-unrelated", ParentWorkflowRunID: parent.ID, ChildWorkflowRunID: "run-unrelated-child",
		RestartPointID: point.ID, TargetDefinitionID: unrelated.ID,
		TargetDefinitionVersion: unrelated.DefinitionVersion,
		ExpectedParentVersion:   parent.Metadata.ResourceVersion,
		CommandID:               "command-unrelated", Principal: "owner",
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) || !strings.Contains(err.Error(), "lineage") {
		t.Fatalf("ReplayWorkflow() error = %v", err)
	}
}

func TestOrchestrationRestartPointRequiresOwnedCheckpoint(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	parent, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-checkpoint", "run-checkpoint")
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "checkpoint")
	if _, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-checkpoint", "workspace-checkpoint", workspace); err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	_, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-missing-checkpoint", Kind: domain.RestartPointOrchestrationCheckpoint,
		WorkflowRunID: parent.ID, EventCursor: graphTestRunCursor(t, ctx, store, parent.ID),
		SnapshotID: "snapshot-checkpoint", CheckpointIDs: []domain.CheckpointID{"checkpoint-missing"},
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeNotFound) {
		t.Fatalf("CreateRestartPoint() error = %v", err)
	}
}

func openGraphTestStore(t *testing.T, ctx context.Context) (*Store, *workflowmodel.Evaluator) {
	t.Helper()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		store.Close()
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	return store, evaluator
}

func createGraphTestRun(
	t *testing.T,
	ctx context.Context,
	store *Store,
	evaluator *workflowmodel.Evaluator,
	definitionID domain.WorkflowDefinitionID,
	runID domain.WorkflowRunID,
) (domain.WorkflowRun, []domain.NodeRun) {
	t.Helper()
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, definitionID, nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	run, nodes, err := store.CreateWorkflowRun(ctx, runID, definitionID, nil)
	if err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	return run, nodes
}

func graphTestCapabilities() workflowmodel.CapabilityMap {
	return workflowmodel.CapabilityMap{
		"pi": {"structured-result", "live-input"},
	}
}

func graphTestInsertOperation(t *testing.T) domain.GraphPatchOperation {
	t.Helper()
	target := domain.EdgeKey("implement-to-judge")
	instance := domain.NodeKey("critic")
	templateKey := domain.StageTemplateKey("critic-template")
	digest := "sha256:ccb5a9d66e068ea8f4e205788589675a48e9e3754a840d8ac10120d14238e914"
	value, err := json.Marshal(workflowmodel.StageOperationValue{
		Adapter: "pi", InputPort: "candidate", OutputPort: "verdict",
		Template: workflowmodel.Template{
			Kind:               "judge",
			InputSchema:        json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object"}`),
			InputSchemaDigest:  digest,
			OutputSchema:       json.RawMessage(`{"$schema":"https://json-schema.org/draft/2020-12/schema","type":"object"}`),
			OutputSchemaDigest: digest,
			Capabilities: workflowmodel.Capabilities{
				Required: []string{"structured-result"}, Optional: []string{},
			},
			Verification: []workflowmodel.Verification{},
			Effects:      workflowmodel.EffectPolicy{Mode: "deny"}, MaxAttempts: 2,
		},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	return domain.GraphPatchOperation{
		Kind:          domain.GraphPatchOperationInsertBetween,
		TargetEdgeKey: &target, InstanceNodeKey: &instance, StageTemplateKey: &templateKey,
		Value: value,
	}
}

func graphTestRunCursor(
	t *testing.T,
	ctx context.Context,
	store *Store,
	runID domain.WorkflowRunID,
) domain.EventCursor {
	t.Helper()
	var cursor domain.EventCursor
	if err := store.db.QueryRowContext(
		ctx,
		"SELECT MAX(cursor) FROM events WHERE aggregate_kind = ? AND aggregate_id = ?",
		workflowRunRecordKind, string(runID),
	).Scan(&cursor); err != nil {
		t.Fatalf("reading run event cursor returned %v", err)
	}
	return cursor
}
