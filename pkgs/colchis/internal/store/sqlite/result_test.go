package sqlite

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const graphTestSchemaDigest = "sha256:ccb5a9d66e068ea8f4e205788589675a48e9e3754a840d8ac10120d14238e914"

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
		ID: "result-1", NodeRunID: reserved[0].ID, SchemaDigest: graphTestSchemaDigest,
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
		ID: "result-invalid", NodeRunID: reserved[0].ID, SchemaDigest: graphTestSchemaDigest,
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
	_, nodes, err := store.WorkflowRun(ctx, "run-repair")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	implement := nodeByKey(t, nodes, "implement")
	if implement.State != domain.NodeRunStateFailed || implement.RepairAttempt != 2 || implement.TaskResultID != nil {
		t.Fatalf("failed node = %#v", implement)
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
		ID: "result-digest", NodeRunID: reserved[0].ID,
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

func TestReplayReusesOnlyCurrentAdmission(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, admission, snapshot, _ := openAdmittedResultTest(t, ctx)
	defer store.Close()
	parent, _, err := store.WorkflowRun(ctx, "run-admission")
	if err != nil {
		t.Fatalf("WorkflowRun() returned %v", err)
	}
	point, err := store.CreateRestartPoint(ctx, RestartPointRequest{
		ID: "restart-current-admission", Kind: domain.RestartPointNodeAdmission,
		WorkflowRunID: parent.ID, EventCursor: graphTestRunCursor(t, ctx, store, parent.ID),
		SnapshotID: snapshot.ID, NodeRunID: nodeIDPointer(nodeRunID(parent.ID, "implement")),
		AdmissionIDs: []domain.AdmissionID{admission.ID},
	})
	if err != nil {
		t.Fatalf("CreateRestartPoint() returned %v", err)
	}
	child, _, err := store.ReplayWorkflow(ctx, ReplayRequest{
		ID: "fork-current-admission", ParentWorkflowRunID: parent.ID,
		ChildWorkflowRunID: "run-admission-child", RestartPointID: point.ID,
		TargetDefinitionID: parent.WorkflowDefinition, TargetDefinitionVersion: parent.DefinitionVersion,
		ExpectedParentVersion: parent.Metadata.ResourceVersion,
		ReusedAdmissionIDs:    []domain.AdmissionID{admission.ID},
		CommandID:             "command-current-admission", Principal: "owner",
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
		*implement.AdmissionID != admission.ID || judge.State != domain.NodeRunStateReady ||
		len(judge.InputSnapshotIDs) != 1 || judge.InputSnapshotIDs[0] != snapshot.ID {
		t.Fatalf("replayed nodes = %#v, %#v", implement, judge)
	}
	if _, current, err := store.RefreshAdmission(ctx, AdmissionFreshnessRequest{
		ID: admission.ID, EnvironmentIDs: map[string]string{"nix": "nix:environment-2"},
	}); err != nil || current {
		t.Fatalf("stale RefreshAdmission() = %v, %v", current, err)
	}
	_, nodes, err = store.WorkflowRun(ctx, child.ID)
	if err != nil {
		t.Fatalf("stale child WorkflowRun() returned %v", err)
	}
	implement = nodeByKey(t, nodes, "implement")
	judge = nodeByKey(t, nodes, "judge")
	if implement.State != domain.NodeRunStateWaiting || judge.State != domain.NodeRunStatePending {
		t.Fatalf("stale replayed nodes = %#v, %#v", implement, judge)
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
		ID: domain.TaskResultID("result-" + suffix), NodeRunID: reserved[0].ID,
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
		ID: "result-admission", NodeRunID: reserved[0].ID, SchemaDigest: graphTestSchemaDigest,
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
