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

func TestWorkflowPauseAndResumeUseVersionedInterventions(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	run, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-pause", "run-pause")
	cause := domain.PauseCause{
		Kind:     domain.PauseCauseOwnerInput,
		Evidence: []domain.ResourceReference{{Kind: workflowRunRecordKind, ID: string(run.ID)}},
		AllowedActions: []domain.InterventionKind{
			domain.InterventionKindResume, domain.InterventionKindCancel,
		},
		RecommendedAction: domain.InterventionKindResume,
		Message:           "owner decision is required",
	}
	paused, pause, err := store.PauseWorkflow(ctx, WorkflowPauseRequest{
		ID: "pause-owner", RunID: run.ID, ExpectedVersion: run.Metadata.ResourceVersion,
		Cause: cause, Source: "owner",
	})
	if err != nil {
		t.Fatalf("PauseWorkflow() returned %v", err)
	}
	if paused.State != domain.WorkflowRunStateWaiting || paused.ActivePauseID == nil ||
		*paused.ActivePauseID != pause.ID || pause.Target.ID != string(run.ID) {
		t.Fatalf("paused workflow = %#v, %#v", paused, pause)
	}
	resumed, resume, err := store.ResumeWorkflow(ctx, WorkflowResumeRequest{
		ID: "resume-owner", RunID: run.ID, PauseID: pause.ID,
		ExpectedVersion: paused.Metadata.ResourceVersion, Source: "owner",
	})
	if err != nil {
		t.Fatalf("ResumeWorkflow() returned %v", err)
	}
	if resumed.State != domain.WorkflowRunStateRunning || resumed.ActivePauseID != nil ||
		resume.Kind != domain.InterventionKindResume {
		t.Fatalf("resumed workflow = %#v, %#v", resumed, resume)
	}
}

func TestWorkflowLifecycleCommandRecoveryRetriesOrCompletes(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	run, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-lifecycle-recovery", "run-lifecycle-recovery")
	cause := domain.PauseCause{
		Kind: domain.PauseCauseOwnerInput,
		AllowedActions: []domain.InterventionKind{
			domain.InterventionKindResume, domain.InterventionKindCancel,
		},
		RecommendedAction: domain.InterventionKindResume,
	}
	pausePayload, err := json.Marshal(WorkflowPauseRequest{
		ID: "pause-recovery", RunID: run.ID, Cause: cause,
	})
	if err != nil {
		t.Fatalf("Marshal(pause) returned %v", err)
	}
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve() returned %v", err)
	}
	before := domain.CommandRequest{
		ID: "command-pause-before", IdempotencyKey: "pause-before", Kind: "workflow.pause", Payload: json.RawMessage(`{"id":"pause-before","runId":"run-lifecycle-recovery"}`),
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

	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve(after pause) returned %v", err)
	}
	pauseVersion := run.Metadata.ResourceVersion
	pauseCommand := domain.CommandRequest{
		ID: "command-pause-after", IdempotencyKey: "pause-after", Kind: "workflow.pause",
		ExpectedVersion: &pauseVersion, Payload: pausePayload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", pauseCommand); err != nil || !created {
		t.Fatalf("AcceptCommand(pause) = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, pauseCommand.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand(pause) = %t, %v", claimed, err)
	}
	paused, pause, err := store.PauseWorkflow(ctx, WorkflowPauseRequest{
		ID: "pause-recovery", RunID: run.ID, ExpectedVersion: pauseVersion, Cause: cause, Source: "owner",
		CommandID: pauseCommand.ID,
	})
	if err != nil {
		t.Fatalf("PauseWorkflow() returned %v", err)
	}
	recovered, err = store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateSucceeded {
		t.Fatalf("RecoverRunningCommands(pause) = %#v, %v", recovered, err)
	}
	var pauseResult struct {
		Run          domain.WorkflowRun  `json:"run"`
		Intervention domain.Intervention `json:"intervention"`
	}
	if err := json.Unmarshal(recovered[0].Result, &pauseResult); err != nil ||
		pauseResult.Run.ID != run.ID || pauseResult.Intervention.ID != pause.ID {
		t.Fatalf("recovered pause result = %#v, %v", pauseResult, err)
	}

	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve(resume) returned %v", err)
	}
	resumePayload, err := json.Marshal(WorkflowResumeRequest{
		ID: "resume-recovery", RunID: run.ID, PauseID: pause.ID,
	})
	if err != nil {
		t.Fatalf("Marshal(resume) returned %v", err)
	}
	resumeVersion := paused.Metadata.ResourceVersion
	resumeCommand := domain.CommandRequest{
		ID: "command-resume-after", IdempotencyKey: "resume-after", Kind: "workflow.resume",
		ExpectedVersion: &resumeVersion, Payload: resumePayload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", resumeCommand); err != nil || !created {
		t.Fatalf("AcceptCommand(resume) = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, resumeCommand.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand(resume) = %t, %v", claimed, err)
	}
	_, resume, err := store.ResumeWorkflow(ctx, WorkflowResumeRequest{
		ID: "resume-recovery", RunID: run.ID, PauseID: pause.ID,
		ExpectedVersion: resumeVersion, Source: "owner", CommandID: resumeCommand.ID,
	})
	if err != nil {
		t.Fatalf("ResumeWorkflow() returned %v", err)
	}
	recovered, err = store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateSucceeded {
		t.Fatalf("RecoverRunningCommands(resume) = %#v, %v", recovered, err)
	}
	if err := json.Unmarshal(recovered[0].Result, &pauseResult); err != nil || pauseResult.Intervention.ID != resume.ID {
		t.Fatalf("recovered resume result = %#v, %v", pauseResult, err)
	}
}

func TestWorkflowLifecycleRecoveryRejectsInterventionFromAnotherCommand(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	run, _ := createGraphTestRun(t, ctx, store, evaluator, "definition-recovery-collision", "run-recovery-collision")
	cause := domain.PauseCause{
		Kind: domain.PauseCauseOwnerInput, AllowedActions: []domain.InterventionKind{
			domain.InterventionKindResume, domain.InterventionKindCancel,
		}, RecommendedAction: domain.InterventionKindResume,
	}
	payload, err := json.Marshal(WorkflowPauseRequest{ID: "pause-collision", RunID: run.ID, Cause: cause})
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	command := domain.CommandRequest{
		ID: "command-collision", IdempotencyKey: "pause-collision", Kind: "workflow.pause", Payload: payload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", command); err != nil || !created {
		t.Fatalf("AcceptCommand() = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, command.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand() = %t, %v", claimed, err)
	}
	if _, _, err := store.PauseWorkflow(ctx, WorkflowPauseRequest{
		ID: "pause-collision", RunID: run.ID, ExpectedVersion: run.Metadata.ResourceVersion,
		Cause: cause, Source: "owner", CommandID: "command-other",
	}); err != nil {
		t.Fatalf("PauseWorkflow() returned %v", err)
	}
	recovered, err := store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateAccepted {
		t.Fatalf("RecoverRunningCommands() = %#v, %v", recovered, err)
	}
}

func TestWorkflowCompletionClearsActivePause(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	document := independentWorkflowDocument(t, 1, "alpha")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-paused-completion", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	run, nodes, err := store.CreateWorkflowRun(ctx, "run-paused-completion", "definition-paused-completion", nil)
	if err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	cause := domain.PauseCause{
		Kind: domain.PauseCauseOwnerInput, AllowedActions: []domain.InterventionKind{
			domain.InterventionKindResume, domain.InterventionKindCancel,
		}, RecommendedAction: domain.InterventionKindResume,
	}
	paused, _, err := store.PauseWorkflow(ctx, WorkflowPauseRequest{
		ID: "pause-before-completion", RunID: run.ID, ExpectedVersion: run.Metadata.ResourceVersion,
		Cause: cause, Source: "owner",
	})
	if err != nil {
		t.Fatalf("PauseWorkflow() returned %v", err)
	}
	err = store.Transaction(ctx, func(transaction *Tx) error {
		node := nodes[0]
		now := paused.Metadata.UpdatedAt.Add(1)
		if err := transaction.transitionNodeRun(ctx, &node, domain.NodeRunStateSucceeded, now); err != nil {
			return err
		}
		return transaction.completeWorkflowRun(ctx, run.ID, now)
	})
	if err != nil {
		t.Fatalf("completeWorkflowRun() returned %v", err)
	}
	completed, _, err := store.WorkflowRun(ctx, run.ID)
	if err != nil || completed.State != domain.WorkflowRunStateSucceeded || completed.ActivePauseID != nil {
		t.Fatalf("completed workflow = %#v, %v", completed, err)
	}
}

func TestWorkflowRetryKeepsPauseForAnotherFailedNode(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, err := Open(ctx, filepath.Join(t.TempDir(), "colchis.db"))
	if err != nil {
		t.Fatalf("Open() returned %v", err)
	}
	defer store.Close()
	document := independentWorkflowDocument(t, 2, "alpha", "bravo")
	resolved := resolveWorkflowForStoreTest(t, document)
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-retry-pair", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	run, _, err := store.CreateWorkflowRun(ctx, "run-retry-pair", "definition-retry-pair", nil)
	if err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	var alpha domain.NodeRun
	var bravo domain.NodeRun
	err = store.Transaction(ctx, func(transaction *Tx) error {
		nodes, err := transaction.nodeRuns(ctx, &run.ID)
		if err != nil {
			return err
		}
		now := run.Metadata.UpdatedAt.Add(1)
		for index := range nodes {
			previousVersion := nodes[index].Metadata.ResourceVersion
			nodes[index].State = domain.NodeRunStateFailed
			nodes[index].Metadata.ResourceVersion++
			nodes[index].Metadata.UpdatedAt = now
			encoded, err := json.Marshal(nodes[index])
			if err != nil {
				return err
			}
			if err := transaction.updateRecord(
				ctx, nodeRunRecordKind, string(nodes[index].ID), previousVersion, nodes[index].Metadata, encoded,
			); err != nil {
				return err
			}
			if nodes[index].NodeKey == "alpha" {
				alpha = nodes[index]
			} else {
				bravo = nodes[index]
			}
		}
		return transaction.pauseWorkflowForNode(
			ctx, &run, alpha, domain.WorkflowRunStateFailed,
			domain.PauseCauseContractIncomplete, "alpha failed", now,
		)
	})
	if err != nil {
		t.Fatalf("prepare failed nodes returned %v", err)
	}
	if _, _, _, err := store.RetryWorkflowNode(ctx, WorkflowRetryRequest{
		ID: "retry-wrong-node", RunID: run.ID, NodeRunID: bravo.ID,
		ExpectedVersion: run.Metadata.ResourceVersion, Source: "owner",
	}); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("wrong-node RetryWorkflowNode() error = %v", err)
	}
	if err := store.EnableEmergencyReserve(); err != nil {
		t.Fatalf("EnableEmergencyReserve(retry) returned %v", err)
	}
	retryPayload, err := json.Marshal(WorkflowRetryRequest{
		ID: "retry-alpha", RunID: run.ID, NodeRunID: alpha.ID,
	})
	if err != nil {
		t.Fatalf("Marshal(retry) returned %v", err)
	}
	retryVersion := run.Metadata.ResourceVersion
	retryCommand := domain.CommandRequest{
		ID: "command-retry-alpha", IdempotencyKey: "retry-alpha", Kind: "workflow.retry",
		ExpectedVersion: &retryVersion, Payload: retryPayload,
	}
	if _, created, err := store.AcceptCommand(ctx, "owner", retryCommand); err != nil || !created {
		t.Fatalf("AcceptCommand(retry) = %t, %v", created, err)
	}
	if _, claimed, err := store.ClaimCommand(ctx, retryCommand.ID); err != nil || !claimed {
		t.Fatalf("ClaimCommand(retry) = %t, %v", claimed, err)
	}
	run, alpha, retry, err := store.RetryWorkflowNode(ctx, WorkflowRetryRequest{
		ID: "retry-alpha", RunID: run.ID, NodeRunID: alpha.ID,
		ExpectedVersion: retryVersion, Source: "owner", CommandID: retryCommand.ID,
	})
	if err != nil {
		t.Fatalf("RetryWorkflowNode(alpha) returned %v", err)
	}
	recovered, err := store.RecoverRunningCommands(ctx)
	if err != nil || len(recovered) != 1 || recovered[0].State != domain.CommandStateSucceeded {
		t.Fatalf("RecoverRunningCommands(retry) = %#v, %v", recovered, err)
	}
	var retryResult struct {
		Intervention domain.Intervention `json:"intervention"`
	}
	if err := json.Unmarshal(recovered[0].Result, &retryResult); err != nil || retryResult.Intervention.ID != retry.ID {
		t.Fatalf("recovered retry result = %#v, %v", retryResult, err)
	}
	if alpha.State != domain.NodeRunStateReady || run.State != domain.WorkflowRunStateFailed || run.ActivePauseID == nil {
		t.Fatalf("first retry = %#v, %#v", run, alpha)
	}
	run, bravo, _, err = store.RetryWorkflowNode(ctx, WorkflowRetryRequest{
		ID: "retry-bravo", RunID: run.ID, NodeRunID: bravo.ID,
		ExpectedVersion: run.Metadata.ResourceVersion, Source: "owner",
	})
	if err != nil {
		t.Fatalf("RetryWorkflowNode(bravo) returned %v", err)
	}
	if bravo.State != domain.NodeRunStateReady || run.State != domain.WorkflowRunStateRunning || run.ActivePauseID != nil {
		t.Fatalf("second retry = %#v, %#v", run, bravo)
	}
}

func TestNodeFailureReplacesPauseThatCannotRetryIt(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	run, nodes := createGraphTestRun(t, ctx, store, evaluator, "definition-replace-pause", "run-replace-pause")
	cause := domain.PauseCause{
		Kind: domain.PauseCauseOwnerInput,
		AllowedActions: []domain.InterventionKind{
			domain.InterventionKindResume, domain.InterventionKindCancel,
		},
		RecommendedAction: domain.InterventionKindResume,
	}
	paused, ownerPause, err := store.PauseWorkflow(ctx, WorkflowPauseRequest{
		ID: "pause-before-failure", RunID: run.ID, ExpectedVersion: run.Metadata.ResourceVersion,
		Cause: cause, Source: "owner",
	})
	if err != nil {
		t.Fatalf("PauseWorkflow() returned %v", err)
	}
	node := nodeByKey(t, nodes, "implement")
	err = store.Transaction(ctx, func(transaction *Tx) error {
		now := paused.Metadata.UpdatedAt.Add(1)
		if err := transaction.transitionNodeRun(ctx, &node, domain.NodeRunStateFailed, now); err != nil {
			return err
		}
		return transaction.pauseWorkflowForNode(
			ctx, &paused, node, domain.WorkflowRunStateFailed,
			domain.PauseCauseContractIncomplete, "node failed", now,
		)
	})
	if err != nil {
		t.Fatalf("pauseWorkflowForNode() returned %v", err)
	}
	if paused.ActivePauseID == nil || *paused.ActivePauseID == ownerPause.ID {
		t.Fatalf("failed workflow pause = %#v", paused)
	}
	if _, _, _, err := store.RetryWorkflowNode(ctx, WorkflowRetryRequest{
		ID: "retry-after-owner-pause", RunID: paused.ID, NodeRunID: node.ID,
		ExpectedVersion: paused.Metadata.ResourceVersion, Source: "owner",
	}); err != nil {
		t.Fatalf("RetryWorkflowNode() returned %v", err)
	}
}

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
