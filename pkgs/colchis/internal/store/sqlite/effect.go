package sqlite

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/cyberphone/json-canonicalization/go/src/webpki.org/jsoncanonicalizer"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	workflowmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/workflow"
)

const (
	effectAuthorityRecordKind      = "effect-authority"
	effectOperationRecordKind      = "effect-operation"
	effectReconciliationRecordKind = "effect-reconciliation"
)

type EffectAuthorityRequest struct {
	ID            domain.EffectAuthorityID `json:"id"`
	CommandID     domain.CommandID         `json:"commandId"`
	NodeRunID     domain.NodeRunID         `json:"nodeRunId"`
	OperationKind string                   `json:"operationKind"`
	Target        json.RawMessage          `json:"target"`
	InputDigest   string                   `json:"inputDigest"`
	Principal     string                   `json:"principal"`
	ExpiresAt     time.Time                `json:"expiresAt"`
}

type EffectOperationRequest struct {
	ID                 domain.OperationID       `json:"id"`
	PluginID           domain.PluginID          `json:"pluginId,omitempty"`
	CommandID          domain.CommandID         `json:"commandId"`
	NodeRunID          domain.NodeRunID         `json:"nodeRunId"`
	Kind               string                   `json:"kind"`
	TargetSchemaDigest string                   `json:"targetSchemaDigest"`
	Target             json.RawMessage          `json:"target"`
	InputDigest        string                   `json:"inputDigest"`
	AuthorityID        domain.EffectAuthorityID `json:"authorityId"`
}

type EffectReconciliationRequest struct {
	ID                   domain.EffectReconciliationID `json:"id"`
	OperationID          domain.OperationID            `json:"operationId"`
	Resolution           string                        `json:"resolution"`
	ObservedTargetDigest string                        `json:"observedTargetDigest"`
	Principal            string                        `json:"principal"`
}

func (store *Store) ReconcileEffectObservation(
	ctx context.Context,
	id domain.EffectReconciliationID,
	operationID domain.OperationID,
	workflowRunID domain.WorkflowRunID,
	observedTarget json.RawMessage,
	principal string,
) (domain.Operation, domain.EffectReconciliation, error) {
	if !json.Valid(observedTarget) {
		return domain.Operation{}, domain.EffectReconciliation{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "reconcile effect observation", Resource: string(operationID),
			Message: "observed target is not valid JSON",
		}
	}
	var operation domain.Operation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		operation, found, err = transaction.effectOperation(ctx, operationID)
		if err != nil {
			return err
		}
		if !found {
			return notFound("reconcile effect observation", string(operationID), "effect operation does not exist")
		}
		node, found, err := transaction.nodeRun(ctx, operation.NodeRunID)
		if err != nil {
			return err
		}
		if !found || node.WorkflowRunID != workflowRunID {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "reconcile effect observation", Resource: string(operationID),
				Message: "effect operation does not belong to the selected workflow run",
			}
		}
		return nil
	})
	if err != nil {
		return domain.Operation{}, domain.EffectReconciliation{}, err
	}
	observedDigest, err := jsonValueDigest(observedTarget)
	if err != nil {
		return domain.Operation{}, domain.EffectReconciliation{}, err
	}
	resolution := "not_applied"
	if observedDigest == operation.TargetDigest {
		resolution = "applied"
	}
	return store.ReconcileEffectOperation(ctx, EffectReconciliationRequest{
		ID: id, OperationID: operationID, Resolution: resolution,
		ObservedTargetDigest: observedDigest, Principal: principal,
	})
}

type effectEventPayload struct {
	AuthorityID  domain.EffectAuthorityID `json:"authorityId,omitempty"`
	CommandID    domain.CommandID         `json:"commandId,omitempty"`
	Kind         string                   `json:"kind,omitempty"`
	OperationID  domain.OperationID       `json:"operationId,omitempty"`
	TargetDigest string                   `json:"targetDigest,omitempty"`
	State        domain.OperationState    `json:"state,omitempty"`
	Resolution   string                   `json:"resolution,omitempty"`
}

func (store *Store) GrantEffectAuthority(
	ctx context.Context,
	request EffectAuthorityRequest,
) (domain.EffectAuthority, error) {
	if err := validateEffectAuthorityRequest(request, time.Now().UTC(), store.budgets.MaxEventBytes); err != nil {
		return domain.EffectAuthority{}, err
	}
	targetDigest, err := jsonValueDigest(request.Target)
	if err != nil {
		return domain.EffectAuthority{}, err
	}
	var authority domain.EffectAuthority
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, effectAuthorityRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "grant effect authority", Resource: string(request.ID),
				Message: "effect authority already exists",
			}
		}
		command, found, err := transaction.commandByID(ctx, request.CommandID)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "grant effect authority", Resource: string(request.CommandID),
				Message: "effect command does not exist",
			}
		}
		if command.State != domain.CommandStateAccepted || command.Principal != request.Principal ||
			command.Kind != "effect."+request.OperationKind {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "grant effect authority", Resource: string(request.CommandID),
				Message: "effect command is not an accepted command from this owner",
			}
		}
		commandTargetDigest, err := jsonValueDigest(command.Payload)
		if err != nil {
			return err
		}
		if commandTargetDigest != targetDigest {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "grant effect authority", Resource: string(request.CommandID),
				Message: "authority target differs from the accepted command",
			}
		}
		node, found, err := transaction.nodeRun(ctx, request.NodeRunID)
		if err != nil {
			return err
		}
		inputDigest, err := effectInputDigest(node)
		if !found || node.State != domain.NodeRunStateRunning || err != nil || inputDigest != request.InputDigest {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "grant effect authority", Resource: string(request.NodeRunID),
				Message: "effect authority inputs are not current for the running node", Err: err,
			}
		}
		now := time.Now().UTC()
		authority = domain.EffectAuthority{
			Metadata: newRecordMetadata(now), ID: request.ID, CommandID: command.ID, NodeRunID: node.ID,
			OperationKind: request.OperationKind, TargetDigest: targetDigest,
			InputDigest: request.InputDigest, Principal: request.Principal, ExpiresAt: request.ExpiresAt.UTC(),
		}
		encoded, err := json.Marshal(authority)
		if err != nil {
			return wrap("encode effect authority", string(authority.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encoded); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, effectAuthorityRecordKind, string(authority.ID), authority.Metadata, encoded,
		); err != nil {
			return err
		}
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect.authority-granted",
			domain.ResourceReference{Kind: effectAuthorityRecordKind, ID: string(authority.ID)},
			effectEventPayload{AuthorityID: authority.ID, CommandID: authority.CommandID},
			false,
		)
	})
	return authority, err
}

func (store *Store) BeginEffectOperation(
	ctx context.Context,
	request EffectOperationRequest,
) (domain.Operation, error) {
	if err := validateEffectOperationRequest(request, store.budgets.MaxEventBytes); err != nil {
		return domain.Operation{}, err
	}
	targetDigest, err := jsonValueDigest(request.Target)
	if err != nil {
		return domain.Operation{}, err
	}
	var operation domain.Operation
	err = store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(ctx, effectOperationRecordKind, string(request.ID)); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "begin effect", Resource: string(request.ID),
				Message: "effect operation already exists",
			}
		}
		command, found, err := transaction.commandByID(ctx, request.CommandID)
		if err != nil {
			return err
		}
		if !found || command.State != domain.CommandStateAccepted || command.Kind != "effect."+request.Kind {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "begin effect", Resource: string(request.CommandID),
				Message: "effect command is unavailable or already dispatched",
			}
		}
		policy, err := transaction.effectPolicy(ctx, request.NodeRunID, request.Kind, request.TargetSchemaDigest)
		if err != nil {
			return err
		}
		node, found, err := transaction.nodeRun(ctx, request.NodeRunID)
		if err != nil {
			return err
		}
		currentInputDigest, err := effectInputDigest(node)
		if !found || err != nil || currentInputDigest != request.InputDigest {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "begin effect", Resource: string(request.NodeRunID),
				Message: "effect inputs changed after owner authority", Err: err,
			}
		}
		blocked, err := transaction.hasIndeterminateEffect(ctx, request.Kind, targetDigest)
		if err != nil {
			return err
		}
		if blocked {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "begin effect", Resource: targetDigest,
				Message: "a matching effect requires reconciliation before repetition",
			}
		}
		authority, found, err := transaction.effectAuthority(ctx, request.AuthorityID)
		if err != nil {
			return err
		}
		now := time.Now().UTC()
		if !found || authority.ConsumedBy != nil || !authority.ExpiresAt.After(now) ||
			authority.CommandID != command.ID || authority.Principal != command.Principal ||
			authority.NodeRunID != request.NodeRunID ||
			authority.OperationKind != request.Kind || authority.TargetDigest != targetDigest ||
			authority.InputDigest != request.InputDigest {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "begin effect", Resource: string(request.AuthorityID),
				Message: "effect authority is absent, expired, consumed, or mismatched",
			}
		}
		operation = domain.Operation{
			Metadata: newRecordMetadata(now), ID: request.ID, PluginID: request.PluginID,
			CommandID: command.ID, NodeRunID: request.NodeRunID, Kind: request.Kind,
			TargetSchemaDigest: request.TargetSchemaDigest, TargetDigest: targetDigest,
			InputDigest: request.InputDigest, AuthorityID: authority.ID,
			State: domain.OperationStatePending, Retryable: false,
			Idempotent: policy.Idempotent, Reconciliation: policy.Reconciliation,
			Request: append(json.RawMessage(nil), request.Target...),
		}
		encodedOperation, err := json.Marshal(operation)
		if err != nil {
			return wrap("encode effect operation", string(operation.ID), err)
		}
		previousAuthorityVersion := authority.Metadata.ResourceVersion
		authority.ConsumedBy = &operation.ID
		authority.ConsumedAt = &now
		authority.Metadata.ResourceVersion++
		authority.Metadata.UpdatedAt = now
		encodedAuthority, err := json.Marshal(authority)
		if err != nil {
			return wrap("encode consumed effect authority", string(authority.ID), err)
		}
		previousCommandVersion := command.Metadata.ResourceVersion
		command.State = domain.CommandStateRunning
		command.Metadata.ResourceVersion++
		command.Metadata.UpdatedAt = now
		encodedCommand, err := json.Marshal(command)
		if err != nil {
			return wrap("encode effect command", string(command.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encodedOperation); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, effectOperationRecordKind, string(operation.ID), operation.Metadata, encodedOperation,
		); err != nil {
			return err
		}
		if err := transaction.updateRecord(
			ctx, effectAuthorityRecordKind, string(authority.ID), previousAuthorityVersion,
			authority.Metadata, encodedAuthority,
		); err != nil {
			return err
		}
		if err := transaction.updateCommandRecords(ctx, command, previousCommandVersion, encodedCommand); err != nil {
			return err
		}
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect.intent-recorded",
			domain.ResourceReference{Kind: effectOperationRecordKind, ID: string(operation.ID)},
			effectEventPayload{OperationID: operation.ID, TargetDigest: operation.TargetDigest},
			false,
		)
	})
	if domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		recordErr := store.recordDeniedEffect(ctx, request, targetDigest)
		return operation, errors.Join(err, recordErr)
	}
	return operation, err
}

func (store *Store) ClaimEffectOperation(
	ctx context.Context,
	id domain.OperationID,
) (domain.Operation, error) {
	return store.transitionEffectOperation(ctx, id, domain.OperationStatePending, domain.OperationStateRunning, nil)
}

func (store *Store) FinishEffectOperation(
	ctx context.Context,
	id domain.OperationID,
	state domain.OperationState,
	result json.RawMessage,
) (domain.Operation, error) {
	if state != domain.OperationStateSucceeded && state != domain.OperationStateFailed &&
		state != domain.OperationStateIndeterminate {
		return domain.Operation{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "finish effect", Resource: string(id),
			Message: "effect finish state is unsupported",
		}
	}
	if len(result) != 0 && !json.Valid(result) {
		return domain.Operation{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "finish effect", Resource: string(id),
			Message: "effect result is not valid JSON",
		}
	}
	return store.transitionEffectOperation(ctx, id, domain.OperationStateRunning, state, result)
}

func (store *Store) RecoverEffectOperations(ctx context.Context) ([]domain.Operation, error) {
	rows, err := store.db.QueryContext(
		ctx,
		"SELECT payload FROM records WHERE kind = ? ORDER BY id",
		effectOperationRecordKind,
	)
	if err != nil {
		return nil, wrap("read interrupted effects", store.path, err)
	}
	var interrupted []domain.OperationID
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			rows.Close()
			return nil, wrap("scan interrupted effect", store.path, err)
		}
		var operation domain.Operation
		if err := json.Unmarshal(payload, &operation); err != nil {
			rows.Close()
			return nil, wrap("decode interrupted effect", store.path, err)
		}
		if operation.State == domain.OperationStatePending || operation.State == domain.OperationStateRunning {
			interrupted = append(interrupted, operation.ID)
		}
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return nil, wrap("iterate interrupted effects", store.path, err)
	}
	if err := rows.Close(); err != nil {
		return nil, wrap("close interrupted effects", store.path, err)
	}

	recovered := make([]domain.Operation, 0, len(interrupted))
	for _, id := range interrupted {
		operation, changed, err := store.recoverEffectOperation(ctx, id)
		if err != nil {
			return nil, err
		}
		if changed {
			recovered = append(recovered, operation)
		}
	}
	return recovered, nil
}

func (store *Store) recoverEffectOperation(
	ctx context.Context,
	id domain.OperationID,
) (domain.Operation, bool, error) {
	var operation domain.Operation
	var changed bool
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		operation, found, err = transaction.effectOperation(ctx, id)
		if err != nil {
			return err
		}
		if !found {
			return &domain.Error{
				Code: domain.ErrorCodeNotFound, Op: "recover effect", Resource: string(id),
				Message: "effect operation does not exist",
			}
		}
		if operation.State != domain.OperationStatePending && operation.State != domain.OperationStateRunning {
			return nil
		}
		command, found, err := transaction.commandByID(ctx, operation.CommandID)
		if err != nil {
			return err
		}
		if !found || command.State != domain.CommandStateIndeterminate {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "recover effect", Resource: string(operation.CommandID),
				Message: "effect command must be recovered before its operation",
			}
		}

		now := time.Now().UTC()
		if err := transaction.releaseEmergencyReserve(); err != nil {
			return err
		}
		previousOperationVersion := operation.Metadata.ResourceVersion
		if operation.State == domain.OperationStatePending {
			operation.State = domain.OperationStateFailed
		} else {
			operation.State = domain.OperationStateIndeterminate
		}
		operation.CompletedAt = &now
		operation.Retryable = false
		operation.Metadata.ResourceVersion++
		operation.Metadata.UpdatedAt = now
		encodedOperation, err := json.Marshal(operation)
		if err != nil {
			return wrap("encode recovered effect operation", string(operation.ID), err)
		}
		if err := transaction.updateRecord(
			ctx, effectOperationRecordKind, string(operation.ID), previousOperationVersion,
			operation.Metadata, encodedOperation,
		); err != nil {
			return err
		}
		if operation.State == domain.OperationStateFailed {
			previousCommandVersion := command.Metadata.ResourceVersion
			command.State = domain.CommandStateFailed
			command.Metadata.ResourceVersion++
			command.Metadata.UpdatedAt = now
			encodedCommand, err := json.Marshal(command)
			if err != nil {
				return wrap("encode recovered effect command", string(command.ID), err)
			}
			if err := transaction.updateCommandRecords(
				ctx, command, previousCommandVersion, encodedCommand,
			); err != nil {
				return err
			}
		}
		changed = true
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect.recovered",
			domain.ResourceReference{Kind: effectOperationRecordKind, ID: string(operation.ID)},
			effectEventPayload{OperationID: operation.ID, State: operation.State},
			true,
		)
	})
	return operation, changed, err
}

func (store *Store) ReconcileEffectOperation(
	ctx context.Context,
	request EffectReconciliationRequest,
) (domain.Operation, domain.EffectReconciliation, error) {
	if err := validateEffectReconciliationRequest(request); err != nil {
		return domain.Operation{}, domain.EffectReconciliation{}, err
	}
	var operation domain.Operation
	var reconciliation domain.EffectReconciliation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		if _, found, err := transaction.recordPayload(
			ctx, effectReconciliationRecordKind, string(request.ID),
		); err != nil {
			return err
		} else if found {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "reconcile effect", Resource: string(request.ID),
				Message: "effect reconciliation already exists",
			}
		}
		var found bool
		var err error
		operation, found, err = transaction.effectOperation(ctx, request.OperationID)
		if err != nil {
			return err
		}
		if !found || operation.State != domain.OperationStateIndeterminate {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "reconcile effect", Resource: string(request.OperationID),
				Message: "effect operation is not indeterminate",
			}
		}
		if request.Resolution == "applied" && request.ObservedTargetDigest != operation.TargetDigest {
			return &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "reconcile effect", Resource: string(operation.ID),
				Message: "applied resolution does not match the intended target digest",
			}
		}
		now := time.Now().UTC()
		if err := transaction.releaseEmergencyReserve(); err != nil {
			return err
		}
		reconciliation = domain.EffectReconciliation{
			Metadata: newRecordMetadata(now), ID: request.ID, OperationID: operation.ID,
			Resolution: request.Resolution, ObservedTargetDigest: request.ObservedTargetDigest,
			Principal: request.Principal, ObservedAt: now,
		}
		encodedReconciliation, err := json.Marshal(reconciliation)
		if err != nil {
			return wrap("encode effect reconciliation", string(reconciliation.ID), err)
		}
		previousOperationVersion := operation.Metadata.ResourceVersion
		if request.Resolution == "applied" {
			operation.State = domain.OperationStateSucceeded
		} else {
			operation.State = domain.OperationStateFailed
		}
		operation.CompletedAt = &now
		operation.Retryable = false
		operation.Metadata.ResourceVersion++
		operation.Metadata.UpdatedAt = now
		encodedOperation, err := json.Marshal(operation)
		if err != nil {
			return wrap("encode reconciled effect operation", string(operation.ID), err)
		}
		command, found, err := transaction.commandByID(ctx, operation.CommandID)
		if err != nil {
			return err
		}
		if !found || command.State != domain.CommandStateIndeterminate || command.Principal != request.Principal {
			return &domain.Error{
				Code: domain.ErrorCodeUnauthorized, Op: "reconcile effect", Resource: string(operation.CommandID),
				Message: "owner command cannot resolve this effect",
			}
		}
		previousCommandVersion := command.Metadata.ResourceVersion
		if request.Resolution == "applied" {
			command.State = domain.CommandStateSucceeded
		} else {
			command.State = domain.CommandStateFailed
		}
		command.Metadata.ResourceVersion++
		command.Metadata.UpdatedAt = now
		encodedCommand, err := json.Marshal(command)
		if err != nil {
			return wrap("encode reconciled effect command", string(command.ID), err)
		}
		if err := transaction.reserveRecordCapacity(ctx, encodedReconciliation); err != nil {
			return err
		}
		if err := transaction.putRecord(
			ctx, effectReconciliationRecordKind, string(reconciliation.ID),
			reconciliation.Metadata, encodedReconciliation,
		); err != nil {
			return err
		}
		if err := transaction.updateRecord(
			ctx, effectOperationRecordKind, string(operation.ID), previousOperationVersion,
			operation.Metadata, encodedOperation,
		); err != nil {
			return err
		}
		if err := transaction.updateCommandRecords(ctx, command, previousCommandVersion, encodedCommand); err != nil {
			return err
		}
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect.reconciled",
			domain.ResourceReference{Kind: effectOperationRecordKind, ID: string(operation.ID)},
			effectEventPayload{OperationID: operation.ID, Resolution: reconciliation.Resolution},
			true,
		)
	})
	return operation, reconciliation, err
}

func (store *Store) transitionEffectOperation(
	ctx context.Context,
	id domain.OperationID,
	from domain.OperationState,
	to domain.OperationState,
	result json.RawMessage,
) (domain.Operation, error) {
	if err := id.Validate(); err != nil {
		return domain.Operation{}, err
	}
	if uint64(len(result)) > store.budgets.MaxEventBytes {
		return domain.Operation{}, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "transition effect", Resource: string(id),
			Message: "effect result exceeds the configured limit",
		}
	}
	var operation domain.Operation
	err := store.Transaction(ctx, func(transaction *Tx) error {
		var found bool
		var err error
		operation, found, err = transaction.effectOperation(ctx, id)
		if err != nil {
			return err
		}
		if !found || operation.State != from {
			return &domain.Error{
				Code: domain.ErrorCodeConflict, Op: "transition effect", Resource: string(id),
				Message: "effect operation is not in the required state",
			}
		}
		if to == domain.OperationStateRunning {
			command, found, err := transaction.commandByID(ctx, operation.CommandID)
			if err != nil {
				return err
			}
			if !found || command.State != domain.CommandStateRunning {
				return &domain.Error{
					Code: domain.ErrorCodeConflict, Op: "dispatch effect", Resource: string(operation.CommandID),
					Message: "effect command requires reconciliation before dispatch",
				}
			}
		}
		now := time.Now().UTC()
		terminal := to == domain.OperationStateSucceeded || to == domain.OperationStateFailed ||
			to == domain.OperationStateIndeterminate
		if terminal {
			if err := transaction.releaseEmergencyReserve(); err != nil {
				return err
			}
		}
		previousVersion := operation.Metadata.ResourceVersion
		operation.State = to
		operation.Metadata.ResourceVersion++
		operation.Metadata.UpdatedAt = now
		if to == domain.OperationStateRunning {
			operation.Attempt++
			operation.DispatchedAt = &now
		} else {
			operation.CompletedAt = &now
			operation.Result = append(json.RawMessage(nil), result...)
			operation.Retryable = false
		}
		encoded, err := json.Marshal(operation)
		if err != nil {
			return wrap("encode effect operation transition", string(id), err)
		}
		if err := transaction.updateRecord(
			ctx, effectOperationRecordKind, string(id), previousVersion, operation.Metadata, encoded,
		); err != nil {
			return err
		}
		if to == domain.OperationStateSucceeded || to == domain.OperationStateFailed ||
			to == domain.OperationStateIndeterminate {
			command, found, err := transaction.commandByID(ctx, operation.CommandID)
			if err != nil {
				return err
			}
			if !found || command.State != domain.CommandStateRunning {
				return &domain.Error{
					Code: domain.ErrorCodeInternal, Op: "transition effect", Resource: string(operation.CommandID),
					Message: "effect command state is unavailable",
				}
			}
			previousCommandVersion := command.Metadata.ResourceVersion
			switch to {
			case domain.OperationStateSucceeded:
				command.State = domain.CommandStateSucceeded
			case domain.OperationStateFailed:
				command.State = domain.CommandStateFailed
			case domain.OperationStateIndeterminate:
				command.State = domain.CommandStateIndeterminate
			}
			command.Metadata.ResourceVersion++
			command.Metadata.UpdatedAt = now
			encodedCommand, err := json.Marshal(command)
			if err != nil {
				return wrap("encode effect command transition", string(command.ID), err)
			}
			if err := transaction.updateCommandRecords(
				ctx, command, previousCommandVersion, encodedCommand,
			); err != nil {
				return err
			}
		}
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect."+string(to),
			domain.ResourceReference{Kind: effectOperationRecordKind, ID: string(operation.ID)},
			effectEventPayload{OperationID: operation.ID, State: operation.State},
			terminal,
		)
	})
	return operation, err
}

func (transaction *Tx) effectPolicy(
	ctx context.Context,
	nodeID domain.NodeRunID,
	kind string,
	targetSchemaDigest string,
) (workflowmodel.EffectOperation, error) {
	node, found, err := transaction.nodeRun(ctx, nodeID)
	if err != nil {
		return workflowmodel.EffectOperation{}, err
	}
	if !found || node.State != domain.NodeRunStateRunning {
		return workflowmodel.EffectOperation{}, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "begin effect", Resource: string(nodeID),
			Message: "effect node is not running",
		}
	}
	run, found, err := transaction.workflowRun(ctx, node.WorkflowRunID)
	if err != nil {
		return workflowmodel.EffectOperation{}, err
	}
	if !found {
		return workflowmodel.EffectOperation{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "begin effect", Resource: string(node.WorkflowRunID),
			Message: "effect workflow run is unavailable",
		}
	}
	definitionRecord, err := transaction.workflowDefinitionAtVersion(ctx, run.WorkflowDefinition, node.DefinitionVersion)
	if err != nil {
		return workflowmodel.EffectOperation{}, err
	}
	definition, err := decodeResolvedDefinition(definitionRecord)
	if err != nil {
		return workflowmodel.EffectOperation{}, err
	}
	if !effectPolicyAllows(definition.Effects, kind, targetSchemaDigest) {
		return workflowmodel.EffectOperation{}, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "begin effect", Resource: string(nodeID),
			Message: "workflow policy denies the outward effect",
		}
	}
	nodeDefinition := definition.Nodes[node.NodeKey]
	template := definition.Templates[nodeDefinition.Template]
	if template.Effects.Mode != "allow" || !template.Effects.RequiresOwnerAuthority {
		return workflowmodel.EffectOperation{}, &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "begin effect", Resource: string(nodeID),
			Message: "workflow policy denies the outward effect",
		}
	}
	for _, operation := range template.Effects.Operations {
		if operation.Kind == kind && operation.TargetSchemaDigest == targetSchemaDigest {
			return operation, nil
		}
	}
	return workflowmodel.EffectOperation{}, &domain.Error{
		Code: domain.ErrorCodeUnauthorized, Op: "begin effect", Resource: kind,
		Message: "workflow policy does not declare this outward effect",
	}
}

func effectPolicyAllows(policy workflowmodel.EffectPolicy, kind string, targetSchemaDigest string) bool {
	if policy.Mode != "allow" || !policy.RequiresOwnerAuthority {
		return false
	}
	for _, operation := range policy.Operations {
		if operation.Kind == kind && operation.TargetSchemaDigest == targetSchemaDigest {
			return true
		}
	}
	return false
}

func (transaction *Tx) effectAuthority(
	ctx context.Context,
	id domain.EffectAuthorityID,
) (domain.EffectAuthority, bool, error) {
	var authority domain.EffectAuthority
	payload, found, err := transaction.recordPayload(ctx, effectAuthorityRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &authority)
		if err != nil {
			err = wrap("decode effect authority", string(id), err)
		}
	}
	return authority, found, err
}

func (transaction *Tx) effectOperation(
	ctx context.Context,
	id domain.OperationID,
) (domain.Operation, bool, error) {
	var operation domain.Operation
	payload, found, err := transaction.recordPayload(ctx, effectOperationRecordKind, string(id))
	if err == nil && found {
		err = json.Unmarshal(payload, &operation)
		if err != nil {
			err = wrap("decode effect operation", string(id), err)
		}
	}
	return operation, found, err
}

func (transaction *Tx) hasIndeterminateEffect(
	ctx context.Context,
	kind string,
	targetDigest string,
) (bool, error) {
	rows, err := transaction.tx.QueryContext(
		ctx,
		"SELECT payload FROM records WHERE kind = ? ORDER BY id",
		effectOperationRecordKind,
	)
	if err != nil {
		return false, wrap("read indeterminate effects", targetDigest, err)
	}
	defer rows.Close()
	for rows.Next() {
		var payload []byte
		if err := rows.Scan(&payload); err != nil {
			return false, wrap("scan indeterminate effect", targetDigest, err)
		}
		var operation domain.Operation
		if err := json.Unmarshal(payload, &operation); err != nil {
			return false, wrap("decode indeterminate effect", targetDigest, err)
		}
		if operation.State == domain.OperationStateIndeterminate &&
			operation.Kind == kind && operation.TargetDigest == targetDigest {
			return true, nil
		}
	}
	if err := rows.Err(); err != nil {
		return false, wrap("iterate indeterminate effects", targetDigest, err)
	}
	return false, nil
}

func (store *Store) recordDeniedEffect(
	ctx context.Context,
	request EffectOperationRequest,
	targetDigest string,
) error {
	return store.Transaction(ctx, func(transaction *Tx) error {
		now := time.Now().UTC()
		return transaction.appendEffectEvent(
			ctx, now, "workflow.effect.denied",
			domain.ResourceReference{Kind: effectOperationRecordKind, ID: string(request.ID)},
			effectEventPayload{
				AuthorityID: request.AuthorityID, OperationID: request.ID,
				Kind: request.Kind, TargetDigest: targetDigest,
			},
			false,
		)
	})
}

func (transaction *Tx) updateCommandRecords(
	ctx context.Context,
	command domain.CommandRecord,
	previousVersion domain.ResourceVersion,
	encoded []byte,
) error {
	if err := transaction.updateRecord(
		ctx, "command", string(command.ID), previousVersion, command.Metadata, encoded,
	); err != nil {
		return err
	}
	return transaction.updateRecord(
		ctx, "command-idempotency", commandIdempotencyID(command.Principal, command.IdempotencyKey),
		previousVersion, command.Metadata, encoded,
	)
}

func (transaction *Tx) appendEffectEvent(
	ctx context.Context,
	now time.Time,
	eventType string,
	aggregate domain.ResourceReference,
	payloadValue effectEventPayload,
	critical bool,
) error {
	payload, err := json.Marshal(payloadValue)
	if err != nil {
		return wrap("encode effect event", aggregate.ID, err)
	}
	_, err = transaction.appendEvent(ctx, domain.EventEnvelope{
		SchemaVersion: domain.CurrentEventSchemaVersion, OccurredAt: now,
		Aggregate: aggregate, Type: eventType, Payload: payload,
	}, critical)
	return err
}

func jsonValueDigest(value json.RawMessage) (string, error) {
	if !json.Valid(value) {
		return "", &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "digest effect target", Resource: "target",
			Message: "effect target is not valid JSON",
		}
	}
	canonical, err := jsoncanonicalizer.Transform(value)
	if err != nil {
		return "", wrap("canonicalize effect target", "target", err)
	}
	digest := sha256.Sum256(canonical)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func effectInputDigest(node domain.NodeRun) (string, error) {
	snapshots := append([]domain.SnapshotID(nil), node.InputSnapshotIDs...)
	sort.Slice(snapshots, func(first int, second int) bool { return snapshots[first] < snapshots[second] })
	encoded, err := json.Marshal(struct {
		NodeDefinitionDigest string              `json:"nodeDefinitionDigest"`
		SnapshotIDs          []domain.SnapshotID `json:"snapshotIds"`
	}{NodeDefinitionDigest: node.NodeDefinitionDigest, SnapshotIDs: snapshots})
	if err != nil {
		return "", wrap("encode effect inputs", string(node.ID), err)
	}
	digest := sha256.Sum256(encoded)
	return fmt.Sprintf("sha256:%x", digest), nil
}

func validSHA256Digest(value string) bool {
	if len(value) != len("sha256:")+sha256.Size*2 || !strings.HasPrefix(value, "sha256:") {
		return false
	}
	decoded, err := hex.DecodeString(strings.TrimPrefix(value, "sha256:"))
	return err == nil && len(decoded) == sha256.Size
}

func validateEffectAuthorityRequest(
	request EffectAuthorityRequest,
	now time.Time,
	limit uint64,
) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.CommandID.Validate(); err != nil {
		return err
	}
	if err := request.NodeRunID.Validate(); err != nil {
		return err
	}
	if err := (domain.ResourceReference{Kind: "effect-kind", ID: request.OperationKind}).Validate(); err != nil {
		return err
	}
	if !strings.HasPrefix(request.Principal, "owner:") {
		return &domain.Error{
			Code: domain.ErrorCodeUnauthorized, Op: "grant effect authority", Resource: request.Principal,
			Message: "effect authority requires an owner principal",
		}
	}
	if !validSHA256Digest(request.InputDigest) || !request.ExpiresAt.After(now) || uint64(len(request.Target)) > limit {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "grant effect authority", Resource: string(request.ID),
			Message: "effect input digest, target size, or expiry is invalid",
		}
	}
	if _, err := jsonValueDigest(request.Target); err != nil {
		return err
	}
	return nil
}

func validateEffectOperationRequest(request EffectOperationRequest, limit uint64) error {
	for _, err := range []error{
		request.ID.Validate(), request.CommandID.Validate(), request.NodeRunID.Validate(), request.AuthorityID.Validate(),
	} {
		if err != nil {
			return err
		}
	}
	if request.PluginID != "" {
		if err := request.PluginID.Validate(); err != nil {
			return err
		}
	}
	if err := (domain.ResourceReference{Kind: "effect-kind", ID: request.Kind}).Validate(); err != nil {
		return err
	}
	if !validSHA256Digest(request.TargetSchemaDigest) || !validSHA256Digest(request.InputDigest) ||
		uint64(len(request.Target)) > limit {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "begin effect", Resource: string(request.ID),
			Message: "effect schema digest, input digest, or target size is invalid",
		}
	}
	if _, err := jsonValueDigest(request.Target); err != nil {
		return err
	}
	return nil
}

func validateEffectReconciliationRequest(request EffectReconciliationRequest) error {
	if err := request.ID.Validate(); err != nil {
		return err
	}
	if err := request.OperationID.Validate(); err != nil {
		return err
	}
	if !strings.HasPrefix(request.Principal, "owner:") ||
		(request.Resolution != "applied" && request.Resolution != "not_applied") ||
		!validSHA256Digest(request.ObservedTargetDigest) {
		return &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "reconcile effect", Resource: string(request.ID),
			Message: "effect resolution, observed digest, or owner principal is invalid",
		}
	}
	return nil
}
