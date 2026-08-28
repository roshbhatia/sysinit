package broker

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

type AdapterCapabilitySource interface {
	AdapterCapabilities() map[string][]string
}

type ControlExecutor struct {
	store        *sqlite.Store
	adapters     *AdapterService
	sessions     *SessionService
	evaluator    *workflowmodel.Evaluator
	capabilities AdapterCapabilitySource
}

type planningCommand struct {
	PluginID  domain.PluginID `json:"pluginId"`
	AdapterID string          `json:"adapterId"`
	Input     json.RawMessage `json:"input"`
}

type adapterCommand struct {
	PluginID    domain.PluginID          `json:"pluginId"`
	Owner       domain.ResourceReference `json:"owner"`
	NewHandleID *domain.AdapterHandleID  `json:"newHandleId,omitempty"`
	Operation   plugin.OperationEnvelope `json:"operation"`
}

type workflowCreateCommand struct {
	DefinitionID domain.WorkflowDefinitionID  `json:"definitionId"`
	Predecessor  *domain.WorkflowDefinitionID `json:"predecessorId,omitempty"`
	Document     json.RawMessage              `json:"document"`
}

type workflowRunCommand struct {
	RunID                domain.WorkflowRunID        `json:"runId"`
	DefinitionID         domain.WorkflowDefinitionID `json:"definitionId"`
	OrchestrationSession *domain.SessionID           `json:"orchestrationSessionId,omitempty"`
}

type workflowScheduleCommand struct {
	RunID           domain.WorkflowRunID   `json:"runId"`
	AdapterCapacity sqlite.AdapterCapacity `json:"adapterCapacity"`
}

type provenanceInspectCommand struct{}

type workflowInspectCommand struct {
	RunID domain.WorkflowRunID `json:"runId"`
}

type workflowExportCommand struct {
	DefinitionID domain.WorkflowDefinitionID `json:"definitionId"`
}

type graphPatchCommand struct {
	ID                        domain.GraphPatchID          `json:"id"`
	RunID                     domain.WorkflowRunID         `json:"workflowRunId"`
	ResultDefinitionID        domain.WorkflowDefinitionID  `json:"resultWorkflowDefinitionId"`
	ExpectedDefinitionVersion uint64                       `json:"expectedDefinitionVersion"`
	Operations                []domain.GraphPatchOperation `json:"operations"`
}

type replayCommand struct {
	ID                      domain.RunForkID            `json:"id"`
	ParentWorkflowRunID     domain.WorkflowRunID        `json:"parentWorkflowRunId"`
	ChildWorkflowRunID      domain.WorkflowRunID        `json:"childWorkflowRunId"`
	RestartPointID          domain.RestartPointID       `json:"restartPointId"`
	TargetDefinitionID      domain.WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
	TargetDefinitionVersion uint64                      `json:"targetDefinitionVersion"`
	ExpectedParentVersion   domain.ResourceVersion      `json:"expectedParentVersion"`
	ReusedAdmissionIDs      []domain.AdmissionID        `json:"reusedAdmissionIds"`
	EnvironmentIDs          map[string]string           `json:"environmentIds"`
}

type sessionHistoryCommand struct {
	SessionID domain.SessionID `json:"sessionId"`
}

type workspaceSnapshotCommand struct {
	ID            domain.SnapshotID  `json:"id"`
	WorkspaceID   domain.WorkspaceID `json:"workspaceId"`
	WorkspacePath string             `json:"workspacePath"`
}

type sessionCancelResult struct {
	Session      domain.Session      `json:"session"`
	Intervention domain.Intervention `json:"intervention"`
}

type workflowRunResult struct {
	Run        domain.WorkflowRun         `json:"run"`
	Definition *domain.WorkflowDefinition `json:"definition,omitempty"`
	Nodes      []domain.NodeRun           `json:"nodes"`
}

type graphPatchResult struct {
	Definition domain.WorkflowDefinition `json:"definition"`
	Patch      domain.GraphPatch         `json:"patch"`
}

type replayResult struct {
	Run  domain.WorkflowRun `json:"run"`
	Fork domain.RunFork     `json:"fork"`
}

type effectReconcileResult struct {
	Operation      domain.Operation            `json:"operation"`
	Reconciliation domain.EffectReconciliation `json:"reconciliation"`
}

type effectReconcileCommand struct {
	ID            domain.EffectReconciliationID `json:"id"`
	OperationID   domain.OperationID            `json:"operationId"`
	WorkflowRunID domain.WorkflowRunID          `json:"workflowRunId"`
	Observation   adapterCommand                `json:"observation"`
}

type effectObservationResult struct {
	Target json.RawMessage `json:"target"`
}

func NewControlExecutor(
	store *sqlite.Store,
	adapters *AdapterService,
	sessions *SessionService,
	capabilities AdapterCapabilitySource,
) (*ControlExecutor, error) {
	if store == nil || adapters == nil || sessions == nil || capabilities == nil {
		return nil, controlError("control executor", "store, adapters, sessions, and capabilities are required")
	}
	evaluator, err := workflowmodel.NewEvaluator(workflowmodel.EvaluatorVersion)
	if err != nil {
		return nil, err
	}
	return &ControlExecutor{
		store: store, adapters: adapters, sessions: sessions,
		evaluator: evaluator, capabilities: capabilities,
	}, nil
}

func (executor *ControlExecutor) ExecuteCommand(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) error {
	_, err := executor.ExecuteCommandResult(ctx, principal, request)
	return err
}

func (executor *ControlExecutor) ExecuteCommandResult(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	switch request.Kind {
	case "planning.discover", "planning.snapshot", "planning.action":
		return executor.invokePlanning(ctx, request)
	case "adapter.invoke":
		return executor.invokeAdapter(ctx, request)
	case "workflow.create":
		return executor.createWorkflow(ctx, request)
	case "workflow.run":
		return executor.createWorkflowRun(ctx, request)
	case "workflow.schedule":
		var command workflowScheduleCommand
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.ReserveReadyNodes(ctx, command.RunID, command.AdapterCapacity)
		return encodeControlResult(result, err)
	case "workflow.inspect":
		return executor.inspectWorkflow(ctx, request)
	case "workflow.export":
		return executor.exportWorkflow(ctx, request)
	case "graph.patch":
		return executor.patchGraph(ctx, request)
	case "workflow.replay":
		return executor.replayWorkflow(ctx, principal, request)
	case "workflow.restart-point":
		var command sqlite.RestartPointRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.CreateRestartPoint(ctx, command)
		return encodeControlResult(result, err)
	case "agent.start":
		var command StartSessionRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.sessions.StartSession(ctx, command)
		return encodeControlResult(result, err)
	case "agent.intervene", "agent.policy":
		var command ForwardInterventionRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.sessions.ForwardIntervention(ctx, command)
		return encodeControlResult(result, err)
	case "agent.attach", "agent.detach":
		var command ForwardAttachmentRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.sessions.ForwardAttachment(ctx, command)
		return encodeControlResult(result, err)
	case "agent.cancel":
		var command sqlite.InterventionRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		session, intervention, err := executor.sessions.CancelSession(ctx, command)
		return encodeControlResult(sessionCancelResult{Session: session, Intervention: intervention}, err)
	case "agent.history":
		var command sessionHistoryCommand
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.SessionHistory(ctx, command.SessionID)
		return encodeControlResult(result, err)
	case "workspace.snapshot":
		var command workspaceSnapshotCommand
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.CreateWorkspaceSnapshot(
			ctx, command.ID, command.WorkspaceID, command.WorkspacePath,
		)
		return encodeControlResult(result, err)
	case "artifact.resolve":
		var command sqlite.ArtifactRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.ResolveArtifact(ctx, command)
		return encodeControlResult(result, err)
	case "verification.submit":
		var command sqlite.TaskResultRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.SubmitTaskResult(ctx, command)
		return encodeControlResult(result, err)
	case "verification.task-record":
		var command sqlite.TaskRecordRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.CreateTaskRecord(ctx, command)
		return encodeControlResult(result, err)
	case "verification.record":
		var command sqlite.ValidationRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.RecordValidation(ctx, command)
		return encodeControlResult(result, err)
	case "verification.admit":
		var command sqlite.AdmissionRequest
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.DecideAdmission(ctx, command)
		return encodeControlResult(result, err)
	case "effect.reconcile":
		var command effectReconcileCommand
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		if command.Observation.Operation.Port != domain.AdapterPortEffect ||
			command.Observation.Operation.Operation != "effect.observe" ||
			command.Observation.NewHandleID != nil || command.Observation.Operation.HandleID != nil {
			return nil, &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "reconcile effect", Resource: command.Observation.Operation.Operation,
				Message: "effect observation must use effect.observe without handles",
			}
		}
		observed, err := executor.adapters.Invoke(ctx, AdapterInvocationRequest{
			PluginID: command.Observation.PluginID, Operation: command.Observation.Operation,
		})
		if err != nil {
			return nil, err
		}
		if observed.Operation.State != domain.OperationStateSucceeded {
			return nil, &domain.Error{
				Code: domain.ErrorCodeIndeterminate, Op: "reconcile effect", Resource: string(command.OperationID),
				Message: "effect observation did not complete",
			}
		}
		observation, observationErr := decodeEffectObservation(observed.Operation.Output)
		if observationErr != nil {
			return nil, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "reconcile effect", Resource: string(command.OperationID),
				Message: "effect observer returned an invalid target", Err: observationErr,
			}
		}
		operation, reconciliation, err := executor.store.ReconcileEffectObservation(
			ctx, command.ID, command.OperationID, command.WorkflowRunID,
			observation.Target, principal.Identifier(),
		)
		return encodeControlResult(effectReconcileResult{
			Operation: operation, Reconciliation: reconciliation,
		}, err)
	case "provenance.commit":
		var command domain.CommitObservation
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.RecordCommitObservation(ctx, command)
		return encodeControlResult(result, err)
	case "provenance.relation":
		var command domain.ProvenanceRelation
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.RecordProvenanceRelation(ctx, command)
		return encodeControlResult(result, err)
	case "provenance.inspect":
		var command provenanceInspectCommand
		if err := decodeControlPayload(request, &command); err != nil {
			return nil, err
		}
		result, err := executor.store.InspectProvenance(ctx)
		return encodeControlResult(result, err)
	case "broker.inspect":
		result, err := executor.store.Inspect(ctx)
		return encodeControlResult(result, err)
	default:
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "execute command", Resource: request.Kind,
			Message: "command kind is unsupported",
		}
	}
}

func (executor *ControlExecutor) invokePlanning(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command planningCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	if command.PluginID == "" {
		command.PluginID = "sysinit"
	}
	if command.AdapterID == "" {
		command.AdapterID = "openspec"
	}
	if command.Input == nil {
		command.Input = json.RawMessage(`{}`)
	}
	operation := plugin.OperationEnvelope{
		ID: domain.OperationID(request.ID), AdapterID: command.AdapterID, Port: domain.AdapterPortPlanning,
		Operation: request.Kind, Input: command.Input, Deadline: time.Now().Add(30 * time.Second),
	}
	result, err := executor.adapters.Invoke(ctx, AdapterInvocationRequest{
		PluginID: command.PluginID, Operation: operation,
	})
	return encodeControlResult(result.Operation.Output, err)
}

func (executor *ControlExecutor) invokeAdapter(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command adapterCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	if !genericAdapterOperationAllowed(command.Operation.Operation) {
		return nil, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "invoke adapter", Resource: command.Operation.Operation,
			Message: "operation requires a broker-owned command path",
		}
	}
	result, err := executor.adapters.Invoke(ctx, AdapterInvocationRequest(command))
	return encodeControlResult(result, err)
}

func genericAdapterOperationAllowed(operation string) bool {
	switch operation {
	case "planning.discover", "planning.snapshot", "planning.action",
		"workspace.snapshot", "environment.resolve", "environment.check",
		"activity.import", "activity.observe", "agent-runtime.reconcile":
		return true
	default:
		return false
	}
}

func (executor *ControlExecutor) createWorkflow(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command workflowCreateCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	resolved, err := executor.evaluator.Resolve(
		command.Document, workflowmodel.CapabilityMap(executor.capabilities.AdapterCapabilities()),
	)
	if err != nil {
		return nil, err
	}
	result, err := executor.store.CreateWorkflowDefinition(
		ctx, command.DefinitionID, command.Predecessor, command.Document, resolved,
	)
	return encodeControlResult(result, err)
}

func (executor *ControlExecutor) createWorkflowRun(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command workflowRunCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	run, nodes, err := executor.store.CreateWorkflowRun(
		ctx, command.RunID, command.DefinitionID, command.OrchestrationSession,
	)
	return encodeControlResult(workflowRunResult{Run: run, Nodes: nodes}, err)
}

func (executor *ControlExecutor) inspectWorkflow(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command workflowInspectCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	run, nodes, err := executor.store.WorkflowRun(ctx, command.RunID)
	if err != nil {
		return nil, err
	}
	definition, err := executor.store.WorkflowDefinition(ctx, run.WorkflowDefinition)
	return encodeControlResult(workflowRunResult{Run: run, Definition: &definition, Nodes: nodes}, err)
}

func (executor *ControlExecutor) exportWorkflow(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command workflowExportCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	return executor.store.ExportWorkflowDefinition(ctx, command.DefinitionID)
}

func (executor *ControlExecutor) patchGraph(
	ctx context.Context,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command graphPatchCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	definition, patch, err := executor.store.ApplyGraphPatch(ctx, sqlite.GraphPatchRequest{
		ID: command.ID, RunID: command.RunID, ResultDefinitionID: command.ResultDefinitionID,
		ExpectedDefinitionVersion: command.ExpectedDefinitionVersion,
		CommandID:                 request.ID, Operations: command.Operations,
	}, executor.evaluator, workflowmodel.CapabilityMap(executor.capabilities.AdapterCapabilities()))
	return encodeControlResult(graphPatchResult{Definition: definition, Patch: patch}, err)
}

func (executor *ControlExecutor) replayWorkflow(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	var command replayCommand
	if err := decodeControlPayload(request, &command); err != nil {
		return nil, err
	}
	run, fork, err := executor.store.ReplayWorkflow(ctx, sqlite.ReplayRequest{
		ID: command.ID, ParentWorkflowRunID: command.ParentWorkflowRunID,
		ChildWorkflowRunID: command.ChildWorkflowRunID, RestartPointID: command.RestartPointID,
		TargetDefinitionID:      command.TargetDefinitionID,
		TargetDefinitionVersion: command.TargetDefinitionVersion,
		ExpectedParentVersion:   command.ExpectedParentVersion,
		ReusedAdmissionIDs:      command.ReusedAdmissionIDs, EnvironmentIDs: command.EnvironmentIDs,
		CommandID: request.ID, Principal: principal.Identifier(),
	})
	return encodeControlResult(replayResult{Run: run, Fork: fork}, err)
}

func decodeEffectObservation(payload json.RawMessage) (effectObservationResult, error) {
	var observation effectObservationResult
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&observation); err != nil {
		return effectObservationResult{}, err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return effectObservationResult{}, errors.New("effect observation contains trailing data")
	}
	if len(observation.Target) == 0 || !json.Valid(observation.Target) {
		return effectObservationResult{}, errors.New("effect observation target must be valid JSON")
	}
	return observation, nil
}

func decodeControlPayload[Value interface {
	*planningCommand | *adapterCommand | *workflowCreateCommand | *workflowRunCommand | *workflowScheduleCommand |
		*workflowInspectCommand | *workflowExportCommand | *graphPatchCommand | *replayCommand |
		*sqlite.RestartPointRequest | *StartSessionRequest | *ForwardInterventionRequest |
		*ForwardAttachmentRequest | *sqlite.InterventionRequest |
		*sessionHistoryCommand | *workspaceSnapshotCommand | *sqlite.ArtifactRequest |
		*sqlite.TaskResultRequest | *sqlite.TaskRecordRequest | *sqlite.ValidationRequest |
		*sqlite.AdmissionRequest | *effectReconcileCommand |
		*domain.CommitObservation | *domain.ProvenanceRelation | *provenanceInspectCommand
}](request domain.CommandRequest, target Value) error {
	decoder := json.NewDecoder(bytes.NewReader(request.Payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return controlError(request.Kind, err.Error())
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); !errors.Is(err, io.EOF) {
		return controlError(request.Kind, "payload has trailing JSON")
	}
	return nil
}

type controlResult interface {
	json.RawMessage | []domain.NodeRun | AdapterInvocationResult | StartSessionResult |
		ForwardInterventionResult | ForwardAttachmentResult |
		sessionCancelResult | sqlite.SessionHistory | workflowRunResult | graphPatchResult | replayResult |
		effectReconcileResult |
		domain.WorkflowDefinition | domain.Snapshot | domain.Artifact | sqlite.TaskResultSubmission |
		domain.TaskRecord | domain.Validation | domain.Admission | domain.CommitObservation |
		domain.ProvenanceRelation | domain.RestartPoint | sqlite.ProvenanceInspection | sqlite.Inspection
}

func encodeControlResult[Value controlResult](value Value, resultErr error) (json.RawMessage, error) {
	if resultErr != nil {
		return nil, resultErr
	}
	payload, err := json.Marshal(value)
	if err != nil {
		return nil, controlError("command result", err.Error())
	}
	return payload, nil
}

func controlError(resource string, message string) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "control", Resource: resource, Message: message,
	}
}
