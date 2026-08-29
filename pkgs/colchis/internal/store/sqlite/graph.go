package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	graphPatchRecordKind   = "graph-patch"
	restartPointRecordKind = "restart-point"
	runForkRecordKind      = "run-fork"
)

type GraphPatchRequest struct {
	ID                        domain.GraphPatchID          `json:"id"`
	RunID                     domain.WorkflowRunID         `json:"workflowRunId"`
	ResultDefinitionID        domain.WorkflowDefinitionID  `json:"resultWorkflowDefinitionId"`
	ExpectedDefinitionVersion uint64                       `json:"expectedDefinitionVersion"`
	CommandID                 domain.CommandID             `json:"commandId"`
	Operations                []domain.GraphPatchOperation `json:"operations"`
}

type RestartPointRequest struct {
	ID            domain.RestartPointID   `json:"id"`
	Kind          domain.RestartPointKind `json:"kind"`
	WorkflowRunID domain.WorkflowRunID    `json:"workflowRunId"`
	EventCursor   domain.EventCursor      `json:"eventCursor"`
	SnapshotID    domain.SnapshotID       `json:"snapshotId"`
	NodeRunID     *domain.NodeRunID       `json:"nodeRunId,omitempty"`
	AdmissionIDs  []domain.AdmissionID    `json:"admissionIds"`
	CheckpointIDs []domain.CheckpointID   `json:"checkpointIds"`
}

type ReplayRequest struct {
	ID                      domain.RunForkID            `json:"id"`
	ParentWorkflowRunID     domain.WorkflowRunID        `json:"parentWorkflowRunId"`
	ChildWorkflowRunID      domain.WorkflowRunID        `json:"childWorkflowRunId"`
	RestartPointID          domain.RestartPointID       `json:"restartPointId"`
	TargetDefinitionID      domain.WorkflowDefinitionID `json:"targetWorkflowDefinitionId"`
	TargetDefinitionVersion uint64                      `json:"targetDefinitionVersion"`
	ExpectedParentVersion   domain.ResourceVersion      `json:"expectedParentVersion"`
	ReusedAdmissionIDs      []domain.AdmissionID        `json:"reusedAdmissionIds"`
	EnvironmentIDs          map[string]string           `json:"environmentIds"`
	CommandID               domain.CommandID            `json:"commandId"`
	Principal               string                      `json:"principal"`
}

func (store *Store) ApplyGraphPatch(
	ctx context.Context,
	request GraphPatchRequest,
	evaluator *workflowmodel.Evaluator,
	resolver workflowmodel.CapabilityResolver,
) (domain.WorkflowDefinition, domain.GraphPatch, error) {
	if err := validateGraphPatchRequest(request); err != nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, err
	}
	if evaluator == nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "patch", Resource: string(request.ID),
			Message: "workflow evaluator is nil",
		}
	}
	run, _, err := store.WorkflowRun(ctx, request.RunID)
	if err != nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, err
	}
	if run.DefinitionVersion != request.ExpectedDefinitionVersion {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, patchVersionConflict(request, run)
	}
	baseRecord, err := store.WorkflowDefinition(ctx, run.WorkflowDefinition)
	if err != nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, err
	}
	base, err := decodeResolvedDefinition(baseRecord)
	if err != nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, err
	}
	patched, err := evaluator.ApplyOperations(base, request.Operations, resolver)
	if err != nil {
		return domain.WorkflowDefinition{}, domain.GraphPatch{}, err
	}

	var definitionRecord domain.WorkflowDefinition
	var patchRecord domain.GraphPatch
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, graphPatchRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(request.ID),
				Message: "graph patch already exists",
			}
		}
		currentRun, found, err := transaction.workflowRun(ctx, request.RunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "patch", Resource: string(request.RunID),
				Message: "workflow run does not exist",
			}
		}
		if currentRun.DefinitionVersion != request.ExpectedDefinitionVersion ||
			currentRun.WorkflowDefinition != baseRecord.ID {
			return patchVersionConflict(request, currentRun)
		}
		if workflowRunIsTerminal(currentRun.State) {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(currentRun.ID),
				Message: "terminal workflow run cannot accept a live patch",
			}
		}
		if _, found, err := transaction.workflowDefinition(ctx, request.ResultDefinitionID); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(request.ResultDefinitionID),
				Message: "result workflow definition already exists",
			}
		}
		if baseRecord.DefinitionVersion == ^uint64(0) {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(baseRecord.ID),
				Message: "workflow definition version is exhausted",
			}
		}
		nodes, err := transaction.nodeRuns(ctx, &request.RunID)
		if err != nil {
			return err
		}
		affected := make(map[domain.NodeKey]struct{}, len(patched.AffectedNodes))
		for _, key := range patched.AffectedNodes {
			affected[key] = struct{}{}
		}
		for _, node := range nodes {
			if _, changed := affected[node.NodeKey]; changed && nodeHasStarted(node) {
				restartID, found, restartErr := transaction.earliestRestartPoint(ctx, request.RunID)
				if restartErr != nil {
					return restartErr
				}
				message := "patch affects work that already started"
				details := map[string]string{"affectedNodeRunId": string(node.ID)}
				if found {
					message += "; earliest restart point is " + string(restartID)
					details["earliestRestartPointId"] = string(restartID)
				}
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(node.ID),
					Message: message, Details: details,
				}
			}
		}
		now := time.Now().UTC()
		predecessorID := baseRecord.ID
		definitionRecord = domain.WorkflowDefinition{
			Metadata: newRecordMetadata(now), ID: request.ResultDefinitionID,
			PredecessorID: &predecessorID, DefinitionVersion: baseRecord.DefinitionVersion + 1,
			DefinitionSchemaVersion: patched.Resolved.Definition.SchemaVersion,
			DefinitionDigest:        patched.Resolved.DefinitionDigest,
			SchemaDigest:            patched.Resolved.SchemaDigest,
			EvaluatorVersion:        patched.Resolved.Definition.EvaluatorVersion,
			Document:                append(json.RawMessage(nil), patched.Resolved.Document...),
			ResolvedDocument:        append(json.RawMessage(nil), patched.Resolved.Document...),
		}
		definitionPayload, err := json.Marshal(definitionRecord)
		if err != nil {
			return wrap("encode patched workflow definition", string(definitionRecord.ID), err)
		}
		patchRecord = domain.GraphPatch{
			Metadata: newRecordMetadata(now), ID: request.ID, WorkflowRunID: &request.RunID,
			BaseWorkflowDefinitionID:   baseRecord.ID,
			ResultWorkflowDefinitionID: request.ResultDefinitionID,
			ExpectedDefinitionVersion:  request.ExpectedDefinitionVersion,
			CommandID:                  request.CommandID, Operations: append([]domain.GraphPatchOperation(nil), request.Operations...),
		}
		patchPayload, err := json.Marshal(patchRecord)
		if err != nil {
			return wrap("encode graph patch", string(request.ID), err)
		}
		if err := transaction.reserveRecordBytes(
			ctx, uint64(len(definitionPayload)+len(patchPayload)), 2,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, workflowDefinitionRecordKind, string(definitionRecord.ID),
			definitionRecord.Metadata, definitionPayload,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, graphPatchRecordKind, string(patchRecord.ID), patchRecord.Metadata, patchPayload,
		); err != nil {
			return err
		}
		if err := transaction.reconcilePatchedNodes(
			ctx, currentRun, nodes, patched.Resolved.Definition,
			definitionRecord.DefinitionVersion, affected, now,
		); err != nil {
			return err
		}
		if err := transaction.advanceDependentNodes(ctx, currentRun.ID, patched.Resolved.Definition, now); err != nil {
			return err
		}
		previousVersion := currentRun.Metadata.ResourceVersion
		currentRun.WorkflowDefinition = definitionRecord.ID
		currentRun.DefinitionVersion = definitionRecord.DefinitionVersion
		currentRun.Metadata.ResourceVersion++
		currentRun.Metadata.UpdatedAt = now
		runPayload, err := json.Marshal(currentRun)
		if err != nil {
			return wrap("encode patched workflow run", string(currentRun.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, workflowRunRecordKind, string(currentRun.ID), previousVersion,
			currentRun.Metadata, runPayload,
		); err != nil {
			return err
		}
		eventPayload, err := json.Marshal(struct {
			PatchID           domain.GraphPatchID         `json:"patchId"`
			DefinitionID      domain.WorkflowDefinitionID `json:"definitionId"`
			DefinitionVersion uint64                      `json:"definitionVersion"`
		}{
			PatchID: request.ID, DefinitionID: definitionRecord.ID,
			DefinitionVersion: definitionRecord.DefinitionVersion,
		})
		if err != nil {
			return wrap("encode graph patch event", string(request.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(currentRun.ID)},
			Type:      "workflow.graph.patched", Payload: eventPayload,
		})
		return err
	})
	return definitionRecord, patchRecord, err
}

func (store *Store) ExportWorkflowDefinition(
	ctx context.Context,
	id domain.WorkflowDefinitionID,
) (json.RawMessage, error) {
	record, err := store.WorkflowDefinition(ctx, id)
	if err != nil {
		return nil, err
	}
	if _, err := decodeResolvedDefinition(record); err != nil {
		return nil, err
	}
	return append(json.RawMessage(nil), record.ResolvedDocument...), nil
}

func (store *Store) CreateRestartPoint(
	ctx context.Context,
	request RestartPointRequest,
) (domain.RestartPoint, error) {
	if err := validateRestartPointRequest(request); err != nil {
		return domain.RestartPoint{}, err
	}
	var point domain.RestartPoint
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.restartPoint(ctx, request.ID); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "create", Resource: string(request.ID),
				Message: "restart point already exists",
			}
		}
		run, found, err := transaction.workflowRun(ctx, request.WorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "create", Resource: string(request.WorkflowRunID),
				Message: "workflow run does not exist",
			}
		}
		if err := transaction.validateRestartCursor(ctx, run.ID, request); err != nil {
			return err
		}
		if _, found, err := transaction.snapshot(ctx, request.SnapshotID); err != nil {
			return err
		} else if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "create", Resource: string(request.SnapshotID),
				Message: "restart snapshot does not exist",
			}
		}
		if request.NodeRunID != nil {
			node, found, err := transaction.nodeRun(ctx, *request.NodeRunID)
			if err != nil {
				return err
			}
			if !found || node.WorkflowRunID != run.ID {
				return &domain.Error{
					Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(*request.NodeRunID),
					Message: "restart node does not belong to the workflow run",
				}
			}
		}
		for _, admissionID := range request.AdmissionIDs {
			payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(admissionID))
			if err != nil {
				return err
			}
			if !found {
				return &domain.Error{
					Code: domain.ErrorCodeNotFound, Op: "create", Resource: string(admissionID),
					Message: "restart admission does not exist",
				}
			}
			var admission domain.Admission
			if err := json.Unmarshal(payload, &admission); err != nil {
				return wrap("decode restart admission", string(admissionID), err)
			}
			evidence, err := transaction.loadTaskContext(ctx, admission.TaskRecordID)
			if err != nil {
				return err
			}
			if evidence.node.WorkflowRunID != run.ID {
				return &domain.Error{
					Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(admissionID),
					Message: "restart admission belongs to a different workflow run",
				}
			}
			if _, current, err := transaction.currentAdmissionSnapshot(ctx, admissionID); err != nil {
				return err
			} else if !current {
				return staleReplayAdmission(admissionID)
			}
		}
		now := time.Now().UTC()
		point = domain.RestartPoint{
			Metadata: newRecordMetadata(now), ID: request.ID, Kind: request.Kind,
			WorkflowRunID: run.ID, WorkflowDefinitionID: run.WorkflowDefinition,
			DefinitionVersion: run.DefinitionVersion, EventCursor: request.EventCursor,
			SnapshotID: request.SnapshotID, NodeRunID: request.NodeRunID,
			AdmissionIDs:  append([]domain.AdmissionID(nil), request.AdmissionIDs...),
			CheckpointIDs: append([]domain.CheckpointID(nil), request.CheckpointIDs...),
		}
		encoded, err := json.Marshal(point)
		if err != nil {
			return wrap("encode restart point", string(point.ID), err)
		}
		owner := domain.ResourceReference{Kind: restartPointRecordKind, ID: string(point.ID)}
		referenceID := snapshotReferenceID(point.SnapshotID, owner)
		referencePayload, err := snapshotReferencePayload(point.SnapshotID, owner)
		if err != nil {
			return err
		}
		if err := transaction.reserveRecordBytes(
			ctx, uint64(len(encoded))+uint64(len(referencePayload)), 2,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, restartPointRecordKind, string(point.ID), point.Metadata, encoded,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, snapshotReferenceRecordKind, referenceID, newRecordMetadata(now), referencePayload,
		); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			RestartPointID domain.RestartPointID `json:"restartPointId"`
			EventCursor    domain.EventCursor    `json:"eventCursor"`
		}{RestartPointID: point.ID, EventCursor: point.EventCursor})
		if err != nil {
			return wrap("encode restart point event", string(point.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(run.ID)},
			Type:      "workflow.restart-point.created", Payload: payload,
		})
		return err
	})
	return point, err
}

func (store *Store) ReplayWorkflow(
	ctx context.Context,
	request ReplayRequest,
) (domain.WorkflowRun, domain.RunFork, error) {
	if err := validateReplayRequest(request); err != nil {
		return domain.WorkflowRun{}, domain.RunFork{}, err
	}
	var child domain.WorkflowRun
	var fork domain.RunFork
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, runForkRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "replay", Resource: string(request.ID),
				Message: "run fork already exists",
			}
		}
		if _, found, err := transaction.workflowRun(ctx, request.ChildWorkflowRunID); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "replay", Resource: string(request.ChildWorkflowRunID),
				Message: "child workflow run already exists",
			}
		}
		parent, found, err := transaction.workflowRun(ctx, request.ParentWorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "replay", Resource: string(request.ParentWorkflowRunID),
				Message: "parent workflow run does not exist",
			}
		}
		if parent.Metadata.ResourceVersion != request.ExpectedParentVersion {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "replay", Resource: string(parent.ID),
				Message: "parent workflow run version changed",
			}
		}
		point, found, err := transaction.restartPoint(ctx, request.RestartPointID)
		if err != nil {
			return err
		}
		if !found || point.WorkflowRunID != parent.ID {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "replay", Resource: string(request.RestartPointID),
				Message: "restart point does not belong to the parent run",
			}
		}
		if !admissionsAreReusable(request.ReusedAdmissionIDs, point.AdmissionIDs) {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "replay", Resource: string(request.ID),
				Message: "reused admission is absent from the restart point",
			}
		}
		target, found, err := transaction.workflowDefinition(ctx, request.TargetDefinitionID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "replay", Resource: string(request.TargetDefinitionID),
				Message: "target workflow definition does not exist",
			}
		}
		if target.DefinitionVersion != request.TargetDefinitionVersion {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "replay", Resource: string(target.ID),
				Message: "target workflow definition version changed",
			}
		}
		definition, err := decodeResolvedDefinition(target)
		if err != nil {
			return err
		}
		reused, err := transaction.reusableAdmissions(
			ctx, request.ReusedAdmissionIDs, definition, request.EnvironmentIDs,
		)
		if err != nil && request.EnvironmentIDs == nil && len(request.ReusedAdmissionIDs) != 0 {
			environmentIDs, identityErr := transaction.replayEnvironmentIDs(ctx, request.ReusedAdmissionIDs)
			if identityErr != nil {
				return identityErr
			}
			reused, err = transaction.reusableAdmissions(
				ctx, request.ReusedAdmissionIDs, definition, environmentIDs,
			)
		}
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		var nodes []domain.NodeRun
		child, nodes, err = newWorkflowRunRecords(
			store, request.ChildWorkflowRunID, target, definition, nil, now,
		)
		if err != nil {
			return err
		}
		if err := applyReusedAdmissions(nodes, reused, definition); err != nil {
			return err
		}
		seedRestartSnapshot(nodes, point.SnapshotID)
		childPayload, err := json.Marshal(child)
		if err != nil {
			return wrap("encode child workflow run", string(child.ID), err)
		}
		fork = domain.RunFork{
			Metadata: newRecordMetadata(now), ID: request.ID,
			ParentWorkflowRunID: parent.ID, ChildWorkflowRunID: child.ID,
			RestartPointID: point.ID, TargetWorkflowDefinitionID: target.ID,
			TargetDefinitionVersion: target.DefinitionVersion,
			ExpectedParentVersion:   request.ExpectedParentVersion,
			StartingSnapshotID:      point.SnapshotID,
			ReusedAdmissionIDs:      append([]domain.AdmissionID(nil), request.ReusedAdmissionIDs...),
			CommandID:               request.CommandID, Principal: request.Principal,
		}
		forkPayload, err := json.Marshal(fork)
		if err != nil {
			return wrap("encode run fork", string(fork.ID), err)
		}
		nodePayloads := make([][]byte, len(nodes))
		totalBytes := uint64(len(childPayload) + len(forkPayload))
		for index := range nodes {
			nodePayloads[index], err = json.Marshal(nodes[index])
			if err != nil {
				return wrap("encode child node run", string(nodes[index].ID), err)
			}
			totalBytes += uint64(len(nodePayloads[index]))
		}
		if err := transaction.reserveRecordBytes(ctx, totalBytes, uint64(len(nodes)+2)); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, workflowRunRecordKind, string(child.ID), child.Metadata, childPayload,
		); err != nil {
			return err
		}
		for index := range nodes {
			if err := transaction.putRecord(
				ctx, nodeRunRecordKind, string(nodes[index].ID), nodes[index].Metadata, nodePayloads[index],
			); err != nil {
				return err
			}
		}
		if err := transaction.putRecord(
			ctx, runForkRecordKind, string(fork.ID), fork.Metadata, forkPayload,
		); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			ForkID   domain.RunForkID     `json:"forkId"`
			ParentID domain.WorkflowRunID `json:"parentWorkflowRunId"`
		}{ForkID: fork.ID, ParentID: parent.ID})
		if err != nil {
			return wrap("encode run fork event", string(fork.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(child.ID)},
			Type:      "workflow.run.forked", Payload: payload,
		})
		return err
	})
	return child, fork, err
}

func (transaction *Tx) replayEnvironmentIDs(
	ctx context.Context,
	ids []domain.AdmissionID,
) (map[string]string, error) {
	identities := make(map[string]string)
	for _, id := range ids {
		payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(id))
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, staleReplayAdmission(id)
		}
		var admission domain.Admission
		if err := json.Unmarshal(payload, &admission); err != nil {
			return nil, wrap("decode replay admission", string(id), err)
		}
		evidence, err := transaction.loadTaskContext(ctx, admission.TaskRecordID)
		if err != nil {
			return nil, err
		}
		validations, err := transaction.validations(ctx, admission.ValidationIDs)
		if err != nil {
			return nil, err
		}
		for _, validation := range validations {
			definition, found := verificationByKey(evidence.template.Verification, validation.Key)
			if !found {
				return nil, staleReplayAdmission(id)
			}
			if current, found := identities[definition.Environment]; found && current != validation.EnvironmentID {
				return nil, staleReplayAdmission(id)
			}
			identities[definition.Environment] = validation.EnvironmentID
		}
	}
	return identities, nil
}

func seedRestartSnapshot(nodes []domain.NodeRun, snapshotID domain.SnapshotID) {
	for index := range nodes {
		if nodes[index].State == domain.NodeRunStateReady && len(nodes[index].InputSnapshotIDs) == 0 {
			nodes[index].InputSnapshotIDs = []domain.SnapshotID{snapshotID}
		}
	}
}

type reusableAdmission struct {
	ID               domain.AdmissionID
	NodeKey          domain.NodeKey
	TaskResultID     domain.TaskResultID
	SnapshotID       domain.SnapshotID
	InputSnapshotIDs []domain.SnapshotID
}

func (transaction *Tx) reusableAdmissions(
	ctx context.Context,
	ids []domain.AdmissionID,
	target workflowmodel.Definition,
	environmentIDs map[string]string,
) ([]reusableAdmission, error) {
	reused := make([]reusableAdmission, 0, len(ids))
	seenNodes := make(map[domain.NodeKey]struct{}, len(ids))
	for _, id := range ids {
		payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(id))
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "reuse admission", Resource: string(id),
				Message: "admission does not exist",
			}
		}
		var admission domain.Admission
		if err := json.Unmarshal(payload, &admission); err != nil {
			return nil, wrap("decode reused admission", string(id), err)
		}
		if admission.State != domain.AdmissionStateAdmitted {
			return nil, staleReplayAdmission(id)
		}
		evidence, err := transaction.loadTaskContext(ctx, admission.TaskRecordID)
		if err != nil {
			return nil, err
		}
		validations, err := transaction.validations(ctx, admission.ValidationIDs)
		if err != nil {
			return nil, err
		}
		current, err := admissionMatchesEnvironment(evidence, validations, admission, environmentIDs)
		if err != nil {
			return nil, err
		}
		if !current {
			return nil, staleReplayAdmission(id)
		}
		targetNode, found := target.Nodes[evidence.node.NodeKey]
		if !found {
			return nil, staleReplayAdmission(id)
		}
		targetTemplate := target.Templates[targetNode.Template]
		targetDigest, err := nodeDefinitionDigest(targetNode, targetTemplate)
		if err != nil {
			return nil, err
		}
		if targetDigest != evidence.node.NodeDefinitionDigest ||
			targetTemplate.OutputSchemaDigest != evidence.result.SchemaDigest {
			return nil, staleReplayAdmission(id)
		}
		if _, found := seenNodes[evidence.node.NodeKey]; found {
			return nil, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "reuse admission", Resource: string(id),
				Message: "reused admissions target the same node",
			}
		}
		seenNodes[evidence.node.NodeKey] = struct{}{}
		reused = append(reused, reusableAdmission{
			ID: id, NodeKey: evidence.node.NodeKey, TaskResultID: evidence.result.ID,
			SnapshotID:       evidence.snapshot.ID,
			InputSnapshotIDs: append([]domain.SnapshotID(nil), evidence.node.InputSnapshotIDs...),
		})
	}
	if err := validateReusableAdmissionTopology(reused, seenNodes, target); err != nil {
		return nil, err
	}
	return reused, nil
}

func validateReusableAdmissionTopology(
	reused []reusableAdmission,
	seenNodes map[domain.NodeKey]struct{},
	target workflowmodel.Definition,
) error {
	for _, admission := range reused {
		for _, edge := range target.Edges {
			if edge.To != admission.NodeKey || !edge.Required || isBackEdge(target.Loops, edge.ID) {
				continue
			}
			if _, found := seenNodes[edge.From]; !found {
				return staleReplayAdmission(admission.ID)
			}
		}
	}
	return nil
}

func applyReusedAdmissions(
	nodes []domain.NodeRun,
	reused []reusableAdmission,
	definition workflowmodel.Definition,
) error {
	byKey := make(map[domain.NodeKey]*domain.NodeRun, len(nodes))
	for index := range nodes {
		byKey[nodes[index].NodeKey] = &nodes[index]
	}
	reusedSnapshots := make(map[domain.NodeKey]domain.SnapshotID, len(reused))
	for _, admission := range reused {
		node, found := byKey[admission.NodeKey]
		if !found {
			return staleReplayAdmission(admission.ID)
		}
		node.State = domain.NodeRunStateSucceeded
		node.AdmissionID = &admission.ID
		node.TaskResultID = &admission.TaskResultID
		node.InputSnapshotIDs = append([]domain.SnapshotID(nil), admission.InputSnapshotIDs...)
		reusedSnapshots[admission.NodeKey] = admission.SnapshotID
	}
	for index := range nodes {
		node := &nodes[index]
		if node.State != domain.NodeRunStatePending {
			continue
		}
		ready := true
		snapshots := make(map[domain.SnapshotID]struct{})
		for _, edge := range definition.Edges {
			if edge.To != node.NodeKey || isBackEdge(definition.Loops, edge.ID) {
				continue
			}
			upstream := byKey[edge.From]
			if upstream == nil || upstream.State != domain.NodeRunStateSucceeded || upstream.AdmissionID == nil {
				if edge.Required {
					ready = false
				}
				continue
			}
			if snapshotID, found := reusedSnapshots[edge.From]; found {
				snapshots[snapshotID] = struct{}{}
			}
		}
		if !ready {
			continue
		}
		node.State = domain.NodeRunStateReady
		node.InputSnapshotIDs = make([]domain.SnapshotID, 0, len(snapshots))
		for snapshotID := range snapshots {
			node.InputSnapshotIDs = append(node.InputSnapshotIDs, snapshotID)
		}
		sort.Slice(node.InputSnapshotIDs, func(first int, second int) bool {
			return node.InputSnapshotIDs[first] < node.InputSnapshotIDs[second]
		})
	}
	return nil
}

func staleReplayAdmission(id domain.AdmissionID) error {
	return &domain.Error{
		Code: domain.ErrorCodeConflict, Op: "reuse admission", Resource: string(id),
		Message: "admission is stale or incompatible with the target definition",
	}
}

func (transaction *Tx) reconcilePatchedNodes(
	ctx context.Context,
	run domain.WorkflowRun,
	existing []domain.NodeRun,
	definition workflowmodel.Definition,
	definitionVersion uint64,
	affected map[domain.NodeKey]struct{},
	now time.Time,
) error {
	desired, err := initialNodeRuns(run.ID, definitionVersion, definition, now)
	if err != nil {
		return err
	}
	var desiredBytes uint64
	for _, node := range desired {
		encoded, err := json.Marshal(node)
		if err != nil {
			return wrap("encode patched node capacity", string(node.ID), err)
		}
		desiredBytes += uint64(len(encoded))
	}
	if err := transaction.reserveRecordBytes(ctx, desiredBytes, uint64(len(desired))); err != nil {
		return err
	}
	existingByKey := make(map[domain.NodeKey]domain.NodeRun, len(existing))
	for _, node := range existing {
		existingByKey[node.NodeKey] = node
	}
	desiredByKey := make(map[domain.NodeKey]struct{}, len(desired))
	for _, node := range desired {
		desiredByKey[node.NodeKey] = struct{}{}
		current, found := existingByKey[node.NodeKey]
		if !found {
			encoded, err := json.Marshal(node)
			if err != nil {
				return wrap("encode patched node run", string(node.ID), err)
			}
			if err := transaction.putRecord(ctx, nodeRunRecordKind, string(node.ID), node.Metadata, encoded); err != nil {
				return err
			}
			continue
		}
		if _, changed := affected[node.NodeKey]; !changed {
			continue
		}
		previousVersion := current.Metadata.ResourceVersion
		current.DefinitionVersion = definitionVersion
		current.NodeDefinitionDigest = node.NodeDefinitionDigest
		current.Adapter = node.Adapter
		current.State = node.State
		current.Metadata.ResourceVersion++
		current.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(current)
		if err != nil {
			return wrap("encode patched node run", string(current.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, nodeRunRecordKind, string(current.ID), previousVersion, current.Metadata, encoded,
		); err != nil {
			return err
		}
	}
	for _, node := range existing {
		if _, changed := affected[node.NodeKey]; !changed {
			continue
		}
		if _, retained := desiredByKey[node.NodeKey]; retained {
			continue
		}
		result, err := transaction.tx.ExecContext(
			ctx, "DELETE FROM records WHERE kind = ? AND id = ? AND resource_version = ?",
			nodeRunRecordKind, string(node.ID), node.Metadata.ResourceVersion,
		)
		if err != nil {
			return wrap("remove unstarted node run", string(node.ID), err)
		}
		rows, err := result.RowsAffected()
		if err != nil {
			return wrap("count removed node run", string(node.ID), err)
		}
		if rows != 1 {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(node.ID),
				Message: "node run version changed",
			}
		}
	}
	return nil
}

func (transaction *Tx) restartPoint(
	ctx context.Context,
	id domain.RestartPointID,
) (domain.RestartPoint, bool, error) {
	var point domain.RestartPoint
	payload, found, err := transaction.recordPayload(ctx, restartPointRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &point)
		if err != nil {
			err = wrap("decode restart point", string(id), err)
		}
	}
	return point, found, err
}

func (store *Store) RestartPoints(
	ctx context.Context,
	runID domain.WorkflowRunID,
) ([]domain.RestartPoint, error) {
	if err := runID.Validate(); err != nil {
		return nil, err
	}
	var points []domain.RestartPoint
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		points, err = typedRecords[domain.RestartPoint](transaction, ctx, restartPointRecordKind)
		return err
	})
	if err != nil {
		return nil, err
	}
	matching := points[:0]
	for _, point := range points {
		if point.WorkflowRunID == runID {
			matching = append(matching, point)
		}
	}
	sort.Slice(matching, func(first int, second int) bool {
		return matching[first].EventCursor > matching[second].EventCursor
	})
	return matching, nil
}

func (store *Store) WorkflowForks(
	ctx context.Context,
	runID domain.WorkflowRunID,
) ([]domain.RunFork, error) {
	if err := runID.Validate(); err != nil {
		return nil, err
	}
	var forks []domain.RunFork
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var err error
		forks, err = typedRecords[domain.RunFork](transaction, ctx, runForkRecordKind)
		return err
	})
	if err != nil {
		return nil, err
	}
	matching := forks[:0]
	for _, fork := range forks {
		if fork.ParentWorkflowRunID == runID || fork.ChildWorkflowRunID == runID {
			matching = append(matching, fork)
		}
	}
	sort.Slice(matching, func(first int, second int) bool {
		return matching[first].Metadata.UpdatedAt.After(matching[second].Metadata.UpdatedAt)
	})
	return matching, nil
}

func (transaction *Tx) nodeRun(
	ctx context.Context,
	id domain.NodeRunID,
) (domain.NodeRun, bool, error) {
	var node domain.NodeRun
	payload, found, err := transaction.recordPayload(ctx, nodeRunRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &node)
		if err != nil {
			err = wrap("decode node run", string(id), err)
		}
	}
	return node, found, err
}

func (transaction *Tx) earliestRestartPoint(
	ctx context.Context,
	runID domain.WorkflowRunID,
) (domain.RestartPointID, bool, error) {
	rows, err := transaction.tx.QueryContext(
		ctx, "SELECT payload FROM records WHERE kind = ? ORDER BY id", restartPointRecordKind,
	)
	if err != nil {
		return "", false, wrap("read restart points", string(runID), err)
	}
	defer rows.Close()
	var points []domain.RestartPoint
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return "", false, wrap("scan restart point", string(runID), err)
		}
		var point domain.RestartPoint
		if err := json.Unmarshal(payload, &point); err != nil {
			return "", false, wrap("decode restart point", string(runID), err)
		}
		if point.WorkflowRunID == runID {
			points = append(points, point)
		}
	}
	if err := rows.Err(); err != nil {
		return "", false, wrap("iterate restart points", string(runID), err)
	}
	if len(points) == 0 {
		return "", false, nil
	}
	sort.Slice(points, func(first int, second int) bool {
		return points[first].EventCursor < points[second].EventCursor
	})
	return points[0].ID, true, nil
}

func (transaction *Tx) validateRestartCursor(
	ctx context.Context,
	runID domain.WorkflowRunID,
	request RestartPointRequest,
) error {
	var aggregateKind string
	var aggregateID string
	err := transaction.tx.QueryRowContext(
		ctx,
		"SELECT aggregate_kind, aggregate_id FROM events WHERE cursor = ?",
		request.EventCursor,
	).Scan(&aggregateKind, &aggregateID)
	if errors.Is(err, sql.ErrNoRows) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: fmt.Sprint(request.EventCursor),
			Message: "restart event cursor does not exist",
		}
	}
	if err != nil {
		return wrap("read restart event cursor", fmt.Sprint(request.EventCursor), err)
	}
	valid := aggregateKind == workflowRunRecordKind && aggregateID == string(runID)
	if request.Kind == domain.RestartPointNodeAdmission && request.NodeRunID != nil {
		valid = valid || aggregateKind == nodeRunRecordKind && aggregateID == string(*request.NodeRunID)
	}
	if !valid {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: fmt.Sprint(request.EventCursor),
			Message: "restart event cursor does not belong to the workflow run",
		}
	}
	return nil
}

func newWorkflowRunRecords(
	store *Store,
	id domain.WorkflowRunID,
	definitionRecord domain.WorkflowDefinition,
	definition workflowmodel.Definition,
	orchestrationSession *domain.SessionID,
	now time.Time,
) (domain.WorkflowRun, []domain.NodeRun, error) {
	budgets := store.budgets
	budgets.MaxConcurrentNodes = minUint32(budgets.MaxConcurrentNodes, definition.Budgets.MaxConcurrentNodes)
	budgets.MaxConcurrentProcesses = minUint32(
		budgets.MaxConcurrentProcesses, definition.Budgets.MaxConcurrentProcesses,
	)
	budgets.MaxMaterializedSnapshots = minUint32(
		budgets.MaxMaterializedSnapshots, definition.Budgets.MaxMaterializedSnapshots,
	)
	budgets.MaxSnapshotBytes = minUint64(budgets.MaxSnapshotBytes, definition.Budgets.MaxSnapshotBytes)
	budgets.MaxVerificationSeconds = minUint32(
		budgets.MaxVerificationSeconds, definition.Budgets.MaxVerificationSeconds,
	)
	run := domain.WorkflowRun{
		Metadata: newRecordMetadata(now), ID: id, WorkflowDefinition: definitionRecord.ID,
		DefinitionVersion: definitionRecord.DefinitionVersion,
		State:             domain.WorkflowRunStatePending, OrchestrationSession: orchestrationSession,
		Budgets: budgets,
	}
	nodes, err := initialNodeRuns(id, definitionRecord.DefinitionVersion, definition, now)
	return run, nodes, err
}

func newRecordMetadata(now time.Time) domain.RecordMetadata {
	return domain.RecordMetadata{
		SchemaVersion: domain.CurrentRecordSchemaVersion, ResourceVersion: 1,
		CreatedAt: now, UpdatedAt: now,
	}
}

func validateGraphPatchRequest(request GraphPatchRequest) error {
	for _, validation := range []error{
		request.ID.Validate(), request.RunID.Validate(), request.ResultDefinitionID.Validate(), request.CommandID.Validate(),
	} {
		if validation != nil {
			return validation
		}
	}
	if request.ExpectedDefinitionVersion == 0 || len(request.Operations) == 0 {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "patch", Resource: string(request.ID),
			Message: "expected definition version and operations are required",
		}
	}
	return nil
}

func validateRestartPointRequest(request RestartPointRequest) error {
	for _, validation := range []error{
		request.ID.Validate(), request.WorkflowRunID.Validate(), request.SnapshotID.Validate(),
	} {
		if validation != nil {
			return validation
		}
	}
	if !request.Kind.Valid() || request.EventCursor == 0 {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(request.ID),
			Message: "restart point kind and event cursor are required",
		}
	}
	if request.Kind == domain.RestartPointNodeAdmission && request.NodeRunID == nil {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(request.ID),
			Message: "node admission restart point requires a node run",
		}
	}
	if request.Kind == domain.RestartPointOrchestrationCheckpoint && len(request.CheckpointIDs) == 0 {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(request.ID),
			Message: "orchestration restart point requires a checkpoint",
		}
	}
	if request.NodeRunID != nil {
		if err := request.NodeRunID.Validate(); err != nil {
			return err
		}
	}
	for _, id := range request.AdmissionIDs {
		if err := id.Validate(); err != nil {
			return err
		}
	}
	if !uniqueAdmissionIDs(request.AdmissionIDs) || !uniqueCheckpointIDs(request.CheckpointIDs) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "create", Resource: string(request.ID),
			Message: "restart point identifiers must be unique",
		}
	}
	for _, id := range request.CheckpointIDs {
		if err := id.Validate(); err != nil {
			return err
		}
	}
	return nil
}

func validateReplayRequest(request ReplayRequest) error {
	for _, validation := range []error{
		request.ID.Validate(), request.ParentWorkflowRunID.Validate(), request.ChildWorkflowRunID.Validate(),
		request.RestartPointID.Validate(), request.TargetDefinitionID.Validate(), request.CommandID.Validate(),
	} {
		if validation != nil {
			return validation
		}
	}
	if request.ExpectedParentVersion == 0 || request.TargetDefinitionVersion == 0 || request.Principal == "" ||
		request.ParentWorkflowRunID == request.ChildWorkflowRunID {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "replay", Resource: string(request.ID),
			Message: "expected parent version, distinct child run, and principal are required",
		}
	}
	for _, id := range request.ReusedAdmissionIDs {
		if err := id.Validate(); err != nil {
			return err
		}
	}
	if !uniqueAdmissionIDs(request.ReusedAdmissionIDs) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "replay", Resource: string(request.ID),
			Message: "reused admission identifiers must be unique",
		}
	}
	return nil
}

func patchVersionConflict(request GraphPatchRequest, run domain.WorkflowRun) error {
	return &domain.Error{
		Code: domain.ErrorCodeConflict, Op: "patch", Resource: string(request.RunID),
		Message: fmt.Sprintf("workflow definition version is %d", run.DefinitionVersion),
		Details: map[string]string{
			"expectedDefinitionVersion": fmt.Sprintf("%d", request.ExpectedDefinitionVersion),
			"currentDefinitionVersion":  fmt.Sprintf("%d", run.DefinitionVersion),
		},
	}
}

func nodeHasStarted(node domain.NodeRun) bool {
	return node.Attempt > 0 || (node.State != domain.NodeRunStatePending && node.State != domain.NodeRunStateReady)
}

func workflowRunIsTerminal(state domain.WorkflowRunState) bool {
	switch state {
	case domain.WorkflowRunStateSucceeded, domain.WorkflowRunStateFailed,
		domain.WorkflowRunStateCancelled, domain.WorkflowRunStateCapped:
		return true
	default:
		return false
	}
}

func admissionsAreReusable(reused []domain.AdmissionID, available []domain.AdmissionID) bool {
	set := make(map[domain.AdmissionID]struct{}, len(available))
	for _, id := range available {
		set[id] = struct{}{}
	}
	for _, id := range reused {
		if _, found := set[id]; !found {
			return false
		}
	}
	return true
}

func uniqueAdmissionIDs(ids []domain.AdmissionID) bool {
	seen := make(map[domain.AdmissionID]struct{}, len(ids))
	for _, id := range ids {
		if _, found := seen[id]; found {
			return false
		}
		seen[id] = struct{}{}
	}
	return true
}

func uniqueCheckpointIDs(ids []domain.CheckpointID) bool {
	seen := make(map[domain.CheckpointID]struct{}, len(ids))
	for _, id := range ids {
		if _, found := seen[id]; found {
			return false
		}
		seen[id] = struct{}{}
	}
	return true
}
