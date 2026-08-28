package sqlite

import (
	"context"
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

func TestEffectOperationRequiresExactOneUseOwnerAuthority(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(document, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	template := definition.Templates["implement"]
	template.Kind = "effect"
	template.Effects = workflowmodel.EffectPolicy{
		Mode: "allow", RequiresOwnerAuthority: true,
		Operations: []workflowmodel.EffectOperation{{
			Kind: "push", TargetSchemaDigest: graphTestSchemaDigest,
			Reconciliation: "observe", Idempotent: false,
		}},
	}
	definition.Templates["implement"] = template
	definition.Effects = template.Effects
	document, err = json.Marshal(definition)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	if _, err := store.CreateWorkflowDefinition(ctx, "definition-effect", nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-effect", "definition-effect", nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, "run-effect", AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	inputDigest, err := effectInputDigest(reserved[0])
	if err != nil {
		t.Fatalf("effectInputDigest() returned %v", err)
	}
	target := json.RawMessage(`{"remote":"origin","ref":"refs/heads/main","tree":"abc123"}`)
	commandRequest := domain.CommandRequest{
		ID: "command-effect", IdempotencyKey: "request-effect", Kind: "effect.push", Payload: target,
	}
	command, created, err := store.AcceptCommand(ctx, "owner:uid:501", commandRequest)
	if err != nil || !created || command.State != domain.CommandStateAccepted {
		t.Fatalf("AcceptCommand() = %#v, %v, %v", command, created, err)
	}
	authority, err := store.GrantEffectAuthority(ctx, EffectAuthorityRequest{
		ID: "authority-effect", CommandID: command.ID, NodeRunID: reserved[0].ID,
		OperationKind: "push", Target: target, InputDigest: inputDigest,
		Principal: command.Principal, ExpiresAt: time.Now().Add(time.Minute),
	})
	if err != nil {
		t.Fatalf("GrantEffectAuthority() returned %v", err)
	}
	if _, _, err := store.CreateWorkflowRun(ctx, "run-effect-child", "definition-effect", nil); err != nil {
		t.Fatalf("child CreateWorkflowRun() returned %v", err)
	}
	childReserved, err := store.ReserveReadyNodes(ctx, "run-effect-child", AdapterCapacity{"pi": 2})
	if err != nil || len(childReserved) != 1 {
		t.Fatalf("child ReserveReadyNodes() = %#v, %v", childReserved, err)
	}
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect-parent-authority", CommandID: command.ID, NodeRunID: childReserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: target,
		InputDigest: mustEffectInputDigest(t, childReserved[0]), AuthorityID: authority.ID,
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("parent authority BeginEffectOperation() error = %v", err)
	}
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect-denied", CommandID: command.ID, NodeRunID: reserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest,
		Target:      json.RawMessage(`{"remote":"origin","ref":"refs/heads/main","tree":"different"}`),
		InputDigest: inputDigest, AuthorityID: authority.ID,
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("unauthorized BeginEffectOperation() error = %v", err)
	}
	events, err := store.EventsAfter(ctx, 0, 100)
	if err != nil {
		t.Fatalf("EventsAfter() returned %v", err)
	}
	denied := false
	for _, event := range events {
		if event.Type == "workflow.effect.denied" {
			denied = true
		}
	}
	if !denied {
		t.Fatal("unauthorized effect did not record a denied event")
	}
	operation, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect", CommandID: command.ID, NodeRunID: reserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: target,
		InputDigest: inputDigest, AuthorityID: authority.ID,
	})
	if err != nil || operation.State != domain.OperationStatePending {
		t.Fatalf("BeginEffectOperation() = %#v, %v", operation, err)
	}
	operation, err = store.ClaimEffectOperation(ctx, operation.ID)
	if err != nil || operation.State != domain.OperationStateRunning || operation.Attempt != 1 {
		t.Fatalf("ClaimEffectOperation() = %#v, %v", operation, err)
	}
	operation, err = store.FinishEffectOperation(
		ctx, operation.ID, domain.OperationStateIndeterminate, json.RawMessage(`{"response":"lost"}`),
	)
	if err != nil || operation.State != domain.OperationStateIndeterminate || operation.Retryable {
		t.Fatalf("FinishEffectOperation() = %#v, %v", operation, err)
	}
	if _, err := store.ClaimEffectOperation(ctx, operation.ID); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("second ClaimEffectOperation() error = %v", err)
	}
	replayCommand, created, err := store.AcceptCommand(ctx, command.Principal, domain.CommandRequest{
		ID: "command-effect-replay", IdempotencyKey: "request-effect-replay",
		Kind:    command.Kind,
		Payload: json.RawMessage(`{"tree":"abc123","ref":"refs/heads/main","remote":"origin"}`),
	})
	if err != nil || !created {
		t.Fatalf("replay AcceptCommand() = %#v, %t, %v", replayCommand, created, err)
	}
	replayAuthority, err := store.GrantEffectAuthority(ctx, EffectAuthorityRequest{
		ID: "authority-effect-replay", CommandID: replayCommand.ID, NodeRunID: reserved[0].ID,
		OperationKind: "push",
		Target:        replayCommand.Payload,
		InputDigest:   inputDigest, Principal: command.Principal, ExpiresAt: time.Now().Add(time.Minute),
	})
	if err != nil {
		t.Fatalf("replay GrantEffectAuthority() returned %v", err)
	}
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect-replay", CommandID: replayCommand.ID, NodeRunID: reserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: replayCommand.Payload,
		InputDigest: inputDigest, AuthorityID: replayAuthority.ID,
	}); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("unreconciled replay BeginEffectOperation() error = %v", err)
	}
	if _, _, err := store.ReconcileEffectObservation(
		ctx, "reconciliation-wrong-run", operation.ID, "run-other", target, command.Principal,
	); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("wrong-run ReconcileEffectObservation() error = %v", err)
	}
	operation, reconciliation, err := store.ReconcileEffectObservation(
		ctx, "reconciliation-effect", operation.ID, "run-effect", target, command.Principal,
	)
	if err != nil || operation.State != domain.OperationStateSucceeded ||
		reconciliation.Resolution != "applied" {
		t.Fatalf("ReconcileEffectOperation() = %#v, %#v, %v", operation, reconciliation, err)
	}
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect-replay", CommandID: replayCommand.ID, NodeRunID: reserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: replayCommand.Payload,
		InputDigest: inputDigest, AuthorityID: replayAuthority.ID,
	}); err != nil {
		t.Fatalf("reconciled replay BeginEffectOperation() returned %v", err)
	}
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-effect-reuse", CommandID: command.ID, NodeRunID: reserved[0].ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: target,
		InputDigest: inputDigest, AuthorityID: authority.ID,
	}); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
		t.Fatalf("reused BeginEffectOperation() error = %v", err)
	}
}

func TestReconcileEffectObservationDerivesNotAppliedFromAdapterOutput(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	reserved, command, authority, target := prepareEffectOperation(t, ctx, store, evaluator, "observed-mismatch", true)
	operation, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-observed-mismatch", CommandID: command.ID, NodeRunID: reserved.ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: target,
		InputDigest: authority.InputDigest, AuthorityID: authority.ID,
	})
	if err != nil {
		t.Fatalf("BeginEffectOperation() returned %v", err)
	}
	operation, err = store.ClaimEffectOperation(ctx, operation.ID)
	if err != nil {
		t.Fatalf("ClaimEffectOperation() returned %v", err)
	}
	operation, err = store.FinishEffectOperation(
		ctx, operation.ID, domain.OperationStateIndeterminate, json.RawMessage(`{"response":"lost"}`),
	)
	if err != nil {
		t.Fatalf("FinishEffectOperation() returned %v", err)
	}
	operation, reconciliation, err := store.ReconcileEffectObservation(
		ctx, "reconciliation-observed-mismatch", operation.ID, "run-recovery-observed-mismatch",
		json.RawMessage(`{"remote":"origin","ref":"refs/heads/main","tree":"other"}`), command.Principal,
	)
	if err != nil || operation.State != domain.OperationStateFailed || reconciliation.Resolution != "not_applied" {
		t.Fatalf("ReconcileEffectObservation() = %#v, %#v, %v", operation, reconciliation, err)
	}
}

func TestRecoverEffectOperationsDistinguishesDispatchBoundary(t *testing.T) {
	t.Parallel()

	for _, test := range []struct {
		name          string
		suffix        string
		claim         bool
		wantOperation domain.OperationState
		wantCommand   domain.CommandState
	}{
		{
			name: "intent only", suffix: "intent-only",
			wantOperation: domain.OperationStateFailed, wantCommand: domain.CommandStateFailed,
		},
		{
			name: "dispatch claimed", suffix: "dispatch-claimed", claim: true,
			wantOperation: domain.OperationStateIndeterminate, wantCommand: domain.CommandStateIndeterminate,
		},
	} {
		t.Run(test.name, func(t *testing.T) {
			ctx := context.Background()
			store, evaluator := openGraphTestStore(t, ctx)
			defer store.Close()
			reserved, command, authority, target := prepareEffectOperation(t, ctx, store, evaluator, test.suffix, true)
			operation, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
				ID: domain.OperationID("operation-recovery-" + test.suffix), CommandID: command.ID,
				NodeRunID: reserved.ID, Kind: "push", TargetSchemaDigest: graphTestSchemaDigest,
				Target: target, InputDigest: authority.InputDigest, AuthorityID: authority.ID,
			})
			if err != nil {
				t.Fatalf("BeginEffectOperation() returned %v", err)
			}
			if test.claim {
				operation, err = store.ClaimEffectOperation(ctx, operation.ID)
				if err != nil {
					t.Fatalf("ClaimEffectOperation() returned %v", err)
				}
			}
			if _, err := store.RecoverRunningCommands(ctx); err != nil {
				t.Fatalf("RecoverRunningCommands() returned %v", err)
			}
			recovered, err := store.RecoverEffectOperations(ctx)
			if err != nil || len(recovered) != 1 || recovered[0].State != test.wantOperation {
				t.Fatalf("RecoverEffectOperations() = %#v, %v", recovered, err)
			}
			if _, err := store.ClaimEffectOperation(ctx, operation.ID); !domain.IsErrorCode(err, domain.ErrorCodeConflict) {
				t.Fatalf("ClaimEffectOperation() after recovery error = %v", err)
			}
			command, created, err := store.AcceptCommand(ctx, command.Principal, domain.CommandRequest{
				ID: command.ID, IdempotencyKey: command.IdempotencyKey, Kind: command.Kind, Payload: command.Payload,
			})
			if err != nil || created || command.State != test.wantCommand {
				t.Fatalf("AcceptCommand() after recovery = %#v, %t, %v", command, created, err)
			}
		})
	}
}

func TestEffectOperationRequiresWorkflowPolicy(t *testing.T) {
	t.Parallel()

	ctx := context.Background()
	store, evaluator := openGraphTestStore(t, ctx)
	defer store.Close()
	reserved, command, authority, target := prepareEffectOperation(
		t, ctx, store, evaluator, "workflow-denied", false,
	)
	if _, err := store.BeginEffectOperation(ctx, EffectOperationRequest{
		ID: "operation-workflow-denied", CommandID: command.ID, NodeRunID: reserved.ID,
		Kind: "push", TargetSchemaDigest: graphTestSchemaDigest, Target: target,
		InputDigest: authority.InputDigest, AuthorityID: authority.ID,
	}); !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("BeginEffectOperation() error = %v", err)
	}
}

func prepareEffectOperation(
	t *testing.T,
	ctx context.Context,
	store *Store,
	evaluator *workflowmodel.Evaluator,
	suffix string,
	workflowAllows bool,
) (domain.NodeRun, domain.CommandRecord, domain.EffectAuthority, json.RawMessage) {
	t.Helper()
	document, err := os.ReadFile("../../../schemas/workflow/v1/testdata/valid.json")
	if err != nil {
		t.Fatalf("ReadFile() returned %v", err)
	}
	var definition workflowmodel.Definition
	if err := json.Unmarshal(document, &definition); err != nil {
		t.Fatalf("Unmarshal() returned %v", err)
	}
	template := definition.Templates["implement"]
	template.Kind = "effect"
	template.Effects = workflowmodel.EffectPolicy{
		Mode: "allow", RequiresOwnerAuthority: true,
		Operations: []workflowmodel.EffectOperation{{
			Kind: "push", TargetSchemaDigest: graphTestSchemaDigest,
			Reconciliation: "observe", Idempotent: false,
		}},
	}
	definition.Templates["implement"] = template
	if workflowAllows {
		definition.Effects = template.Effects
	}
	document, err = json.Marshal(definition)
	if err != nil {
		t.Fatalf("Marshal() returned %v", err)
	}
	resolved, err := evaluator.Resolve(document, graphTestCapabilities())
	if err != nil {
		t.Fatalf("Resolve() returned %v", err)
	}
	definitionID := domain.WorkflowDefinitionID("definition-recovery-" + suffix)
	if _, err := store.CreateWorkflowDefinition(ctx, definitionID, nil, document, resolved); err != nil {
		t.Fatalf("CreateWorkflowDefinition() returned %v", err)
	}
	runID := domain.WorkflowRunID("run-recovery-" + suffix)
	if _, _, err := store.CreateWorkflowRun(ctx, runID, definitionID, nil); err != nil {
		t.Fatalf("CreateWorkflowRun() returned %v", err)
	}
	reserved, err := store.ReserveReadyNodes(ctx, runID, AdapterCapacity{"pi": 1})
	if err != nil || len(reserved) != 1 {
		t.Fatalf("ReserveReadyNodes() = %#v, %v", reserved, err)
	}
	target := json.RawMessage(`{"remote":"origin","ref":"refs/heads/main","tree":"abc123"}`)
	command, created, err := store.AcceptCommand(ctx, "owner:uid:501", domain.CommandRequest{
		ID:             domain.CommandID("command-recovery-" + suffix),
		IdempotencyKey: "request-recovery-" + suffix, Kind: "effect.push", Payload: target,
	})
	if err != nil || !created {
		t.Fatalf("AcceptCommand() = %#v, %t, %v", command, created, err)
	}
	authority, err := store.GrantEffectAuthority(ctx, EffectAuthorityRequest{
		ID: domain.EffectAuthorityID("authority-recovery-" + suffix), CommandID: command.ID,
		NodeRunID: reserved[0].ID, OperationKind: "push", Target: target,
		InputDigest: mustEffectInputDigest(t, reserved[0]),
		Principal:   command.Principal, ExpiresAt: time.Now().Add(time.Minute),
	})
	if err != nil {
		t.Fatalf("GrantEffectAuthority() returned %v", err)
	}
	return reserved[0], command, authority, target
}

func mustEffectInputDigest(t *testing.T, node domain.NodeRun) string {
	t.Helper()
	digest, err := effectInputDigest(node)
	if err != nil {
		t.Fatalf("effectInputDigest() returned %v", err)
	}
	return digest
}
