package seshy

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	WorkspaceAdapterID  = "seshy.workspace"
	AttachmentAdapterID = "seshy.attachment"
	OperationCreate     = "workspace.create"
	OperationAdd        = "workspace.add-repository"
	OperationRemove     = "workspace.remove-repository"
	OperationSnapshot   = "workspace.snapshot"
	OperationOpen       = "attachment.open"
	OperationClose      = "attachment.close"
)

type CommandRunner interface {
	Run(context.Context, external.Request) (external.Result, error)
}

type Config struct {
	Executable  string
	Directory   string
	Environment []string
}

type Adapter struct {
	runner CommandRunner
	config Config
}

type Repository struct {
	Name   string `json:"name"`
	Path   string `json:"path"`
	Branch string `json:"branch,omitempty"`
}

type Workspace struct {
	Name         string       `json:"name"`
	Path         string       `json:"path"`
	Repositories []Repository `json:"repositories"`
}

type attachDocument struct {
	Name  string       `json:"name"`
	Path  string       `json:"path"`
	Repos []Repository `json:"repos"`
}

type WorkspaceResult struct {
	Workspace    Workspace `json:"workspace"`
	SourceDigest string    `json:"sourceDigest"`
}

type AttachmentResult struct {
	Kind         string       `json:"kind"`
	Name         string       `json:"name"`
	Path         string       `json:"path"`
	Repositories []Repository `json:"repositories"`
}

type CloseResult struct {
	Closed bool `json:"closed"`
}

type createRequest struct {
	Name         string   `json:"name"`
	Repositories []string `json:"repositories"`
	Branch       string   `json:"branch,omitempty"`
}

type repositoryRequest struct {
	Name       string `json:"name,omitempty"`
	Repository string `json:"repository"`
	Branch     string `json:"branch,omitempty"`
}

type workspaceRequest struct {
	Name string `json:"name,omitempty"`
}

type handleValue struct {
	Name string `json:"name"`
}

func New(config Config, runner CommandRunner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "create seshy adapter", "runner is nil", nil)
	}
	if config.Executable == "" {
		resolved, err := exec.LookPath("sy")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "find seshy", err.Error(), err)
		}
		config.Executable = resolved
	}
	executable, err := filepath.Abs(config.Executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "configure seshy", err.Error(), err)
	}
	directory, err := filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "configure seshy", "working directory is invalid", err)
	}
	config.Executable = executable
	config.Directory = directory
	config.Environment = append([]string(nil), config.Environment...)
	return &Adapter{runner: runner, config: config}, nil
}

func NewLocal(directory string, maxOutputBytes uint64) (*Adapter, error) {
	return New(Config{Directory: directory, Environment: os.Environ()}, external.NewRunner(maxOutputBytes))
}

func (adapter *Adapter) Invoke(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
	_ plugin.EventEmitter,
) (plugin.OperationResult, error) {
	var output json.RawMessage
	var handle *plugin.AdapterHandleValue
	var err error
	switch envelope.Operation {
	case OperationCreate:
		output, handle, err = adapter.create(ctx, envelope.Input)
	case OperationAdd:
		output, err = adapter.add(ctx, envelope)
	case OperationRemove:
		output, err = adapter.remove(ctx, envelope)
	case OperationSnapshot:
		output, err = adapter.snapshot(ctx, envelope)
	case OperationOpen:
		output, err = adapter.open(ctx, envelope)
	case OperationClose:
		output, err = json.Marshal(CloseResult{Closed: true})
	default:
		err = adapterError(domain.ErrorCodeNotFound, envelope.Operation, "operation is unknown", nil)
	}
	if err != nil {
		return plugin.OperationResult{}, err
	}
	return plugin.OperationResult{
		ID: envelope.ID, State: domain.OperationStateSucceeded, Output: output, Handle: handle,
	}, nil
}

func (adapter *Adapter) Reconcile(
	ctx context.Context,
	handles []plugin.HandleDescriptor,
) ([]plugin.ReconcileResult, error) {
	results := make([]plugin.ReconcileResult, 0, len(handles))
	for _, descriptor := range handles {
		if descriptor.AdapterID != WorkspaceAdapterID || descriptor.Port != domain.AdapterPortWorkspace {
			results = append(results, plugin.ReconcileResult{
				HandleID: descriptor.ID, State: plugin.ReconcileStateOrphaned,
			})
			continue
		}
		name, err := workspaceName("", &descriptor)
		if err != nil {
			return nil, err
		}
		state := plugin.ReconcileStateAdopted
		if _, err := adapter.snapshotName(ctx, name); err != nil {
			state = plugin.ReconcileStateOrphaned
		}
		results = append(results, plugin.ReconcileResult{HandleID: descriptor.ID, State: state})
	}
	return results, nil
}

func (adapter *Adapter) create(
	ctx context.Context,
	payload json.RawMessage,
) (json.RawMessage, *plugin.AdapterHandleValue, error) {
	request, err := decodeRequest[createRequest](payload)
	if err != nil {
		return nil, nil, err
	}
	if err := validateName(request.Name); err != nil {
		return nil, nil, err
	}
	arguments := []string{"new", request.Name}
	if request.Branch != "" {
		arguments = append(arguments, "--branch", request.Branch)
	}
	if len(request.Repositories) == 0 {
		arguments = append(arguments, "--empty")
	} else {
		for _, repository := range request.Repositories {
			if err := validateRepository(repository); err != nil {
				return nil, nil, err
			}
		}
		arguments = append(arguments, request.Repositories...)
	}
	if _, err := adapter.run(ctx, arguments...); err != nil {
		return nil, nil, err
	}
	output, err := adapter.snapshotName(ctx, request.Name)
	if err != nil {
		return nil, nil, err
	}
	opaque, err := json.Marshal(handleValue{Name: request.Name})
	if err != nil {
		return nil, nil, err
	}
	return output, &plugin.AdapterHandleValue{FormatVersion: 1, OpaqueValue: opaque}, nil
}

func (adapter *Adapter) add(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[repositoryRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	name, err := workspaceName(request.Name, envelope.Handle)
	if err != nil {
		return nil, err
	}
	if err := validateRepository(request.Repository); err != nil {
		return nil, err
	}
	arguments := []string{"add", name}
	if request.Branch != "" {
		arguments = append(arguments, "--branch", request.Branch)
	}
	arguments = append(arguments, request.Repository)
	if _, err := adapter.run(ctx, arguments...); err != nil {
		return nil, err
	}
	return adapter.snapshotName(ctx, name)
}

func (adapter *Adapter) remove(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[repositoryRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	name, err := workspaceName(request.Name, envelope.Handle)
	if err != nil {
		return nil, err
	}
	if err := validateName(request.Repository); err != nil {
		return nil, err
	}
	if _, err := adapter.run(ctx, "remove", "--force", name, request.Repository); err != nil {
		return nil, err
	}
	return adapter.snapshotName(ctx, name)
}

func (adapter *Adapter) snapshot(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[workspaceRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	name, err := workspaceName(request.Name, envelope.Handle)
	if err != nil {
		return nil, err
	}
	return adapter.snapshotName(ctx, name)
}

func (adapter *Adapter) open(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[workspaceRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	name, err := workspaceName(request.Name, envelope.Handle)
	if err != nil {
		return nil, err
	}
	payload, err := adapter.attach(ctx, name)
	if err != nil {
		return nil, err
	}
	workspace, err := decodeAttachment(payload, name)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "seshy returned invalid attachment JSON", err)
	}
	return json.Marshal(AttachmentResult{
		Kind: "terminal", Name: workspace.Name, Path: workspace.Path, Repositories: workspace.Repositories,
	})
}

func (adapter *Adapter) snapshotName(ctx context.Context, name string) (json.RawMessage, error) {
	payload, err := adapter.attach(ctx, name)
	if err != nil {
		return nil, err
	}
	workspace, err := decodeAttachment(payload, name)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "seshy returned invalid attachment JSON", err)
	}
	digest := sha256.Sum256(payload)
	return json.Marshal(WorkspaceResult{
		Workspace: workspace, SourceDigest: fmt.Sprintf("sha256:%x", digest),
	})
}

func decodeAttachment(payload json.RawMessage, expectedName string) (Workspace, error) {
	var document attachDocument
	if err := json.Unmarshal(payload, &document); err != nil {
		return Workspace{}, err
	}
	if document.Name != expectedName || document.Path == "" {
		return Workspace{}, fmt.Errorf("attachment identity does not match")
	}
	repositories := document.Repos
	if repositories == nil {
		repositories = []Repository{}
	}
	for _, repository := range repositories {
		if repository.Name == "" || repository.Path == "" {
			return Workspace{}, fmt.Errorf("attachment repository is incomplete")
		}
	}
	return Workspace{Name: document.Name, Path: document.Path, Repositories: repositories}, nil
}

func (adapter *Adapter) attach(ctx context.Context, name string) (json.RawMessage, error) {
	if err := validateName(name); err != nil {
		return nil, err
	}
	result, err := adapter.run(ctx, "attach", name)
	if err != nil {
		return nil, err
	}
	if !json.Valid(result.Stdout) {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "seshy returned invalid JSON", nil)
	}
	return append(json.RawMessage(nil), result.Stdout...), nil
}

func (adapter *Adapter) run(ctx context.Context, arguments ...string) (external.Result, error) {
	result, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.Executable, Arguments: arguments, Directory: adapter.config.Directory,
		Environment: adapter.config.Environment,
	})
	if err != nil {
		return result, err
	}
	if result.ExitCode != 0 {
		message := strings.TrimSpace(string(result.Stderr))
		if message == "" {
			message = fmt.Sprintf("seshy exited with status %d", result.ExitCode)
		}
		return result, adapterError(domain.ErrorCodeInternal, strings.Join(arguments, " "), message, nil)
	}
	return result, nil
}

func workspaceName(explicit string, handle *plugin.HandleDescriptor) (string, error) {
	if explicit != "" {
		if err := validateName(explicit); err != nil {
			return "", err
		}
		if handle != nil {
			var value handleValue
			if err := json.Unmarshal(handle.OpaqueValue, &value); err != nil || value.Name != explicit {
				return "", adapterError(domain.ErrorCodeConflict, explicit, "workspace handle and request differ", err)
			}
		}
		return explicit, nil
	}
	if handle == nil {
		return "", adapterError(domain.ErrorCodeInvalidArgument, "workspace", "workspace name or handle is required", nil)
	}
	var value handleValue
	if err := json.Unmarshal(handle.OpaqueValue, &value); err != nil {
		return "", adapterError(domain.ErrorCodeInvalidArgument, string(handle.ID), "workspace handle is invalid", err)
	}
	if err := validateName(value.Name); err != nil {
		return "", err
	}
	return value.Name, nil
}

func validateName(value string) error {
	if strings.HasPrefix(value, "-") {
		return adapterError(domain.ErrorCodeInvalidArgument, value, "name cannot begin with a hyphen", nil)
	}
	return (domain.ResourceReference{Kind: "seshy-name", ID: value}).Validate()
}

func validateRepository(value string) error {
	if value == "" || strings.HasPrefix(value, "-") {
		return adapterError(domain.ErrorCodeInvalidArgument, value, "repository is invalid", nil)
	}
	return nil
}

type requestDocument interface {
	createRequest | repositoryRequest | workspaceRequest
}

func decodeRequest[Request requestDocument](payload json.RawMessage) (Request, error) {
	var request Request
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", err.Error(), err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return request, adapterError(domain.ErrorCodeInvalidArgument, "request", "request has trailing JSON", err)
	}
	return request, nil
}

func adapterError(code domain.ErrorCode, resource string, message string, err error) error {
	return &domain.Error{Code: code, Op: "use seshy adapter", Resource: resource, Message: message, Err: err}
}
