package sqlite

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"sort"
	"time"
	"unicode/utf8"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	resultmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/result"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	taskResultRecordKind = "task-result"
	taskRecordRecordKind = "task-record"
	validationRecordKind = "validation"
	admissionRecordKind  = "admission"
)

type TaskResultRequest struct {
	ID           domain.TaskResultID `json:"id"`
	NodeRunID    domain.NodeRunID    `json:"nodeRunId"`
	SchemaDigest string              `json:"schemaDigest"`
	Value        json.RawMessage     `json:"value"`
	ArtifactIDs  []domain.ArtifactID `json:"artifactIds"`
}

type TaskResultSubmission struct {
	Result   *domain.TaskResult   `json:"result,omitempty"`
	Decision resultmodel.Decision `json:"decision"`
}

type TaskRecordRequest struct {
	ID           domain.TaskRecordID `json:"id"`
	TaskResultID domain.TaskResultID `json:"taskResultId"`
	SnapshotID   domain.SnapshotID   `json:"snapshotId"`
}

type ValidationRequest struct {
	ID            domain.ValidationID    `json:"id"`
	TaskRecordID  domain.TaskRecordID    `json:"taskRecordId"`
	Key           string                 `json:"key"`
	State         domain.ValidationState `json:"state"`
	Authority     domain.Authority       `json:"authority"`
	EnvironmentID string                 `json:"environmentId"`
	ArtifactID    *domain.ArtifactID     `json:"artifactId,omitempty"`
	ExitCode      *int                   `json:"exitCode,omitempty"`
	LogArtifactID *domain.ArtifactID     `json:"logArtifactId,omitempty"`
}

type AdmissionRequest struct {
	ID            domain.AdmissionID    `json:"id"`
	TaskRecordID  domain.TaskRecordID   `json:"taskRecordId"`
	ValidationIDs []domain.ValidationID `json:"validationIds"`
}

type AdmissionFreshnessRequest struct {
	ID             domain.AdmissionID `json:"id"`
	EnvironmentIDs map[string]string  `json:"environmentIds"`
}

func (store *Store) SubmitTaskResult(
	ctx context.Context,
	request TaskResultRequest,
) (TaskResultSubmission, error) {
	if err := validateTaskResultRequest(request); err != nil {
		return TaskResultSubmission{}, err
	}
	var submission TaskResultSubmission
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, taskResultRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "submit", Resource: string(request.ID),
				Message: "task result already exists",
			}
		}
		node, found, err := transaction.nodeRun(ctx, request.NodeRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "submit", Resource: string(request.NodeRunID),
				Message: "node run does not exist",
			}
		}
		if node.State != domain.NodeRunStateRunning &&
			(node.State != domain.NodeRunStateWaiting || node.TaskResultID != nil) {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "submit", Resource: string(node.ID),
				Message: "node run is not accepting a task result",
			}
		}
		run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "submit", Resource: string(node.ID),
				Message: "node workflow run is unavailable",
			}
		}
		definitionVersion := node.DefinitionVersion
		if definitionVersion == 0 {
			definitionVersion = run.DefinitionVersion
		}
		definitionRecord, err := transaction.workflowDefinitionAtVersion(
			ctx, run.WorkflowDefinition, definitionVersion,
		)
		if err != nil {
			return err
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		nodeDefinition, found := definition.Nodes[node.NodeKey]
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "submit", Resource: string(node.ID),
				Message: "pinned node definition is unavailable",
			}
		}
		template := definition.Templates[nodeDefinition.Template]
		if request.SchemaDigest != template.OutputSchemaDigest {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "submit", Resource: string(request.ID),
				Message: "task result schema digest does not match the pinned node",
			}
		}
		validator, err := resultmodel.NewValidator(
			template.OutputSchema, template.OutputSchemaDigest,
			template.MaxRepairAttempts, store.budgets.MaxEventBytes,
		)
		if err != nil {
			return err
		}
		submission.Decision = validator.Validate(request.Value, node.RepairAttempt)
		now := time.Now().UTC()
		if !submission.Decision.Accepted {
			previousVersion := node.Metadata.ResourceVersion
			node.RepairAttempt = submission.Decision.RepairsUsed
			if submission.Decision.RepairAllowed {
				node.State = domain.NodeRunStateWaiting
			} else {
				node.State = domain.NodeRunStateFailed
			}
			node.Metadata.ResourceVersion++
			node.Metadata.UpdatedAt = now
			encoded, err := json.Marshal(node)
			if err != nil {
				return wrap("encode task result rejection", string(node.ID), err)
			}
			if err := transaction.updateRecord(
				ctx, nodeRunRecordKind, string(node.ID), previousVersion, node.Metadata, encoded,
			); err != nil {
				return err
			}
			eventType := "workflow.task-result.repair-requested"
			if submission.Decision.Exhausted {
				eventType = "workflow.task-result.rejected"
			}
			payload, err := json.Marshal(struct {
				TaskResultID domain.TaskResultID  `json:"taskResultId"`
				Decision     resultmodel.Decision `json:"decision"`
			}{TaskResultID: request.ID, Decision: submission.Decision})
			if err != nil {
				return wrap("encode task result rejection event", string(request.ID), err)
			}
			_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
				SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
				Aggregate: domain.ResourceReference{Kind: nodeRunRecordKind, ID: string(node.ID)},
				Type:      eventType, Payload: payload,
			})
			return err
		}
		result := domain.TaskResult{
			Metadata: newRecordMetadata(now), ID: request.ID, NodeRunID: node.ID,
			SchemaDigest: request.SchemaDigest,
			Value:        append(json.RawMessage(nil), request.Value...),
			ArtifactIDs:  append([]domain.ArtifactID(nil), request.ArtifactIDs...),
		}
		encodedResult, err := json.Marshal(result)
		if err != nil {
			return wrap("encode task result", string(result.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encodedResult); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, taskResultRecordKind, string(result.ID), result.Metadata, encodedResult,
		); err != nil {
			return err
		}
		previousVersion := node.Metadata.ResourceVersion
		node.State = domain.NodeRunStateWaiting
		node.TaskResultID = &result.ID
		node.Metadata.ResourceVersion++
		node.Metadata.UpdatedAt = now
		encodedNode, err := json.Marshal(node)
		if err != nil {
			return wrap("encode accepted task result node", string(node.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, nodeRunRecordKind, string(node.ID), previousVersion, node.Metadata, encodedNode,
		); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			TaskResultID domain.TaskResultID `json:"taskResultId"`
			SchemaDigest string              `json:"schemaDigest"`
		}{TaskResultID: result.ID, SchemaDigest: result.SchemaDigest})
		if err != nil {
			return wrap("encode accepted task result event", string(result.ID), err)
		}
		if _, err := transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: nodeRunRecordKind, ID: string(node.ID)},
			Type:      "workflow.task-result.accepted", Payload: payload,
		}); err != nil {
			return err
		}
		submission.Result = &result
		return nil
	})
	return submission, err
}

func (transaction *Tx) workflowDefinitionAtVersion(
	ctx context.Context,
	currentID domain.WorkflowDefinitionID,
	version uint64,
) (domain.WorkflowDefinition, error) {
	seen := make(map[domain.WorkflowDefinitionID]struct{})
	for currentID != "" {
		if _, found := seen[currentID]; found {
			return domain.WorkflowDefinition{}, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "read", Resource: string(currentID),
				Message: "workflow definition lineage contains a cycle",
			}
		}
		seen[currentID] = struct{}{}
		record, found, err := transaction.workflowDefinition(ctx, currentID)
		if err != nil {
			return domain.WorkflowDefinition{}, err
		}
		if !found {
			break
		}
		if record.DefinitionVersion == version {
			return record, nil
		}
		if record.PredecessorID == nil || record.DefinitionVersion < version {
			break
		}
		currentID = *record.PredecessorID
	}
	return domain.WorkflowDefinition{}, &domain.Error{
		Code: domain.ErrorCodeInternal, Op: "read", Resource: string(currentID),
		Message: "pinned workflow definition version is unavailable",
	}
}

func validateTaskResultRequest(request TaskResultRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.NodeRunID.Validate(); err != nil {
		return err
	}
	if request.SchemaDigest == "" {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "submit", Resource: string(request.ID),
			Message: "task result schema digest is empty",
		}
	}
	seen := make(map[domain.ArtifactID]struct{}, len(request.ArtifactIDs))
	for _, id := range request.ArtifactIDs {
		if err := id.Validate(); err != nil {
			return err
		}
		if _, found := seen[id]; found {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "submit", Resource: string(request.ID),
				Message: "task result artifact identifiers must be unique",
			}
		}
		seen[id] = struct{}{}
	}
	return nil
}

func (store *Store) CreateTaskRecord(
	ctx context.Context,
	request TaskRecordRequest,
) (domain.TaskRecord, error) {
	if err := validateTaskRecordRequest(request); err != nil {
		return domain.TaskRecord{}, err
	}
	var created domain.TaskRecord
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, taskRecordRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "create task record", Resource: string(request.ID),
				Message: "task record already exists",
			}
		}
		result, found, err := transaction.taskResult(ctx, request.TaskResultID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "create task record", Resource: string(request.TaskResultID),
				Message: "task result does not exist",
			}
		}
		node, found, err := transaction.nodeRun(ctx, result.NodeRunID)
		if err != nil {
			return err
		}
		if !found || node.TaskResultID == nil || *node.TaskResultID != result.ID || node.State != domain.NodeRunStateWaiting {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "create task record", Resource: string(result.NodeRunID),
				Message: "node run is not waiting for evidence for this result",
			}
		}
		snapshot, found, err := transaction.snapshot(ctx, request.SnapshotID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "create task record", Resource: string(request.SnapshotID),
				Message: "workspace snapshot does not exist",
			}
		}
		artifacts, err := transaction.taskArtifacts(ctx, result, snapshot)
		if err != nil {
			return err
		}
		inputDigest, err := taskInputDigest(node, result, snapshot, artifacts)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		created = domain.TaskRecord{
			Metadata: newRecordMetadata(now), ID: request.ID, TaskResultID: result.ID,
			SnapshotID: snapshot.ID, InputDigest: inputDigest,
		}
		encoded, err := json.Marshal(created)
		if err != nil {
			return wrap("encode task record", string(created.ID), err)
		}
		owner := domain.ResourceReference{Kind: taskRecordRecordKind, ID: string(created.ID)}
		referenceID := snapshotReferenceID(snapshot.ID, owner)
		referencePayload, err := snapshotReferencePayload(snapshot.ID, owner)
		if err != nil {
			return err
		}
		if err := transaction.reserveRecordBytes(
			ctx, uint64(len(encoded))+uint64(len(referencePayload)), 2,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, taskRecordRecordKind, string(created.ID), created.Metadata, encoded,
		); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, snapshotReferenceRecordKind, referenceID, newRecordMetadata(now), referencePayload,
		); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			TaskRecordID domain.TaskRecordID `json:"taskRecordId"`
			InputDigest  string              `json:"inputDigest"`
		}{TaskRecordID: created.ID, InputDigest: created.InputDigest})
		if err != nil {
			return wrap("encode task record event", string(created.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: taskRecordRecordKind, ID: string(created.ID)},
			Type:      "workflow.task-record.created", Payload: payload,
		})
		return err
	})
	return created, err
}

func (store *Store) RecordValidation(
	ctx context.Context,
	request ValidationRequest,
) (domain.Validation, error) {
	if err := validateValidationRequest(request); err != nil {
		return domain.Validation{}, err
	}
	var created domain.Validation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, validationRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "record validation", Resource: string(request.ID),
				Message: "validation already exists",
			}
		}
		context, err := transaction.loadTaskContext(ctx, request.TaskRecordID)
		if err != nil {
			return err
		}
		definition, found := verificationByKey(context.template.Verification, request.Key)
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: request.Key,
				Message: "validation key is absent from the pinned stage template",
			}
		}
		definitionDigest, err := verificationDefinitionDigest(definition)
		if err != nil {
			return err
		}
		if request.ArtifactID != nil {
			if !containsArtifactID(context.result.ArtifactIDs, *request.ArtifactID) {
				return &domain.Error{
					Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: string(*request.ArtifactID),
					Message: "validation artifact is absent from the task result",
				}
			}
			if _, err := transaction.taskArtifact(ctx, *request.ArtifactID, context.snapshot.ID); err != nil {
				return err
			}
		}
		if request.LogArtifactID != nil {
			if _, err := transaction.taskArtifact(ctx, *request.LogArtifactID, context.snapshot.ID); err != nil {
				return err
			}
		}
		now := time.Now().UTC()
		created = domain.Validation{
			Metadata: newRecordMetadata(now), ID: request.ID, TaskRecordID: context.task.ID,
			Key: request.Key, ArtifactID: request.ArtifactID, State: request.State,
			Authority: request.Authority, InputDigest: context.task.InputDigest,
			DefinitionDigest: definitionDigest, EnvironmentID: request.EnvironmentID,
			ExitCode: request.ExitCode, LogArtifactID: request.LogArtifactID,
		}
		encoded, err := json.Marshal(created)
		if err != nil {
			return wrap("encode validation", string(created.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, validationRecordKind, string(created.ID), created.Metadata, encoded,
		); err != nil {
			return err
		}
		payload, err := json.Marshal(struct {
			ValidationID domain.ValidationID    `json:"validationId"`
			State        domain.ValidationState `json:"state"`
		}{ValidationID: created.ID, State: created.State})
		if err != nil {
			return wrap("encode validation event", string(created.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: validationRecordKind, ID: string(created.ID)},
			Type:      "workflow.validation.recorded", Payload: payload,
		})
		return err
	})
	return created, err
}

func (store *Store) DecideAdmission(
	ctx context.Context,
	request AdmissionRequest,
) (domain.Admission, error) {
	if err := validateAdmissionRequest(request); err != nil {
		return domain.Admission{}, err
	}
	var created domain.Admission
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "decide admission", Resource: string(request.ID),
				Message: "admission already exists",
			}
		}
		context, err := transaction.loadTaskContext(ctx, request.TaskRecordID)
		if err != nil {
			return err
		}
		if context.node.State != domain.NodeRunStateWaiting || context.node.TaskResultID == nil ||
			*context.node.TaskResultID != context.result.ID {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "decide admission", Resource: string(context.node.ID),
				Message: "node run is not waiting for admission",
			}
		}
		validations, err := transaction.validations(ctx, request.ValidationIDs)
		if err != nil {
			return err
		}
		state, err := admissionState(context, validations)
		if err != nil {
			return err
		}
		boundDigest, err := admissionBoundDigest(context.task, validations)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		created = domain.Admission{
			Metadata: newRecordMetadata(now), ID: request.ID, TaskRecordID: context.task.ID,
			State: state, BoundDigest: boundDigest,
			ValidationIDs: append([]domain.ValidationID(nil), request.ValidationIDs...),
		}
		sort.Slice(created.ValidationIDs, func(first int, second int) bool {
			return created.ValidationIDs[first] < created.ValidationIDs[second]
		})
		encoded, err := json.Marshal(created)
		if err != nil {
			return wrap("encode admission", string(created.ID), err)
		}
		var referencePayload []byte
		var referenceID string
		if state == domain.AdmissionStateAdmitted {
			owner := domain.ResourceReference{Kind: admissionRecordKind, ID: string(created.ID)}
			referenceID = snapshotReferenceID(context.snapshot.ID, owner)
			referencePayload, err = snapshotReferencePayload(context.snapshot.ID, owner)
			if err != nil {
				return err
			}
		}
		totalBytes := uint64(len(encoded)) + uint64(len(referencePayload))
		records := uint64(1)
		if len(referencePayload) != 0 {
			records++
		}
		if err := transaction.reserveRecordBytes(ctx, totalBytes, records); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, admissionRecordKind, string(created.ID), created.Metadata, encoded,
		); err != nil {
			return err
		}
		if len(referencePayload) != 0 {
			if err := transaction.putRecord(
				ctx, snapshotReferenceRecordKind, referenceID, newRecordMetadata(now), referencePayload,
			); err != nil {
				return err
			}
		}
		previousVersion := context.node.Metadata.ResourceVersion
		context.node.AdmissionID = &created.ID
		if state == domain.AdmissionStateAdmitted {
			context.node.State = domain.NodeRunStateSucceeded
		}
		context.node.Metadata.ResourceVersion++
		context.node.Metadata.UpdatedAt = now
		encodedNode, err := json.Marshal(context.node)
		if err != nil {
			return wrap("encode admitted node", string(context.node.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, nodeRunRecordKind, string(context.node.ID), previousVersion, context.node.Metadata, encodedNode,
		); err != nil {
			return err
		}
		if state == domain.AdmissionStateAdmitted {
			handled, err := transaction.advanceLoopsAfterAdmission(
				ctx, context.node.WorkflowRunID, context.node.NodeKey, created.ID, context.definition, now,
			)
			if err != nil {
				return err
			}
			if !handled {
				if err := transaction.advanceDependentNodes(
					ctx, context.node.WorkflowRunID, context.definition, now,
				); err != nil {
					return err
				}
				if err := transaction.completeWorkflowRun(ctx, context.node.WorkflowRunID, now); err != nil {
					return err
				}
			}
		}
		payload, err := json.Marshal(struct {
			AdmissionID domain.AdmissionID    `json:"admissionId"`
			State       domain.AdmissionState `json:"state"`
			BoundDigest string                `json:"boundDigest"`
		}{AdmissionID: created.ID, State: created.State, BoundDigest: created.BoundDigest})
		if err != nil {
			return wrap("encode admission event", string(created.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: admissionRecordKind, ID: string(created.ID)},
			Type:      "workflow.admission.decided", Payload: payload,
		})
		return err
	})
	return created, err
}

func (transaction *Tx) advanceLoopsAfterAdmission(
	ctx context.Context,
	runID domain.WorkflowRunID,
	sourceKey domain.NodeKey,
	admissionID domain.AdmissionID,
	definition workflowmodel.Definition,
	now time.Time,
) (bool, error) {
	for _, loop := range definition.Loops {
		backEdge, found := workflowEdgeByID(definition.Edges, loop.BackEdge)
		if !found {
			return false, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "advance loop", Resource: loop.ID,
				Message: "loop back-edge is unavailable",
			}
		}
		if backEdge.From != sourceKey {
			continue
		}
		stopped, err := transaction.loopStopSatisfied(ctx, runID, loop, definition)
		if err != nil {
			return false, err
		}
		if stopped {
			continue
		}
		source, found, err := transaction.nodeRun(ctx, nodeRunID(runID, sourceKey))
		if err != nil {
			return false, err
		}
		if !found {
			return false, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "advance loop", Resource: string(sourceKey),
				Message: "loop source node is unavailable",
			}
		}
		stalled, err := transaction.loopOutputStalled(ctx, source.ID, loop.StallLimit)
		if err != nil {
			return false, err
		}
		if source.Attempt >= loop.IterationLimit || stalled {
			return true, transaction.capLoop(ctx, runID, loop, definition, stalled, now)
		}
		return true, transaction.restartLoop(ctx, runID, loop, definition, admissionID, now)
	}
	return false, nil
}

func (transaction *Tx) loopStopSatisfied(
	ctx context.Context,
	runID domain.WorkflowRunID,
	loop workflowmodel.Loop,
	definition workflowmodel.Definition,
) (bool, error) {
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return false, err
	}
	switch loop.Stop.Kind {
	case "validation":
		members := loopNodeKeys(definition, loop)
		for _, node := range nodes {
			if _, found := members[node.NodeKey]; !found || node.AdmissionID == nil {
				continue
			}
			admission, found, err := transaction.admission(ctx, *node.AdmissionID)
			if err != nil {
				return false, err
			}
			if !found {
				return false, &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "evaluate loop", Resource: string(*node.AdmissionID),
					Message: "loop admission is unavailable",
				}
			}
			validations, err := transaction.validations(ctx, admission.ValidationIDs)
			if err != nil {
				return false, err
			}
			for _, validation := range validations {
				if validation.Key == loop.Stop.Validation && validation.State == domain.ValidationStatePassed &&
					validation.Authority != domain.AuthorityAdvisory {
					return true, nil
				}
			}
		}
		return false, nil
	case "result_match":
		for _, node := range nodes {
			if node.NodeKey != loop.Stop.Node || node.TaskResultID == nil {
				continue
			}
			result, found, err := transaction.taskResult(ctx, *node.TaskResultID)
			if err != nil {
				return false, err
			}
			if !found {
				return false, &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "evaluate loop", Resource: string(*node.TaskResultID),
					Message: "loop task result is unavailable",
				}
			}
			value, found, err := jsonValueAtPath(result.Value, loop.Stop.Path)
			if err != nil || !found {
				return false, err
			}
			actualDigest, err := loopJSONValueDigest(value)
			if err != nil {
				return false, err
			}
			expectedDigest, err := loopJSONValueDigest(loop.Stop.Equals)
			if err != nil {
				return false, err
			}
			return actualDigest == expectedDigest, nil
		}
		return false, nil
	default:
		return false, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "evaluate loop", Resource: loop.ID,
			Message: "loop stop condition is unsupported",
		}
	}
}

func loopJSONValueDigest(value json.RawMessage) (string, error) {
	wrapped := make(json.RawMessage, 0, len(value)+10)
	wrapped = append(wrapped, `{"value":`...)
	wrapped = append(wrapped, value...)
	wrapped = append(wrapped, '}')
	return jsonValueDigest(wrapped)
}

func jsonValueAtPath(value json.RawMessage, path []string) (json.RawMessage, bool, error) {
	current := append(json.RawMessage(nil), value...)
	for _, segment := range path {
		var object map[string]json.RawMessage
		if err := json.Unmarshal(current, &object); err != nil {
			return nil, false, nil
		}
		next, found := object[segment]
		if !found {
			return nil, false, nil
		}
		current = next
	}
	return current, true, nil
}

type loopResultValue struct {
	CreatedAt time.Time
	Value     json.RawMessage
}

func (transaction *Tx) loopOutputStalled(
	ctx context.Context,
	nodeID domain.NodeRunID,
	limit uint32,
) (bool, error) {
	rows, err := transaction.tx.QueryContext(
		ctx, "SELECT payload FROM records WHERE kind = ?", taskResultRecordKind,
	)
	if err != nil {
		return false, wrap("read loop task results", string(nodeID), err)
	}
	defer rows.Close()
	var values []loopResultValue
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return false, wrap("scan loop task result", string(nodeID), err)
		}
		var result domain.TaskResult
		if err := json.Unmarshal(payload, &result); err != nil {
			return false, wrap("decode loop task result", string(nodeID), err)
		}
		if result.NodeRunID == nodeID {
			values = append(values, loopResultValue{CreatedAt: result.Metadata.CreatedAt, Value: result.Value})
		}
	}
	if err := rows.Err(); err != nil {
		return false, wrap("iterate loop task results", string(nodeID), err)
	}
	if uint32(len(values)) < limit {
		return false, nil
	}
	sort.Slice(values, func(first int, second int) bool {
		return values[first].CreatedAt.Before(values[second].CreatedAt)
	})
	latest, err := jsonValueDigest(values[len(values)-1].Value)
	if err != nil {
		return false, err
	}
	for offset := uint32(1); offset < limit; offset++ {
		candidate, err := jsonValueDigest(values[len(values)-1-int(offset)].Value)
		if err != nil {
			return false, err
		}
		if candidate != latest {
			return false, nil
		}
	}
	return true, nil
}

func (transaction *Tx) restartLoop(
	ctx context.Context,
	runID domain.WorkflowRunID,
	loop workflowmodel.Loop,
	definition workflowmodel.Definition,
	admissionID domain.AdmissionID,
	now time.Time,
) error {
	backEdge, _ := workflowEdgeByID(definition.Edges, loop.BackEdge)
	members := loopNodeKeys(definition, loop)
	snapshotID, current, err := transaction.currentAdmissionSnapshot(ctx, admissionID)
	if err != nil {
		return err
	}
	if !current {
		return staleReplayAdmission(admissionID)
	}
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if _, found := members[node.NodeKey]; !found {
			continue
		}
		node.SessionID = nil
		node.TaskResultID = nil
		node.AdmissionID = nil
		node.RepairAttempt = 0
		node.InputSnapshotIDs = nil
		state := domain.NodeRunStatePending
		if node.NodeKey == backEdge.To {
			state = domain.NodeRunStateReady
			node.InputSnapshotIDs = []domain.SnapshotID{snapshotID}
		}
		if err := transaction.transitionNodeRun(ctx, &node, state, now); err != nil {
			return err
		}
	}
	payload, err := json.Marshal(struct {
		LoopID      string             `json:"loopId"`
		AdmissionID domain.AdmissionID `json:"admissionId"`
		SnapshotID  domain.SnapshotID  `json:"snapshotId"`
	}{LoopID: loop.ID, AdmissionID: admissionID, SnapshotID: snapshotID})
	if err != nil {
		return wrap("encode loop iteration event", loop.ID, err)
	}
	_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
		Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(runID)},
		Type:      "workflow.loop.iteration-started", Payload: payload,
	})
	return err
}

func (transaction *Tx) capLoop(
	ctx context.Context,
	runID domain.WorkflowRunID,
	loop workflowmodel.Loop,
	definition workflowmodel.Definition,
	stalled bool,
	now time.Time,
) error {
	members := loopNodeKeys(definition, loop)
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if _, found := members[node.NodeKey]; !found || node.State == domain.NodeRunStateCapped {
			continue
		}
		if err := transaction.transitionNodeRun(ctx, &node, domain.NodeRunStateCapped, now); err != nil {
			return err
		}
	}
	if err := transaction.transitionWorkflowRun(ctx, runID, domain.WorkflowRunStateCapped, now); err != nil {
		return err
	}
	payload, err := json.Marshal(struct {
		LoopID  string `json:"loopId"`
		Stalled bool   `json:"stalled"`
	}{LoopID: loop.ID, Stalled: stalled})
	if err != nil {
		return wrap("encode loop capped event", loop.ID, err)
	}
	_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
		Aggregate: domain.ResourceReference{Kind: workflowRunRecordKind, ID: string(runID)},
		Type:      "workflow.loop.capped", Payload: payload,
	})
	return err
}

func loopNodeKeys(definition workflowmodel.Definition, loop workflowmodel.Loop) map[domain.NodeKey]struct{} {
	backEdge, found := workflowEdgeByID(definition.Edges, loop.BackEdge)
	if !found {
		return nil
	}
	forward := make(map[domain.NodeKey][]domain.NodeKey)
	reverse := make(map[domain.NodeKey][]domain.NodeKey)
	for _, edge := range definition.Edges {
		if isBackEdge(definition.Loops, edge.ID) {
			continue
		}
		forward[edge.From] = append(forward[edge.From], edge.To)
		reverse[edge.To] = append(reverse[edge.To], edge.From)
	}
	fromTarget := reachableNodeKeys(backEdge.To, forward)
	toSource := reachableNodeKeys(backEdge.From, reverse)
	members := make(map[domain.NodeKey]struct{})
	for key := range fromTarget {
		if _, found := toSource[key]; found {
			members[key] = struct{}{}
		}
	}
	return members
}

func reachableNodeKeys(
	start domain.NodeKey,
	adjacent map[domain.NodeKey][]domain.NodeKey,
) map[domain.NodeKey]struct{} {
	seen := map[domain.NodeKey]struct{}{start: {}}
	queue := []domain.NodeKey{start}
	for len(queue) > 0 {
		key := queue[0]
		queue = queue[1:]
		for _, next := range adjacent[key] {
			if _, found := seen[next]; found {
				continue
			}
			seen[next] = struct{}{}
			queue = append(queue, next)
		}
	}
	return seen
}

func workflowEdgeByID(edges []workflowmodel.Edge, id domain.EdgeKey) (workflowmodel.Edge, bool) {
	for _, edge := range edges {
		if edge.ID == id {
			return edge, true
		}
	}
	return workflowmodel.Edge{}, false
}

func (transaction *Tx) completeWorkflowRun(
	ctx context.Context,
	runID domain.WorkflowRunID,
	now time.Time,
) error {
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if node.State != domain.NodeRunStateSucceeded {
			return nil
		}
	}
	return transaction.transitionWorkflowRun(ctx, runID, domain.WorkflowRunStateSucceeded, now)
}

func (transaction *Tx) transitionWorkflowRun(
	ctx context.Context,
	runID domain.WorkflowRunID,
	state domain.WorkflowRunState,
	now time.Time,
) error {
	run, found, err := transaction.workflowRun(ctx, runID)
	if err != nil {
		return err
	}
	if !found {
		return &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "transition workflow", Resource: string(runID),
			Message: "workflow run is unavailable",
		}
	}
	if run.State == state {
		return nil
	}
	previousVersion := run.Metadata.ResourceVersion
	run.State = state
	run.Metadata.ResourceVersion++
	run.Metadata.UpdatedAt = now
	encoded, err := json.Marshal(run)
	if err != nil {
		return wrap("encode workflow transition", string(runID), err)
	}
	return transaction.updateRecord(
		ctx, workflowRunRecordKind, string(runID), previousVersion, run.Metadata, encoded,
	)
}

func (transaction *Tx) admission(
	ctx context.Context,
	id domain.AdmissionID,
) (domain.Admission, bool, error) {
	var admission domain.Admission
	payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &admission)
		if err != nil {
			err = wrap("decode admission", string(id), err)
		}
	}
	return admission, found, err
}

func (store *Store) RefreshAdmission(
	ctx context.Context,
	request AdmissionFreshnessRequest,
) (domain.Admission, bool, error) {
	if err := validateAdmissionFreshnessRequest(request); err != nil {
		return domain.Admission{}, false, err
	}
	var refreshed domain.Admission
	var current bool
	err := store.Transaction(ctx, func(transaction *Tx) error {
		payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(request.ID))
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "refresh admission", Resource: string(request.ID),
				Message: "admission does not exist",
			}
		}
		if err := json.Unmarshal(payload, &refreshed); err != nil {
			return wrap("decode admission", string(request.ID), err)
		}
		if refreshed.State != domain.AdmissionStateAdmitted {
			return nil
		}
		evidence, err := transaction.loadTaskContext(ctx, refreshed.TaskRecordID)
		if err != nil {
			return err
		}
		validations, err := transaction.validations(ctx, refreshed.ValidationIDs)
		if err != nil {
			return err
		}
		current, err = admissionMatchesEnvironment(evidence, validations, refreshed, request.EnvironmentIDs)
		if err != nil || current {
			return err
		}
		now := time.Now().UTC()
		previousVersion := refreshed.Metadata.ResourceVersion
		refreshed.State = domain.AdmissionStateStale
		refreshed.Metadata.ResourceVersion++
		refreshed.Metadata.UpdatedAt = now
		encoded, err := json.Marshal(refreshed)
		if err != nil {
			return wrap("encode stale admission", string(refreshed.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, admissionRecordKind, string(refreshed.ID), previousVersion, refreshed.Metadata, encoded,
		); err != nil {
			return err
		}
		if err := transaction.invalidateAdmissionConsumers(ctx, refreshed.ID, now); err != nil {
			return err
		}
		eventPayload, err := json.Marshal(struct {
			AdmissionID domain.AdmissionID `json:"admissionId"`
		}{AdmissionID: refreshed.ID})
		if err != nil {
			return wrap("encode stale admission event", string(refreshed.ID), err)
		}
		_, err = transaction.AppendEvent(ctx, domain.EventEnvelope{
			SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
			Aggregate: domain.ResourceReference{Kind: admissionRecordKind, ID: string(refreshed.ID)},
			Type:      "workflow.admission.stale", Payload: eventPayload,
		})
		return err
	})
	return refreshed, current, err
}

type taskEvidenceContext struct {
	task       domain.TaskRecord
	result     domain.TaskResult
	node       domain.NodeRun
	definition workflowmodel.Definition
	template   workflowmodel.Template
	snapshot   domain.Snapshot
}

func (transaction *Tx) loadTaskContext(
	ctx context.Context,
	id domain.TaskRecordID,
) (taskEvidenceContext, error) {
	task, found, err := transaction.taskRecord(ctx, id)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "read evidence", Resource: string(id),
			Message: "task record does not exist",
		}
	}
	result, found, err := transaction.taskResult(ctx, task.TaskResultID)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(id),
			Message: "task result is unavailable",
		}
	}
	node, found, err := transaction.nodeRun(ctx, result.NodeRunID)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(result.NodeRunID),
			Message: "node run is unavailable",
		}
	}
	run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(node.WorkflowRunID),
			Message: "workflow run is unavailable",
		}
	}
	definitionRecord, err := transaction.workflowDefinitionAtVersion(
		ctx, run.WorkflowDefinition, node.DefinitionVersion,
	)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	definition, err := decodeResolvedDefinition(definitionRecord)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	nodeDefinition, found := definition.Nodes[node.NodeKey]
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(node.NodeKey),
			Message: "pinned node definition is unavailable",
		}
	}
	template, found := definition.Templates[nodeDefinition.Template]
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(nodeDefinition.Template),
			Message: "pinned stage template is unavailable",
		}
	}
	snapshot, found, err := transaction.snapshot(ctx, task.SnapshotID)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if !found {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(task.SnapshotID),
			Message: "task snapshot is unavailable",
		}
	}
	artifacts, err := transaction.taskArtifacts(ctx, result, snapshot)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	digest, err := taskInputDigest(node, result, snapshot, artifacts)
	if err != nil {
		return taskEvidenceContext{}, err
	}
	if digest != task.InputDigest {
		return taskEvidenceContext{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read evidence", Resource: string(task.ID),
			Message: "task input digest does not match its records",
		}
	}
	return taskEvidenceContext{
		task: task, result: result, node: node, definition: definition,
		template: template, snapshot: snapshot,
	}, nil
}

func (transaction *Tx) taskRecord(
	ctx context.Context,
	id domain.TaskRecordID,
) (domain.TaskRecord, bool, error) {
	var record domain.TaskRecord
	payload, found, err := transaction.recordPayload(ctx, taskRecordRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &record)
		if err != nil {
			err = wrap("decode task record", string(id), err)
		}
	}
	return record, found, err
}

func (transaction *Tx) taskResult(
	ctx context.Context,
	id domain.TaskResultID,
) (domain.TaskResult, bool, error) {
	var result domain.TaskResult
	payload, found, err := transaction.recordPayload(ctx, taskResultRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &result)
		if err != nil {
			err = wrap("decode task result", string(id), err)
		}
	}
	return result, found, err
}

func (transaction *Tx) snapshot(
	ctx context.Context,
	id domain.SnapshotID,
) (domain.Snapshot, bool, error) {
	var snapshot domain.Snapshot
	payload, found, err := transaction.recordPayload(ctx, snapshotRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &snapshot)
		if err != nil {
			err = wrap("decode workspace snapshot", string(id), err)
		}
	}
	return snapshot, found, err
}

func (transaction *Tx) artifact(
	ctx context.Context,
	id domain.ArtifactID,
) (domain.Artifact, bool, error) {
	var artifact domain.Artifact
	payload, found, err := transaction.recordPayload(ctx, artifactRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &artifact)
		if err != nil {
			err = wrap("decode artifact", string(id), err)
		}
	}
	return artifact, found, err
}

func (transaction *Tx) taskArtifact(
	ctx context.Context,
	id domain.ArtifactID,
	snapshotID domain.SnapshotID,
) (domain.Artifact, error) {
	artifact, found, err := transaction.artifact(ctx, id)
	if err != nil {
		return domain.Artifact{}, err
	}
	if !found {
		return domain.Artifact{}, &domain.Error{
			Code: domain.ErrorCodeNotFound, Op: "read artifact", Resource: string(id),
			Message: "artifact does not exist",
		}
	}
	if artifact.SnapshotID != snapshotID {
		return domain.Artifact{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "read artifact", Resource: string(id),
			Message: "artifact belongs to a different snapshot",
		}
	}
	return artifact, nil
}

func (transaction *Tx) taskArtifacts(
	ctx context.Context,
	result domain.TaskResult,
	snapshot domain.Snapshot,
) ([]domain.Artifact, error) {
	artifacts := make([]domain.Artifact, 0, len(result.ArtifactIDs))
	for _, id := range result.ArtifactIDs {
		artifact, err := transaction.taskArtifact(ctx, id, snapshot.ID)
		if err != nil {
			return nil, err
		}
		artifacts = append(artifacts, artifact)
	}
	sort.Slice(artifacts, func(first int, second int) bool { return artifacts[first].ID < artifacts[second].ID })
	return artifacts, nil
}

func taskInputDigest(
	node domain.NodeRun,
	result domain.TaskResult,
	snapshot domain.Snapshot,
	artifacts []domain.Artifact,
) (string, error) {
	encoded, err := json.Marshal(struct {
		NodeDefinitionDigest string            `json:"nodeDefinitionDigest"`
		Result               domain.TaskResult `json:"result"`
		SnapshotTreeDigest   string            `json:"snapshotTreeDigest"`
		Artifacts            []domain.Artifact `json:"artifacts"`
	}{
		NodeDefinitionDigest: node.NodeDefinitionDigest,
		Result:               result, SnapshotTreeDigest: snapshot.TreeDigest, Artifacts: artifacts,
	})
	if err != nil {
		return "", wrap("encode task evidence inputs", string(result.ID), err)
	}
	digest := sha256.Sum256(encoded)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func verificationDefinitionDigest(definition workflowmodel.Verification) (string, error) {
	encoded, err := json.Marshal(definition)
	if err != nil {
		return "", wrap("encode validation definition", definition.Key, err)
	}
	digest := sha256.Sum256(encoded)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func verificationByKey(
	definitions []workflowmodel.Verification,
	key string,
) (workflowmodel.Verification, bool) {
	for _, definition := range definitions {
		if definition.Key == key {
			return definition, true
		}
	}
	return workflowmodel.Verification{}, false
}

func (transaction *Tx) validations(
	ctx context.Context,
	ids []domain.ValidationID,
) ([]domain.Validation, error) {
	validations := make([]domain.Validation, 0, len(ids))
	for _, id := range ids {
		var validation domain.Validation
		payload, found, err := transaction.recordPayload(ctx, validationRecordKind, string(id))
		if err != nil {
			return nil, err
		}
		if !found {
			return nil, &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "read validation", Resource: string(id),
				Message: "validation does not exist",
			}
		}
		if err := json.Unmarshal(payload, &validation); err != nil {
			return nil, wrap("decode validation", string(id), err)
		}
		validations = append(validations, validation)
	}
	sort.Slice(validations, func(first int, second int) bool { return validations[first].ID < validations[second].ID })
	return validations, nil
}

func admissionState(
	context taskEvidenceContext,
	validations []domain.Validation,
) (domain.AdmissionState, error) {
	byKey := make(map[string]domain.Validation, len(validations))
	for _, validation := range validations {
		if validation.TaskRecordID != context.task.ID || validation.InputDigest != context.task.InputDigest {
			return domain.AdmissionStateStale, nil
		}
		definition, found := verificationByKey(context.template.Verification, validation.Key)
		if !found {
			return "", &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "decide admission", Resource: validation.Key,
				Message: "validation is absent from the pinned stage template",
			}
		}
		digest, err := verificationDefinitionDigest(definition)
		if err != nil {
			return "", err
		}
		if digest != validation.DefinitionDigest {
			return domain.AdmissionStateStale, nil
		}
		if _, found := byKey[validation.Key]; found {
			return "", &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "decide admission", Resource: validation.Key,
				Message: "admission contains duplicate validation keys",
			}
		}
		byKey[validation.Key] = validation
	}
	state := domain.AdmissionStateAdmitted
	for _, definition := range context.template.Verification {
		if !definition.Required {
			continue
		}
		validation, found := byKey[definition.Key]
		if !found {
			state = domain.AdmissionStatePending
			continue
		}
		if validation.Authority == domain.AuthorityAdvisory {
			state = domain.AdmissionStatePending
			continue
		}
		switch validation.State {
		case domain.ValidationStatePassed:
		case domain.ValidationStateStale:
			return domain.AdmissionStateStale, nil
		case domain.ValidationStateFailed, domain.ValidationStateError, domain.ValidationStateSkipped:
			state = domain.AdmissionStateRejected
		default:
			return "", &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "decide admission", Resource: string(validation.ID),
				Message: "validation state is unsupported",
			}
		}
	}
	return state, nil
}

func admissionBoundDigest(task domain.TaskRecord, validations []domain.Validation) (string, error) {
	type boundValidation struct {
		ID               domain.ValidationID    `json:"id"`
		Key              string                 `json:"key"`
		State            domain.ValidationState `json:"state"`
		Authority        domain.Authority       `json:"authority"`
		InputDigest      string                 `json:"inputDigest"`
		DefinitionDigest string                 `json:"definitionDigest"`
		EnvironmentID    string                 `json:"environmentId"`
		ArtifactID       *domain.ArtifactID     `json:"artifactId,omitempty"`
		ExitCode         *int                   `json:"exitCode,omitempty"`
		LogArtifactID    *domain.ArtifactID     `json:"logArtifactId,omitempty"`
	}
	bound := make([]boundValidation, len(validations))
	for index, validation := range validations {
		bound[index] = boundValidation{
			ID: validation.ID, Key: validation.Key, State: validation.State,
			Authority: validation.Authority, InputDigest: validation.InputDigest,
			DefinitionDigest: validation.DefinitionDigest, EnvironmentID: validation.EnvironmentID,
			ArtifactID: validation.ArtifactID, ExitCode: validation.ExitCode,
			LogArtifactID: validation.LogArtifactID,
		}
	}
	sort.Slice(bound, func(first int, second int) bool { return bound[first].ID < bound[second].ID })
	encoded, err := json.Marshal(struct {
		TaskInputDigest string            `json:"taskInputDigest"`
		Validations     []boundValidation `json:"validations"`
	}{TaskInputDigest: task.InputDigest, Validations: bound})
	if err != nil {
		return "", wrap("encode admission binding", string(task.ID), err)
	}
	digest := sha256.Sum256(encoded)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func (transaction *Tx) advanceDependentNodes(
	ctx context.Context,
	runID domain.WorkflowRunID,
	definition workflowmodel.Definition,
	now time.Time,
) error {
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return err
	}
	byKey := make(map[domain.NodeKey]domain.NodeRun, len(nodes))
	for _, node := range nodes {
		byKey[node.NodeKey] = node
	}
	backEdges := make(map[domain.EdgeKey]struct{}, len(definition.Loops))
	for _, loop := range definition.Loops {
		backEdges[loop.BackEdge] = struct{}{}
	}
	for _, candidate := range nodes {
		if candidate.State != domain.NodeRunStatePending {
			continue
		}
		ready := true
		snapshots := make(map[domain.SnapshotID]struct{})
		for _, edge := range definition.Edges {
			if edge.To != candidate.NodeKey {
				continue
			}
			if _, backEdge := backEdges[edge.ID]; backEdge {
				continue
			}
			upstream, found := byKey[edge.From]
			if !found {
				return &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "advance workflow", Resource: string(edge.From),
					Message: "upstream node run is unavailable",
				}
			}
			if upstream.AdmissionID == nil {
				if edge.Required {
					ready = false
				}
				continue
			}
			snapshotID, current, err := transaction.currentAdmissionSnapshot(ctx, *upstream.AdmissionID)
			if err != nil {
				return err
			}
			if !current {
				if edge.Required {
					ready = false
				}
				continue
			}
			snapshots[snapshotID] = struct{}{}
		}
		if !ready {
			continue
		}
		candidate.InputSnapshotIDs = make([]domain.SnapshotID, 0, len(snapshots))
		for snapshotID := range snapshots {
			candidate.InputSnapshotIDs = append(candidate.InputSnapshotIDs, snapshotID)
		}
		sort.Slice(candidate.InputSnapshotIDs, func(first int, second int) bool {
			return candidate.InputSnapshotIDs[first] < candidate.InputSnapshotIDs[second]
		})
		if err := transaction.transitionNodeRun(ctx, &candidate, domain.NodeRunStateReady, now); err != nil {
			return err
		}
		byKey[candidate.NodeKey] = candidate
	}
	return nil
}

func (transaction *Tx) currentAdmissionSnapshot(
	ctx context.Context,
	id domain.AdmissionID,
) (domain.SnapshotID, bool, error) {
	var admission domain.Admission
	payload, found, err := transaction.recordPayload(ctx, admissionRecordKind, string(id))
	if err != nil {
		return "", false, err
	}
	if !found {
		return "", false, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "read admission", Resource: string(id),
			Message: "node admission is unavailable",
		}
	}
	if err := json.Unmarshal(payload, &admission); err != nil {
		return "", false, wrap("decode admission", string(id), err)
	}
	if admission.State != domain.AdmissionStateAdmitted {
		return "", false, nil
	}
	context, err := transaction.loadTaskContext(ctx, admission.TaskRecordID)
	if err != nil {
		return "", false, err
	}
	validations, err := transaction.validations(ctx, admission.ValidationIDs)
	if err != nil {
		return "", false, err
	}
	state, err := admissionState(context, validations)
	if err != nil || state != domain.AdmissionStateAdmitted {
		return "", false, err
	}
	digest, err := admissionBoundDigest(context.task, validations)
	if err != nil {
		return "", false, err
	}
	return context.snapshot.ID, digest == admission.BoundDigest, nil
}

func admissionMatchesEnvironment(
	context taskEvidenceContext,
	validations []domain.Validation,
	admission domain.Admission,
	environmentIDs map[string]string,
) (bool, error) {
	state, err := admissionState(context, validations)
	if err != nil || state != domain.AdmissionStateAdmitted {
		return false, err
	}
	digest, err := admissionBoundDigest(context.task, validations)
	if err != nil || digest != admission.BoundDigest {
		return false, err
	}
	for _, validation := range validations {
		definition, found := verificationByKey(context.template.Verification, validation.Key)
		if !found {
			return false, nil
		}
		identity, found := environmentIDs[definition.Environment]
		if !found {
			return false, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "refresh admission", Resource: definition.Environment,
				Message: "current environment identity is missing",
			}
		}
		if identity != validation.EnvironmentID {
			return false, nil
		}
	}
	return true, nil
}

func (transaction *Tx) blockReadyDependents(
	ctx context.Context,
	runID domain.WorkflowRunID,
	upstreamKey domain.NodeKey,
	definition workflowmodel.Definition,
	now time.Time,
) error {
	blocked := make(map[domain.NodeKey]struct{})
	for _, edge := range definition.Edges {
		if edge.From == upstreamKey && edge.Required && !isBackEdge(definition.Loops, edge.ID) {
			blocked[edge.To] = struct{}{}
		}
	}
	nodes, err := transaction.nodeRuns(ctx, &runID)
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if _, found := blocked[node.NodeKey]; !found || node.State != domain.NodeRunStateReady || node.Attempt != 0 {
			continue
		}
		node.InputSnapshotIDs = []domain.SnapshotID{}
		if err := transaction.transitionNodeRun(ctx, &node, domain.NodeRunStatePending, now); err != nil {
			return err
		}
	}
	return nil
}

func (transaction *Tx) invalidateAdmissionConsumers(
	ctx context.Context,
	id domain.AdmissionID,
	now time.Time,
) error {
	nodes, err := transaction.nodeRuns(ctx, nil)
	if err != nil {
		return err
	}
	for _, node := range nodes {
		if node.AdmissionID == nil || *node.AdmissionID != id {
			continue
		}
		if node.State == domain.NodeRunStateSucceeded {
			previousVersion := node.Metadata.ResourceVersion
			node.State = domain.NodeRunStateWaiting
			node.Metadata.ResourceVersion++
			node.Metadata.UpdatedAt = now
			encoded, err := json.Marshal(node)
			if err != nil {
				return wrap("encode stale admission consumer", string(node.ID), err)
			}
			if err := transaction.updateRecord(
				ctx, nodeRunRecordKind, string(node.ID), previousVersion, node.Metadata, encoded,
			); err != nil {
				return err
			}
		}
		run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "invalidate admission", Resource: string(node.WorkflowRunID),
				Message: "admission consumer workflow run is unavailable",
			}
		}
		definitionRecord, err := transaction.workflowDefinitionAtVersion(
			ctx, run.WorkflowDefinition, node.DefinitionVersion,
		)
		if err != nil {
			return err
		}
		definition, err := decodeResolvedDefinition(definitionRecord)
		if err != nil {
			return err
		}
		if err := transaction.blockReadyDependents(
			ctx, node.WorkflowRunID, node.NodeKey, definition, now,
		); err != nil {
			return err
		}
	}
	return nil
}

func isBackEdge(loops []workflowmodel.Loop, edgeID domain.EdgeKey) bool {
	for _, loop := range loops {
		if loop.BackEdge == edgeID {
			return true
		}
	}
	return false
}

func snapshotReferencePayload(
	snapshotID domain.SnapshotID,
	owner domain.ResourceReference,
) ([]byte, error) {
	payload, err := json.Marshal(struct {
		SnapshotID domain.SnapshotID        `json:"snapshotId"`
		Owner      domain.ResourceReference `json:"owner"`
	}{SnapshotID: snapshotID, Owner: owner})
	if err != nil {
		return nil, wrap("encode snapshot reference", string(snapshotID), err)
	}
	return payload, nil
}

func validateTaskRecordRequest(request TaskRecordRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.TaskResultID.Validate(); err != nil {
		return err
	}
	return request.SnapshotID.Validate()
}

func validateValidationRequest(request ValidationRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.TaskRecordID.Validate(); err != nil {
		return err
	}
	if err := (domain.ResourceReference{Kind: "validation-key", ID: request.Key}).Validate(); err != nil {
		return err
	}
	if !request.State.Valid() || !request.Authority.Valid() {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: string(request.ID),
			Message: "validation state or authority is unsupported",
		}
	}
	if request.EnvironmentID == "" || len(request.EnvironmentID) > 1024 || !utf8.ValidString(request.EnvironmentID) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: string(request.ID),
			Message: "environment identity is empty or invalid",
		}
	}
	if request.ArtifactID != nil {
		if err := request.ArtifactID.Validate(); err != nil {
			return err
		}
	}
	if request.LogArtifactID != nil {
		if err := request.LogArtifactID.Validate(); err != nil {
			return err
		}
	}
	switch request.State {
	case domain.ValidationStatePassed:
		if request.ExitCode == nil || *request.ExitCode != 0 {
			return invalidValidationExit(request.ID)
		}
	case domain.ValidationStateFailed:
		if request.ExitCode == nil || *request.ExitCode == 0 {
			return invalidValidationExit(request.ID)
		}
	case domain.ValidationStateError, domain.ValidationStateSkipped, domain.ValidationStateStale:
	default:
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: string(request.ID),
			Message: "validation state is unsupported",
		}
	}
	return nil
}

func invalidValidationExit(id domain.ValidationID) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "record validation", Resource: string(id),
		Message: "validation state and exit code do not match",
	}
}

func validateAdmissionRequest(request AdmissionRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.TaskRecordID.Validate(); err != nil {
		return err
	}
	seen := make(map[domain.ValidationID]struct{}, len(request.ValidationIDs))
	for _, id := range request.ValidationIDs {
		if err := id.Validate(); err != nil {
			return err
		}
		if _, found := seen[id]; found {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "decide admission", Resource: string(request.ID),
				Message: "validation identifiers must be unique",
			}
		}
		seen[id] = struct{}{}
	}
	return nil
}

func validateAdmissionFreshnessRequest(request AdmissionFreshnessRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if request.EnvironmentIDs == nil {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "refresh admission", Resource: string(request.ID),
			Message: "current environment identities are missing",
		}
	}
	for name, identity := range request.EnvironmentIDs {
		if err := (domain.ResourceReference{Kind: "environment", ID: name}).Validate(); err != nil {
			return err
		}
		if identity == "" || len(identity) > 1024 || !utf8.ValidString(identity) {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "refresh admission", Resource: name,
				Message: "current environment identity is empty or invalid",
			}
		}
	}
	return nil
}

func containsArtifactID(ids []domain.ArtifactID, expected domain.ArtifactID) bool {
	for _, id := range ids {
		if id == expected {
			return true
		}
	}
	return false
}
