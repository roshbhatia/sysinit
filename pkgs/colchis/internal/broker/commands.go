package broker

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/api/socket"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/store/sqlite"
)

type AdapterRuntime interface {
	Invoke(context.Context, domain.PluginID, plugin.OperationEnvelope) (plugin.OperationResult, error)
	TrackHandle(domain.PluginID, plugin.HandleDescriptor) error
}

type AdapterInvocationRequest struct {
	PluginID    domain.PluginID
	Owner       domain.ResourceReference
	NewHandleID *domain.AdapterHandleID
	Operation   plugin.OperationEnvelope
}

type AdapterInvocationResult struct {
	Operation plugin.OperationResult
	Handle    *domain.AdapterHandle
}

type AdapterService struct {
	store   *sqlite.Store
	runtime AdapterRuntime
}

func NewAdapterService(store *sqlite.Store, runtime AdapterRuntime) (*AdapterService, error) {
	if store == nil || runtime == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "adapter service",
			Message: "store and runtime are required",
		}
	}
	return &AdapterService{store: store, runtime: runtime}, nil
}

func (service *AdapterService) Invoke(
	ctx context.Context,
	request AdapterInvocationRequest,
) (AdapterInvocationResult, error) {
	if err := request.PluginID.Validate(); err != nil {
		return AdapterInvocationResult{}, err
	}
	if request.NewHandleID != nil && request.Operation.HandleID != nil {
		return AdapterInvocationResult{}, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "invoke adapter", Resource: string(request.Operation.ID),
			Message: "new and existing handle identifiers are mutually exclusive",
		}
	}
	if request.NewHandleID != nil {
		if err := request.Owner.Validate(); err != nil {
			return AdapterInvocationResult{}, err
		}
	}
	result, err := service.runtime.Invoke(ctx, request.PluginID, request.Operation)
	if err != nil {
		return AdapterInvocationResult{}, err
	}
	invocation := AdapterInvocationResult{Operation: result}
	if result.Handle == nil {
		if request.NewHandleID != nil {
			return invocation, &domain.Error{
				Code: domain.ErrorCodeInvalidArgument, Op: "invoke adapter", Resource: string(request.Operation.ID),
				Message: "adapter omitted the requested handle",
			}
		}
		return invocation, nil
	}
	if request.NewHandleID == nil {
		return invocation, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Op: "invoke adapter", Resource: string(request.Operation.ID),
			Message: "adapter returned an unaddressed handle",
		}
	}
	handle, err := service.store.CreateAdapterHandle(ctx, domain.AdapterHandle{
		ID: *request.NewHandleID, Owner: request.Owner, PluginID: request.PluginID, Port: request.Operation.Port,
		AdapterID: request.Operation.AdapterID, FormatVersion: result.Handle.FormatVersion,
		OpaqueValue: result.Handle.OpaqueValue,
	})
	if err != nil {
		return invocation, err
	}
	invocation.Handle = &handle
	err = service.runtime.TrackHandle(request.PluginID, plugin.HandleDescriptor{
		ID: handle.ID, PluginID: handle.PluginID, Port: handle.Port, AdapterID: handle.AdapterID,
		FormatVersion: handle.FormatVersion, OpaqueValue: handle.OpaqueValue,
	})
	return invocation, err
}

type CommandExecutor interface {
	ExecuteCommand(context.Context, socket.Principal, domain.CommandRequest) error
}

type CommandResultExecutor interface {
	ExecuteCommandResult(context.Context, socket.Principal, domain.CommandRequest) (json.RawMessage, error)
}

type CommandExecutorFunc func(context.Context, socket.Principal, domain.CommandRequest) error

func (executor CommandExecutorFunc) ExecuteCommand(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) error {
	return executor(ctx, principal, request)
}

type CommandResultExecutorFunc func(
	context.Context,
	socket.Principal,
	domain.CommandRequest,
) (json.RawMessage, error)

func (executor CommandResultExecutorFunc) ExecuteCommand(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) error {
	_, err := executor(ctx, principal, request)
	return err
}

func (executor CommandResultExecutorFunc) ExecuteCommandResult(
	ctx context.Context,
	principal socket.Principal,
	request domain.CommandRequest,
) (json.RawMessage, error) {
	return executor(ctx, principal, request)
}

type CommandService struct {
	store    *sqlite.Store
	executor CommandExecutor
}

func NewCommandService(store *sqlite.Store, executor CommandExecutor) (*CommandService, error) {
	if store == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command service", Message: "store is nil",
		}
	}
	if executor == nil {
		return nil, &domain.Error{
			Code: domain.ErrorCodeInvalidArgument, Resource: "command service", Message: "executor is nil",
		}
	}
	if err := store.EnableEmergencyReserve(); err != nil {
		return nil, err
	}
	return &CommandService{store: store, executor: executor}, nil
}

func (service *CommandService) RecoverInterruptedCommands(ctx context.Context) error {
	if _, err := service.store.RecoverRunningCommands(ctx); err != nil {
		return err
	}
	if _, err := service.store.RecoverEffectOperations(ctx); err != nil {
		return err
	}
	if _, err := service.store.ReconcileOrphanSnapshotReferences(ctx); err != nil {
		return err
	}
	_, err := service.store.RecoverUnboundNodeReservations(ctx)
	return err
}

func (service *CommandService) HandleCommand(
	ctx context.Context,
	principal socket.Principal,
	request socket.CommandRequest,
) (domain.CommandRecord, error) {
	record, _, err := service.store.AcceptCommand(ctx, principal.Identifier(), request)
	if err != nil {
		return record, err
	}
	record, claimed, err := service.store.ClaimCommand(ctx, record.ID)
	if err != nil {
		return record, err
	}
	if !claimed {
		if record.State == domain.CommandStateSucceeded {
			return record, nil
		}
		message := "command cannot be dispatched from its current state"
		if record.State == domain.CommandStateRunning {
			message = "command is already running"
		}
		if record.State == domain.CommandStateIndeterminate {
			message = "command requires reconciliation before dispatch"
		}
		return record, &domain.Error{
			Code: domain.ErrorCodeConflict, Op: "dispatch", Resource: string(record.ID),
			Message: message,
		}
	}
	var result json.RawMessage
	var executionErr error
	if executor, ok := service.executor.(CommandResultExecutor); ok {
		result, executionErr = executor.ExecuteCommandResult(ctx, principal, request)
	} else {
		executionErr = service.executor.ExecuteCommand(ctx, principal, request)
	}
	if executionErr != nil {
		finishState := domain.CommandStateFailed
		if domain.IsErrorCode(executionErr, domain.ErrorCodeIndeterminate) {
			finishState = domain.CommandStateIndeterminate
		}
		failed, finishErr := service.store.FinishCommand(
			context.Background(), record.ID, finishState,
		)
		if finishErr == nil {
			record = failed
		}
		return record, errors.Join(executionErr, finishErr)
	}
	if result == nil {
		result = json.RawMessage(`null`)
	}
	return service.store.FinishCommand(
		context.Background(), record.ID, domain.CommandStateSucceeded, result,
	)
}
