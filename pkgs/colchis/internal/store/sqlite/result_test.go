package sqlite

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"slices"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const graphTestSchemaDigest = "sha256:ccb5a9d66e068ea8f4e205788589675a48e9e3754a840d8ac10120d14238e914"

func TestLegacyTaskResultKeepsItsEvidenceEncoding(t *testing.T) {
	t.Parallel()

	legacy := json.RawMessage(`{"metadata":{"schemaVersion":1,"resourceVersion":1,"createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-01T00:00:00Z"},"id":"result-legacy","nodeRunId":"node-legacy","schemaDigest":"sha256:legacy","value":{},"artifactIds":[]}`)
	var result domain.TaskResult
	if err := json.Unmarshal(legacy, &result); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	encoded, err := json.Marshal(result)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	if string(encoded) != string(legacy) || string(encoded) == "" || jsonContainsKey(encoded, "attempt") {
		t.Fatalf("legacy task result changed from %s to %s", legacy, encoded)
	}
}

func jsonContainsKey(encoded []byte, key string) bool {
	var value map[string]json.RawMessage
	if err := json.Unmarshal(encoded, &value); err != nil {
		return false
	}
	_, found := value[key]
	return found
}

func TestSubmitTaskResultPersistsValidatedValue(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	_, nodes := createGraphTestRun(t, ctx, store, evaluator, "definition-result", "run-result")
	reserved, err := store.ReserveReadyNodes(ctx, "run-result", AdapterCapacity{"pi": 1})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	if len(reserved) != 1 || reserved[0].NodeKey != "implement" {
		t.Fatalf("reserved nodes = %#v", reserved)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-1", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt, SchemaDigest: graphTestSchemaDigest,
		Value: json.RawMessage(`{"status":"complete"}`),
	})
	if err != nil {
		t.Fatalf("SubmitTaskResult() returned %v", err)
	}
	if !submission.Decision.Accepted || submission.Result == nil || submission.Result.ID != "result-1" {
		t.Fatalf("submission = %#v", submission)
	}
	_, restoredNodes, err := store.WorkflowRun(ctx, "run-result")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, restoredNodes, "implement")
	if implement.State != domain.NodeRunStateWaiting || implement.TaskResultID == nil ||
		*implement.TaskResultID != "result-1" {
		t.Fatalf("implement node = %#v", implement)
	}
	if next, err := store.ReserveReadyNodes(ctx, "run-result", AdapterCapacity{"pi": 1}); err != nil || len(next) != 0 {
		t.Fatalf("downstream reservation = %#v, %v", next, err)
	}
	if len(nodes) != 2 {
		t.Fatalf("initial nodes = %#v", nodes)
	}
}

func TestSubmitTaskResultPersistsBoundedRepairState(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createGraphTestRun(t, ctx, store, evaluator, "definition-repair", "run-repair")
	reserved, err := store.ReserveReadyNodes(ctx, "run-repair", AdapterCapacity{"pi": 1})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	request := TaskResultRequest{
		ID: "result-invalid", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt, SchemaDigest: graphTestSchemaDigest,
		Value: json.RawMessage(`"invalid"`),
	}
	for expected := uint32(1); expected <= 2; expected++ {
		submission, err := store.SubmitTaskResult(ctx, request)
		if err != nil {
			t.Fatalf("SubmitTaskResult() attempt %d returned %v", expected, err)
		}
		if !submission.Decision.RepairAllowed || submission.Decision.RepairsUsed != expected ||
			submission.Result != nil {
			t.Fatalf("repair submission %d = %#v", expected, submission)
		}
	}
	exhausted, err := store.SubmitTaskResult(ctx, request)
	if err != nil {
		t.Fatalf("exhausted SubmitTaskResult() returned %v", err)
	}
	if !exhausted.Decision.Exhausted || exhausted.Result != nil {
		t.Fatalf("exhausted submission = %#v", exhausted)
	}
	run, nodes, err := store.WorkflowRun(ctx, "run-repair")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, nodes, "implement")
	if implement.State != domain.NodeRunStateFailed || implement.RepairAttempt != 2 || implement.TaskResultID != nil {
		t.Fatalf("failed node = %#v", implement)
	}
	if run.State != domain.WorkflowRunStateFailed || run.ActivePauseID == nil {
		t.Fatalf("failed run = %#v", run)
	}
	retriedRun, retriedNode, retry, err := store.RetryWorkflowNode(ctx, WorkflowRetryRequest{
		ID: "retry-repair", RunID: run.ID, NodeRunID: implement.ID,
		ExpectedVersion: run.Metadata.ResourceVersion, Source: "owner",
	})
	if err != nil {
		t.Fatalf("RetryWorkflowNode() returned %v", err)
	}
	if retriedRun.State != domain.WorkflowRunStateRunning || retriedRun.ActivePauseID != nil ||
		retriedNode.State != domain.NodeRunStateReady || retriedNode.RepairAttempt != 0 ||
		retry.Kind != domain.InterventionKindRetry {
		t.Fatalf("retry result = %#v, %#v, %#v", retriedRun, retriedNode, retry)
	}
	reserved, err = store.ReserveReadyNodes(ctx, run.ID, AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 || reserved[0].Attempt != 2 {
		t.Fatalf("retry reservation = %#v, %v", reserved, err)
	}
	_, err = store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-stale-attempt", NodeRunID: reserved[0].ID, Attempt: 1,
		SchemaDigest: graphTestSchemaDigest, Value: json.RawMessage(`{"status":"complete"}`),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("stale SubmitTaskResult() error = %v", err)
	}
	_, err = store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-missing-attempt", NodeRunID: reserved[0].ID,
		SchemaDigest: graphTestSchemaDigest, Value: json.RawMessage(`{"status":"complete"}`),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("missing-attempt SubmitTaskResult() error = %v", err)
	}
	var count uint32
	if err := store.db.QueryRowContext(
		ctx, "SELECT COUNT(*) FROM records WHERE kind = ?", taskResultRecordKind,
	).Scan(&count); err != nil {
		t.Fatalf("counting task results returned %v", err)
	}
	if count != 0 {
		t.Fatalf("task result count = %d", count)
	}
}

func TestSubmitTaskResultRejectsUnpinnedSchemaDigest(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createGraphTestRun(t, ctx, store, evaluator, "definition-digest", "run-digest")
	reserved, err := store.ReserveReadyNodes(ctx, "run-digest", AdapterCapacity{"pi": 1})
	if err != nil {
		t.Fatalf("ReserveReadyNodes() returned %v", err)
	}
	_, err = store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-digest", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt,
		SchemaDigest: "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
		Value:        json.RawMessage(`{}`),
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeInvalidArgument) {
		t.Fatalf("SubmitTaskResult() error = %v", err)
	}
}

func TestAdmissionAdvancesDependentWithImmutableSnapshot(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, snapshot, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	refreshed, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-1"},
	})
	if err != nil || !current || refreshed.State != domain.AdmissionStateAdmitted {
		t.Fatalf("RefreshAdmission() = %#v, %v, %v", refreshed, current, err)
	}
	_, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, nodes, "implement")
	judge := nodeByKey(t, nodes, "judge")
	if implement.State != domain.NodeRunStateSucceeded || implement.AdmissionID == nil ||
		judge.State != domain.NodeRunStateReady || len(judge.InputSnapshotIDs) != 1 ||
		judge.InputSnapshotIDs[0] != snapshot.ID {
		t.Fatalf("admitted nodes = %#v, %#v", implement, judge)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "unchecked")
	materialized, err := store.MaterializeWorkspaceSnapshot(ctx, snapshot.ID)
	if err != nil {
		t.Fatalf("MaterializeWorkspaceSnapshot() returned %v", err)
	}
	defer materialized.Close()
	content, err := os.ReadFile(filepath.Join(materialized.Path, "input.txt"))
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	if string(content) != "admitted" {
		t.Fatalf("materialized input = %q", content)
	}
}

func TestAdmissionEnvironmentChangeMarksEvidenceStale(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	refreshed, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	})
	if err != nil || current || refreshed.State != domain.AdmissionStateStale {
		t.Fatalf("RefreshAdmission() = %#v, %v, %v", refreshed, current, err)
	}
	_, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, nodes, "implement")
	judge := nodeByKey(t, nodes, "judge")
	if implement.State != domain.NodeRunStateWaiting || judge.State != domain.NodeRunStatePending ||
		len(judge.InputSnapshotIDs) != 0 {
		t.Fatalf("stale nodes = %#v, %#v", implement, judge)
	}
}

func TestAdmissionKeepsAdvisoryVerificationPending(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, task, validation, _, _ := openResultEvidenceTest(t, ctx, domain.AuthorityAdvisory)
	defer store.Close()
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: "admission-advisory", TaskRecordID: task.ID,
		ValidationIDs: []domain.ValidationID{validation.ID},
	})
	if err != nil || admission.State != domain.AdmissionStatePending {
		t.Fatalf("DecideAdmission() = %#v, %v", admission, err)
	}
	_, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if implement := nodeByKey(t, nodes, "implement"); implement.State != domain.NodeRunStateWaiting {
		t.Fatalf("advisory implement node = %#v", implement)
	}
	if judge := nodeByKey(t, nodes, "judge"); judge.State != domain.NodeRunStatePending {
		t.Fatalf("advisory judge node = %#v", judge)
	}
}

func TestReplayReusesCompatibleAdmissionBeforeRestartCursor(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, snapshot, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-restart-admission", snapshot.WorkspaceID, workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, _, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-current-admission", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID:    nodeIDPointer(nodeRunID(parent.ID, "implement")),
		AdmissionIDs: []domain.AdmissionID{admission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-rerun", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-admission-child", RestartPointID: point.ID,
		TargetDefinitionID: parent.WorkflowDefinition, TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		CommandID:             "command-rerun", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	_, nodes, err := store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("child WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, nodes, "implement")
	judge := nodeByKey(t, nodes, "judge")
	if implement.State != domain.NodeRunStateSucceeded || implement.AdmissionID == nil ||
		*implement.AdmissionID != admission.ID || len(implement.InputSnapshotIDs) != 0 ||
		judge.State != domain.NodeRunStateReady || len(judge.InputSnapshotIDs) != 1 ||
		judge.InputSnapshotIDs[0] != snapshot.ID || len(fork.AdmissionReuseIDs) != 1 {
		t.Fatalf("replayed nodes = %#v, %#v", implement, judge)
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		now := child.Metadata.UpdatedAt.Add(1)
		if err := transaction.transitionNodeRun(ctx, &judge, domain.NodeRunStateSucceeded, now); err != nil {
			return err
		}
		return transaction.completeWorkflowRun(ctx, child.ID, now)
	})
	if err != nil {
		t.Fatalf("complete child workflow returned %v", err)
	}
	refreshed, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	})
	if err != nil || current || refreshed.State != domain.AdmissionStateStale {
		t.Fatalf("RefreshAdmission() = %#v, %v, %v", refreshed, current, err)
	}
	child, nodes, err = store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(stale child) returned %v", err)
	}
	implement = nodeByKey(t, nodes, "implement")
	if child.State != domain.WorkflowRunStatePending || implement.State != domain.NodeRunStateReady ||
		implement.AdmissionID != nil || implement.TaskResultID != nil || implement.SessionID != nil ||
		len(implement.InputSnapshotIDs) != 1 || implement.InputSnapshotIDs[0] != point.SnapshotID {
		t.Fatalf("invalidated reused child = %#v, %#v", child, implement)
	}
}

func TestReplayCompletesWhenEveryAdmissionIsReused(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	document := independentWorkflowDocument(t, 1, "alpha")
	resolved, err := evaluator.Resolve(document, workflowmodel.CapabilityMap{"fixture": {"structured-result"}})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-full-reuse", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	parent, _, err := store.CreateWorkflowRun(ctx, "run-full-reuse", "definition-full-reuse", nil)
	if err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, parent.ID, AdapterCapacity{"fixture": 1})
	if err != nil || len(reserved) != 1 {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "admitted")
	snapshot, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-full-reuse", "workspace-full-reuse", workspace)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-full-reuse", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt,
		SchemaDigest: "sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88",
		Value:        json.RawMessage(`{}`),
	})
	if err != nil || submission.Result == nil {
		t.Fatalf("SubmitTaskResult() = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: "task-full-reuse", TaskResultID: submission.Result.ID, SnapshotID: snapshot.ID,
	})
	if err != nil {
		t.Fatalf("CreateTaskRecord() returned %v", err)
	}
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: "admission-full-reuse", TaskRecordID: task.ID,
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("DecideAdmission() = %#v, %v", admission, err)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-full-reuse-restart", snapshot.WorkspaceID, workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, _, err = store.WorkflowRun(ctx, parent.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(parent) returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-full-reuse", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID: nodeIDPointer(reserved[0].ID), AdmissionIDs: []domain.AdmissionID{admission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-full-reuse", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-full-reuse-child", RestartPointID: point.ID,
		TargetDefinitionID: parent.WorkflowDefinition, TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		CommandID:             "command-full-reuse", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	if child.State != domain.WorkflowRunStateSucceeded || len(fork.AdmissionReuseIDs) != 1 {
		t.Fatalf("fully reused branch = %#v, %#v", child, fork)
	}
}

func TestReplayRequiresReusablePredecessors(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _, _, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	judgeAdmission, _ := completeJudgeAdmissionTest(t, ctx, store, workspace, "closure")
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart closure")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-restart-closure", "workspace-admission", workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun(parent) returned %v", err)
	}
	judge := nodeByKey(t, nodes, "judge")
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-closure", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID: nodeIDPointer(judge.ID), AdmissionIDs: []domain.AdmissionID{judgeAdmission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-closure", ParentWorkflowRunID: parent.ID, ChildWorkflowRunID: "run-closure-child",
		RestartPointID: point.ID, TargetDefinitionID: parent.WorkflowDefinition,
		TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion:   parent.Metadata.ResourceVersion,
		CommandID:               "command-closure", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	_, nodes, err = store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(child) returned %v", err)
	}
	if len(fork.AdmissionReuseIDs) != 0 || nodeByKey(t, nodes, "implement").State != domain.NodeRunStateReady ||
		nodeByKey(t, nodes, "judge").State != domain.NodeRunStatePending {
		t.Fatalf("non-closed reuse = %#v, %#v", fork, nodes)
	}
}

func TestStaleAdmissionInvalidatesReusedDownstreamClosure(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, implementAdmission, _, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	judgeAdmission, _ := completeJudgeAdmissionTest(t, ctx, store, workspace, "invalidate")
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart invalidate")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-restart-invalidate", "workspace-admission", workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun(parent) returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-invalidate", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID:    nodeIDPointer(nodeByKey(t, nodes, "judge").ID),
		AdmissionIDs: []domain.AdmissionID{implementAdmission.ID, judgeAdmission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-invalidate", ParentWorkflowRunID: parent.ID, ChildWorkflowRunID: "run-invalidate-child",
		RestartPointID: point.ID, TargetDefinitionID: parent.WorkflowDefinition,
		TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion:   parent.Metadata.ResourceVersion,
		CommandID:               "command-invalidate", Principal: "owner",
	})
	if err != nil || child.State != domain.WorkflowRunStateSucceeded || len(fork.AdmissionReuseIDs) != 2 {
		t.Fatalf("ReplayWorkflow() = %#v, %#v, %v", child, fork, err)
	}
	refreshed, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: implementAdmission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	})
	if err != nil || current || refreshed.State != domain.AdmissionStateStale {
		t.Fatalf("RefreshAdmission() = %#v, %t, %v", refreshed, current, err)
	}
	for _, runID := range []domain.WorkflowRunID{parent.ID, child.ID} {
		run, runNodes, err := store.WorkflowRun(ctx, runID)
		if err != nil {
			t.Fatalf("WorkflowRun(%s) returned %v", runID, err)
		}
		implement := nodeByKey(t, runNodes, "implement")
		judge := nodeByKey(t, runNodes, "judge")
		if run.State != domain.WorkflowRunStatePending || judge.State != domain.NodeRunStatePending ||
			judge.AdmissionID != nil || judge.TaskResultID != nil || judge.SessionID != nil {
			t.Fatalf("invalidated run %s = %#v, %#v", runID, run, runNodes)
		}
		if runID == parent.ID && implement.State != domain.NodeRunStateWaiting {
			t.Fatalf("parent source node = %#v", implement)
		}
		if runID == child.ID && (implement.State != domain.NodeRunStateReady ||
			len(implement.InputSnapshotIDs) != 1 || implement.InputSnapshotIDs[0] != point.SnapshotID) {
			t.Fatalf("child source node = %#v", implement)
		}
	}
}

func TestStaleAdmissionWaitsForActiveDownstreamCancellation(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	reserved, err := store.ReserveReadyNodes(ctx, "run-admission", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 || reserved[0].NodeKey != "judge" {
		t.Fatalf("ReserveReadyNodes(judge) = %#v, %v", reserved, err)
	}
	session, err := store.CreateSession(ctx, CreateSessionRequest{
		ID: "session-stale-downstream", WorkflowRunID: "run-admission", NodeRunID: reserved[0].ID,
		RuntimePluginID: "plugin-pi", RuntimeAdapterID: "pi",
		Capabilities: []string{"structured-result", "live-input", "job-policy"},
	})
	if err != nil {
		t.Fatalf("CreateSession() returned %v", err)
	}
	consumers, err := store.AdmissionConsumerSessions(ctx, admission.ID)
	if err != nil || len(consumers) != 1 || consumers[0].ID != session.ID {
		t.Fatalf("AdmissionConsumerSessions() = %#v, %v", consumers, err)
	}
	if _, _, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	}); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("active RefreshAdmission() error = %v", err)
	}
	history, err := store.SessionHistory(ctx, session.ID)
	if err != nil || history.Session.State != domain.SessionStateStarting {
		t.Fatalf("SessionHistory() = %#v, %v", history, err)
	}
	run, nodes, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	judge := nodeByKey(t, nodes, "judge")
	if run.State != domain.WorkflowRunStateRunning || judge.State != domain.NodeRunStateRunning ||
		judge.SessionID == nil || *judge.SessionID != session.ID {
		t.Fatalf("preserved active run = %#v, %#v", run, judge)
	}
	session, err = store.TransitionSession(ctx, SessionTransitionRequest{
		SessionID: history.Session.ID, ExpectedVersion: history.Session.Metadata.ResourceVersion,
		State: domain.SessionStateCancelled,
	})
	if err != nil {
		t.Fatalf("TransitionSession(cancelled) returned %v", err)
	}
	if _, _, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	}); err != nil {
		t.Fatalf("cancelled RefreshAdmission() returned %v", err)
	}
	run, nodes, err = store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun(invalidated) returned %v", err)
	}
	judge = nodeByKey(t, nodes, "judge")
	if run.State != domain.WorkflowRunStatePending || judge.State != domain.NodeRunStatePending || judge.SessionID != nil {
		t.Fatalf("invalidated cancelled run = %#v, %#v", run, judge)
	}
}

func TestAdmissionRefreshCommandRecoveryRetriesOrCompletes(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	payload, err := json.Marshal(AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	before := domain.CommandRequest{
		ID: "command-refresh-before", IdempotencyKey: "refresh-before",
		Kind: "verification.refresh", Payload: payload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", before); err != nil || !created {
		t.Fatalf("AcceptCommand(before) = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, before.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand(before) = %t, %v", claimed, err)
	}
	recovered, err := store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateAccepted {
		t.Fatalf("RecoverRunningCommands(before) = %#v, %v", recovered, err)
	}
	after := domain.CommandRequest{
		ID: "command-refresh-after", IdempotencyKey: "refresh-after",
		Kind: "verification.refresh", Payload: payload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", after); err != nil || !created {
		t.Fatalf("AcceptCommand(after) = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, after.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand(after) = %t, %v", claimed, err)
	}
	if _, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	}); err != nil || current {
		t.Fatalf("RefreshAdmission() current = %t, error = %v", current, err)
	}
	recovered, err = store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateSucceeded {
		t.Fatalf("RecoverRunningCommands(after) = %#v, %v", recovered, err)
	}
	var result struct {
		Admission domain.Admission `json:"admission"`
		Current   bool             `json:"current"`
	}
	if err := json.Unmarshal(recovered[0].Result, &result); err != nil ||
		result.Admission.ID != admission.ID || result.Admission.State != domain.AdmissionStateStale || result.Current {
		t.Fatalf("recovered refresh result = %#v, %v", result, err)
	}
}

func TestAdmissionRefreshCommandRecoveryRetriesMalformedPayload(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	request := domain.CommandRequest{
		ID: "command-refresh-malformed", IdempotencyKey: "refresh-malformed",
		Kind: "verification.refresh", Payload: json.RawMessage(`{"id":1}`),
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", request); err != nil || !created {
		t.Fatalf("AcceptCommand() = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, request.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand() = %t, %v", claimed, err)
	}
	recovered, err := store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateAccepted {
		t.Fatalf("RecoverRunningCommands() = %#v, %v", recovered, err)
	}
}

func TestAdmissionRefreshCommandRecoveryRetriesIncompleteStaleRequest(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, _, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	if _, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	}); err != nil || current {
		t.Fatalf("RefreshAdmission() current = %t, error = %v", current, err)
	}
	payload, err := json.Marshal(AdmissionFreshnessRequest{ID: admission.ID})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	request := domain.CommandRequest{
		ID: "command-refresh-incomplete", IdempotencyKey: "refresh-incomplete",
		Kind: "verification.refresh", Payload: payload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", request); err != nil || !created {
		t.Fatalf("AcceptCommand() = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, request.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand() = %t, %v", claimed, err)
	}
	recovered, err := store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateAccepted {
		t.Fatalf("RecoverRunningCommands() = %#v, %v", recovered, err)
	}
}

func TestAdmissionInvalidationPreservesIndependentRunningBranch(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	document := independentWorkflowDocument(t, 2, "alpha", "beta")
	resolved, err := evaluator.Resolve(document, workflowmodel.CapabilityMap{"fixture": {"structured-result"}})
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-independent-invalidation", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(
		ctx, "run-independent-invalidation", "definition-independent-invalidation", nil,
	); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(
		ctx, "run-independent-invalidation", AdapterCapacity{"fixture": 2},
	)
	if err != nil || len(reserved) != 2 {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	alpha := nodeByKey(t, reserved, "alpha")
	beta := nodeByKey(t, reserved, "beta")
	session, err := store.CreateSession(ctx, CreateSessionRequest{
		ID: "session-independent-beta", WorkflowRunID: "run-independent-invalidation", NodeRunID: beta.ID,
		RuntimePluginID: "plugin-fixture", RuntimeAdapterID: "fixture",
		Capabilities: []string{"structured-result", "job-policy"},
	})
	if err != nil {
		t.Fatalf("CreateSession(beta) returned %v", err)
	}
	session, err = store.TransitionSession(ctx, SessionTransitionRequest{
		SessionID: session.ID, ExpectedVersion: session.Metadata.ResourceVersion,
		State: domain.SessionStateWaiting,
	})
	if err != nil {
		t.Fatalf("TransitionSession(beta) returned %v", err)
	}
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "result.txt"), "alpha")
	snapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-independent-invalidation", "workspace-independent-invalidation", workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-independent-invalidation", NodeRunID: alpha.ID, Attempt: alpha.Attempt,
		SchemaDigest: "sha256:042593f8c06f3af13910448e80b07865b66db137c16a125291699564732eac88",
		Value:        json.RawMessage(`{}`),
	})
	if err != nil || submission.Result == nil {
		t.Fatalf("SubmitTaskResult() = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: "task-independent-invalidation", TaskResultID: submission.Result.ID, SnapshotID: snapshot.ID,
	})
	if err != nil {
		t.Fatalf("CreateTaskRecord() returned %v", err)
	}
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: "admission-independent-invalidation", TaskRecordID: task.ID,
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("DecideAdmission() = %#v, %v", admission, err)
	}
	if err := store.Transaction(ctx, func(transaction *Tx) error {
		return transaction.invalidateAdmissionConsumers(ctx, admission.ID, time.Now().UTC())
	}); err != nil {
		t.Fatalf("invalidateAdmissionConsumers() returned %v", err)
	}
	run, nodes, err := store.WorkflowRun(ctx, "run-independent-invalidation")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if run.State != domain.WorkflowRunStateRunning || nodeByKey(t, nodes, "beta").State != domain.NodeRunStateWaiting ||
		session.State != domain.SessionStateWaiting {
		t.Fatalf("independent branch changed = %#v, %#v", run, nodes)
	}
}

func TestReplayDoesNotReuseAdmissionForPatchedAffectedNode(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, _, snapshot, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	reserved, err := store.ReserveReadyNodes(ctx, "run-admission", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 || reserved[0].NodeKey != "judge" {
		t.Fatalf("ReserveReadyNodes(judge) = %#v, %v", reserved, err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-judge-reuse", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt,
		SchemaDigest: graphTestSchemaDigest, Value: json.RawMessage(`{"approved":true}`),
	})
	if err != nil || submission.Result == nil {
		t.Fatalf("SubmitTaskResult(judge) = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: "task-judge-reuse", TaskResultID: submission.Result.ID, SnapshotID: snapshot.ID,
	})
	if err != nil {
		t.Fatalf("CreateTaskRecord(judge) returned %v", err)
	}
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: "admission-judge-reuse", TaskRecordID: task.ID,
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("DecideAdmission(judge) = %#v, %v", admission, err)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart judge")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-judge-restart", snapshot.WorkspaceID, workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, _, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun(parent) returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-judge-reuse", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID: nodeIDPointer(reserved[0].ID), AdmissionIDs: []domain.AdmissionID{admission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		t.Fatalf("NewEvaluator() returned %v", err)
	}
	target, patch, err := store.ReviseWorkflowDefinition(ctx, WorkflowRevisionRequest{
		ID: "revision-judge-reuse", BaseDefinitionID: parent.WorkflowDefinition,
		ResultDefinitionID: "definition-judge-reuse", ExpectedDefinitionVersion: parent.DefinitionVersion,
		CommandID: "command-judge-reuse", Operations: []domain.GraphPatchOperation{graphTestInsertOperation(t)},
		Source: "owner",
	}, evaluator, graphTestCapabilities())
	if err != nil {
		t.Fatalf("ReviseWorkflowDefinition() returned %v", err)
	}
	if !slices.Contains(patch.AffectedNodeKeys, domain.NodeKey("judge")) {
		t.Fatalf("affected nodes = %#v", patch.AffectedNodeKeys)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-judge-reuse", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-judge-reuse-child", RestartPointID: point.ID,
		TargetDefinitionID: target.ID, TargetDefinitionVersion: target.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		CommandID:             "command-judge-branch", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	_, nodes, err := store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(child) returned %v", err)
	}
	if len(fork.AdmissionReuseIDs) != 0 || nodeByKey(t, nodes, "judge").State == domain.NodeRunStateSucceeded {
		t.Fatalf("affected admission was reused = %#v, %#v", fork, nodeByKey(t, nodes, "judge"))
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		stored, found, err := typedRecord[domain.GraphPatch](
			transaction, ctx, graphPatchRecordKind, string(patch.ID),
		)
		if err != nil || !found {
			return err
		}
		previousVersion := stored.Metadata.ResourceVersion
		stored.AffectedNodeKeys = nil
		stored.Metadata.ResourceVersion++
		stored.Metadata.UpdatedAt = stored.Metadata.UpdatedAt.Add(1)
		encoded, err := json.Marshal(stored)
		if err != nil {
			return err
		}
		return transaction.updateRecord(
			ctx, graphPatchRecordKind, string(stored.ID), previousVersion, stored.Metadata, encoded,
		)
	})
	if err != nil {
		t.Fatalf("clear legacy affected nodes returned %v", err)
	}
	legacyChild, legacyFork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-judge-reuse-legacy", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-judge-reuse-legacy", RestartPointID: point.ID,
		TargetDefinitionID: target.ID, TargetDefinitionVersion: target.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		CommandID:             "command-judge-legacy", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow(legacy patch) returned %v", err)
	}
	_, legacyNodes, err := store.WorkflowRun(ctx, legacyChild.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(legacy child) returned %v", err)
	}
	if len(legacyFork.AdmissionReuseIDs) != 0 ||
		nodeByKey(t, legacyNodes, "judge").State == domain.NodeRunStateSucceeded {
		t.Fatalf("legacy patch reused admission = %#v, %#v", legacyFork, legacyNodes)
	}
}

func TestReplayDoesNotReuseAdmissionAcrossWorkspaces(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, snapshot, workspace := openAdmittedResultTest(t, ctx)
	defer store.Close()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "restart")
	restartSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-workspace-restart", snapshot.WorkspaceID, workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(restart) returned %v", err)
	}
	parent, _, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun(parent) returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-workspace-reuse", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, SnapshotID: restartSnapshot.ID,
		NodeRunID:    nodeIDPointer(nodeRunID(parent.ID, "implement")),
		AdmissionIDs: []domain.AdmissionID{admission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	otherWorkspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(otherWorkspace, "input.txt"), "other")
	otherSnapshot, err := store.CreateWorkspaceSnapshot(
		ctx, "snapshot-other-workspace", "workspace-other", otherWorkspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(other) returned %v", err)
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		stored, found, err := transaction.restartPoint(ctx, point.ID)
		if err != nil || !found {
			return err
		}
		previousVersion := stored.Metadata.ResourceVersion
		stored.SnapshotID = otherSnapshot.ID
		stored.Metadata.ResourceVersion++
		stored.Metadata.UpdatedAt = otherSnapshot.Metadata.CreatedAt
		encoded, err := json.Marshal(stored)
		if err != nil {
			return err
		}
		return transaction.updateRecord(
			ctx, restartPointRecordKind, string(stored.ID), previousVersion, stored.Metadata, encoded,
		)
	})
	if err != nil {
		t.Fatalf("replace restart snapshot returned %v", err)
	}
	child, fork, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-workspace-reuse", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-workspace-reuse-child", RestartPointID: point.ID,
		TargetDefinitionID: parent.WorkflowDefinition, TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		CommandID:             "command-workspace-reuse", Principal: "owner",
	})
	if err != nil {
		t.Fatalf("ReplayWorkflow() returned %v", err)
	}
	_, nodes, err := store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("WorkflowRun(child) returned %v", err)
	}
	if len(fork.AdmissionReuseIDs) != 0 || nodeByKey(t, nodes, "implement").State == domain.NodeRunStateSucceeded {
		t.Fatalf("cross-workspace admission was reused = %#v, %#v", fork, nodeByKey(t, nodes, "implement"))
	}
}

func TestLoopRepeatsAndCapsAtIterationLimit(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createLoopResultTestRun(t, ctx, store, evaluator, 2, 3)

	completeLoopTestNode(t, ctx, store, "implement", `{"status":"first"}`, "implement-1", true)
	completeLoopTestNode(t, ctx, store, "judge", `{"approved":false}`, "judge-1", false)
	_, nodes, err := store.WorkflowRun(ctx, "run-loop")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if implement := nodeByKey(t, nodes, "implement"); implement.State != domain.NodeRunStateReady ||
		len(implement.InputSnapshotIDs) != 1 {
		t.Fatalf("repeated implement node = %#v", implement)
	}
	if judge := nodeByKey(t, nodes, "judge"); judge.State != domain.NodeRunStatePending {
		t.Fatalf("repeated judge node = %#v", judge)
	}

	completeLoopTestNode(t, ctx, store, "implement", `{"status":"second"}`, "implement-2", true)
	completeLoopTestNode(t, ctx, store, "judge", `{"approved":false}`, "judge-2", false)
	run, nodes, err := store.WorkflowRun(ctx, "run-loop")
	if err != nil {
		t.Fatalf("capped WorkflowRun() returned %v", err)
	}
	if run.State != domain.WorkflowRunStateCapped ||
		nodeByKey(t, nodes, "implement").State != domain.NodeRunStateCapped ||
		nodeByKey(t, nodes, "judge").State != domain.NodeRunStateCapped {
		t.Fatalf("capped loop = %#v, %#v", run, nodes)
	}
	if run.ActivePauseID == nil {
		t.Fatalf("capped loop has no active pause: %#v", run)
	}
	var cause domain.PauseCause
	err = store.Transaction(ctx, func(transaction *Tx) error {
		pause, found, err := typedRecord[domain.Intervention](
			transaction, ctx, interventionRecordKind, string(*run.ActivePauseID),
		)
		if err != nil {
			return err
		}
		if !found {
			return fmt.Errorf("active cap pause %s is unavailable", *run.ActivePauseID)
		}
		return json.Unmarshal(pause.Payload, &cause)
	})
	if err != nil {
		t.Fatalf("read cap pause returned %v", err)
	}
	if cause.RecommendedAction != domain.InterventionKindBranch ||
		!slices.Contains(cause.AllowedActions, domain.InterventionKindBranch) ||
		slices.Contains(cause.AllowedActions, domain.InterventionKindRetry) {
		t.Fatalf("cap pause cause = %#v", cause)
	}
}

func TestLoopStopsWhenResultMatches(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	createLoopResultTestRun(t, ctx, store, evaluator, 2, 2)
	completeLoopTestNode(t, ctx, store, "implement", `{"status":"complete"}`, "implement-stop", true)
	completeLoopTestNode(t, ctx, store, "judge", `{"approved":true}`, "judge-stop", false)
	run, nodes, err := store.WorkflowRun(ctx, "run-loop")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	if run.State != domain.WorkflowRunStateSucceeded ||
		nodeByKey(t, nodes, "implement").State != domain.NodeRunStateSucceeded ||
		nodeByKey(t, nodes, "judge").State != domain.NodeRunStateSucceeded {
		t.Fatalf("completed loop = %#v, %#v", run, nodes)
	}
}

func createLoopResultTestRun(
	t *testing.T,
	ctx context.Context,
	store *Store,
	evaluator *workflowmodel.Evaluator,
	iterationLimit uint32,
	stallLimit uint32,
) {
	t.Helper()
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(document, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	definition.Loops[0].Stop = workflowmodel.StopCondition{
		Kind: "result_match", Node: "judge", Path: []string{"approved"}, Equals: json.RawMessage(`true`),
	}
	definition.Loops[0].IterationLimit = iterationLimit
	definition.Loops[0].StallLimit = stallLimit
	document, err = json.Marshal(definition)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-loop", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-loop", "definition-loop", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
}

func completeLoopTestNode(
	t *testing.T,
	ctx context.Context,
	store *Store,
	expectedNode domain.NodeKey,
	value string,
	suffix string,
	validated bool,
) {
	t.Helper()
	reserved, err := store.ReserveReadyNodes(ctx, "run-loop", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 || reserved[0].NodeKey != expectedNode {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "result.txt"), suffix)
	snapshot, err := store.CreateWorkspaceSnapshot(
		ctx, domain.SnapshotID("snapshot-"+suffix), "workspace-loop", workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: domain.TaskResultID("result-" + suffix), NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt,
		SchemaDigest: graphTestSchemaDigest, Value: json.RawMessage(value),
	})
	if err != nil || submission.Result == nil {
		t.Fatalf("SubmitTaskResult() = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: domain.TaskRecordID("task-" + suffix), TaskResultID: submission.Result.ID,
		SnapshotID: snapshot.ID,
	})
	if err != nil {
		t.Fatalf("CreateTaskRecord() returned %v", err)
	}
	var validationIDs []domain.ValidationID
	if validated {
		exitCode := 0
		validation, err := store.RecordValidation(ctx, ValidationRequest{
			ID: domain.ValidationID("validation-" + suffix), TaskRecordID: task.ID,
			Key: "unit-tests", State: domain.ValidationStatePassed,
			Authority: domain.AuthorityRepository, EnvironmentID: "nix:loop", ExitCode: &exitCode,
		})
		if err != nil {
			t.Fatalf("RecordValidation() returned %v", err)
		}
		validationIDs = []domain.ValidationID{validation.ID}
	}
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: domain.AdmissionID("admission-" + suffix), TaskRecordID: task.ID,
		ValidationIDs: validationIDs,
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("DecideAdmission() = %#v, %v", admission, err)
	}
}

func nodeIDPointer(id domain.NodeRunID) *domain.NodeRunID {
	return &id
}

func openAdmittedResultTest(
	t *testing.T,
	ctx context.Context,
) (*Store, domain.Admission, domain.Snapshot, string) {
	t.Helper()
	store, task, validation, snapshot, workspace := openResultEvidenceTest(t, ctx, domain.AuthorityRepository)
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: "admission-1", TaskRecordID: task.ID,
		ValidationIDs: []domain.ValidationID{validation.ID},
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		store.Close()
		t.Fatalf("DecideAdmission() = %#v, %v", admission, err)
	}
	return store, admission, snapshot, workspace
}

func completeJudgeAdmissionTest(
	t *testing.T,
	ctx context.Context,
	store *Store,
	workspace string,
	suffix string,
) (domain.Admission, domain.Snapshot) {
	t.Helper()
	reserved, err := store.ReserveReadyNodes(ctx, "run-admission", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 || reserved[0].NodeKey != "judge" {
		t.Fatalf("ReserveReadyNodes(judge) = %#v, %v", reserved, err)
	}
	writeSnapshotTestFile(t, filepath.Join(workspace, "judge.txt"), suffix)
	snapshot, err := store.CreateWorkspaceSnapshot(
		ctx, domain.SnapshotID("snapshot-judge-"+suffix), "workspace-admission", workspace,
	)
	if err != nil {
		t.Fatalf("CreateWorkspaceSnapshot(judge) returned %v", err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: domain.TaskResultID("result-judge-" + suffix), NodeRunID: reserved[0].ID,
		Attempt: reserved[0].Attempt, SchemaDigest: graphTestSchemaDigest,
		Value: json.RawMessage(`{"approved":true}`),
	})
	if err != nil || submission.Result == nil {
		t.Fatalf("SubmitTaskResult(judge) = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: domain.TaskRecordID("task-judge-" + suffix), TaskResultID: submission.Result.ID,
		SnapshotID: snapshot.ID,
	})
	if err != nil {
		t.Fatalf("CreateTaskRecord(judge) returned %v", err)
	}
	admission, err := store.DecideAdmission(ctx, AdmissionRequest{
		ID: domain.AdmissionID("admission-judge-" + suffix), TaskRecordID: task.ID,
	})
	if err != nil || admission.State != domain.AdmissionStateAdmitted {
		t.Fatalf("DecideAdmission(judge) = %#v, %v", admission, err)
	}
	return admission, snapshot
}

func openResultEvidenceTest(
	t *testing.T,
	ctx context.Context,
	authority domain.Authority,
) (*Store, domain.TaskRecord, domain.Validation, domain.Snapshot, string) {
	t.Helper()
	store, evaluator := openGraphTestStore(t, ctx)
	createGraphTestRun(t, ctx, store, evaluator, "definition-admission", "run-admission")
	reserved, err := store.ReserveReadyNodes(ctx, "run-admission", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 {
		store.Close()
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	workspace := t.TempDir()
	writeSnapshotTestFile(t, filepath.Join(workspace, "input.txt"), "admitted")
	snapshot, err := store.CreateWorkspaceSnapshot(ctx, "snapshot-admission", "workspace-admission", workspace)
	if err != nil {
		store.Close()
		t.Fatalf("CreateWorkspaceSnapshot() returned %v", err)
	}
	submission, err := store.SubmitTaskResult(ctx, TaskResultRequest{
		ID: "result-admission", NodeRunID: reserved[0].ID, Attempt: reserved[0].Attempt, SchemaDigest: graphTestSchemaDigest,
		Value: json.RawMessage(`{"status":"complete"}`),
	})
	if err != nil || submission.Result == nil {
		store.Close()
		t.Fatalf("SubmitTaskResult() = %#v, %v", submission, err)
	}
	task, err := store.CreateTaskRecord(ctx, TaskRecordRequest{
		ID: "task-admission", TaskResultID: submission.Result.ID, SnapshotID: snapshot.ID,
	})
	if err != nil {
		store.Close()
		t.Fatalf("CreateTaskRecord() returned %v", err)
	}
	exitCode := 0
	validation, err := store.RecordValidation(ctx, ValidationRequest{
		ID: "validation-admission", TaskRecordID: task.ID, Key: "unit-tests",
		State: domain.ValidationStatePassed, Authority: authority,
		EnvironmentID: "nix:environment-1", ExitCode: &exitCode,
	})
	if err != nil {
		store.Close()
		t.Fatalf("RecordValidation() returned %v", err)
	}
	return store, task, validation, snapshot, workspace
}

func nodeByKey(t *testing.T, nodes []domain.NodeRun, key domain.NodeKey) domain.NodeRun {
	t.Helper()
	for _, node := range nodes {
		if node.NodeKey == key {
			return node
		}
	}
	t.Fatalf("node %q is absent from %#v", key, nodes)
	return domain.NodeRun{}
}
