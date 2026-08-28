package nix

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const (
	AdapterID        = "nix"
	OperationResolve = "environment.resolve"
	OperationExecute = "environment.execute"
	OperationCheck   = "environment.check"
)

type CommandRunner interface {
	Run(context.Context, external.Request) (external.Result, error)
}

type Config struct {
	Executable  string
	Directory   string
	Environment []string
	Secrets     map[string]string
}

type Adapter struct {
	runner CommandRunner
	config Config
}

type ResolveRequest struct {
	Workspace      string `json:"workspace"`
	FlakeReference string `json:"flakeReference,omitempty"`
	Shell          string `json:"shell"`
	SnapshotDigest string `json:"snapshotDigest"`
}

type ExecuteRequest struct {
	Command                []string `json:"command"`
	Stdin                  string   `json:"stdin,omitempty"`
	SecretNames            []string `json:"secretNames"`
	ExpectedSnapshotDigest string   `json:"expectedSnapshotDigest"`
}

type CheckRequest struct {
	Checks                 []string `json:"checks"`
	ExpectedSnapshotDigest string   `json:"expectedSnapshotDigest"`
}

type Environment struct {
	ID             string          `json:"id"`
	System         string          `json:"system"`
	FlakeReference string          `json:"flakeReference"`
	Shell          string          `json:"shell"`
	Derivation     string          `json:"derivation"`
	LockDigest     string          `json:"lockDigest"`
	SnapshotDigest string          `json:"snapshotDigest"`
	Sandbox        string          `json:"sandbox"`
	OpaqueMetadata json.RawMessage `json:"opaqueMetadata"`
}

type ResolveResult struct {
	Environment Environment `json:"environment"`
}

type ExecuteResult struct {
	EnvironmentID  string `json:"environmentId"`
	SnapshotDigest string `json:"snapshotDigest"`
	ExitCode       int    `json:"exitCode"`
	Stdout         string `json:"stdout"`
	Stderr         string `json:"stderr"`
}

type CheckResult struct {
	Name     string          `json:"name"`
	ExitCode int             `json:"exitCode"`
	Build    json.RawMessage `json:"build"`
	Stderr   string          `json:"stderr"`
}

type ChecksResult struct {
	EnvironmentID  string        `json:"environmentId"`
	SnapshotDigest string        `json:"snapshotDigest"`
	Checks         []CheckResult `json:"checks"`
}

type handleValue struct {
	EnvironmentID  string `json:"environmentId"`
	Workspace      string `json:"workspace"`
	WorkspaceState string `json:"workspaceState"`
	System         string `json:"system"`
	FlakeReference string `json:"flakeReference"`
	Shell          string `json:"shell"`
	Derivation     string `json:"derivation"`
	SnapshotDigest string `json:"snapshotDigest"`
}

type metadataDocument struct {
	Fingerprint string          `json:"fingerprint"`
	Locks       json.RawMessage `json:"locks"`
	Locked      json.RawMessage `json:"locked"`
	ResolvedURL string          `json:"resolvedUrl"`
}

func New(config Config, runner CommandRunner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "runner", "runner is nil", nil)
	}
	if config.Executable == "" {
		resolved, err := exec.LookPath("nix")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "nix", err.Error(), err)
		}
		config.Executable = resolved
	}
	executable, err := filepath.Abs(config.Executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "nix", "executable path is invalid", err)
	}
	directory, err := filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "nix", "working directory is invalid", err)
	}
	config.Executable = executable
	config.Directory = directory
	config.Environment = append([]string(nil), config.Environment...)
	config.Secrets = cloneSecrets(config.Secrets)
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
	case OperationResolve:
		output, handle, err = adapter.resolve(ctx, envelope.Input)
	case OperationExecute:
		output, err = adapter.execute(ctx, envelope)
	case OperationCheck:
		output, err = adapter.check(ctx, envelope)
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
	_ context.Context,
	handles []plugin.HandleDescriptor,
) ([]plugin.ReconcileResult, error) {
	results := make([]plugin.ReconcileResult, 0, len(handles))
	for _, descriptor := range handles {
		var encoded handleValue
		if err := json.Unmarshal(descriptor.OpaqueValue, &encoded); err != nil {
			return nil, adapterError(
				domain.ErrorCodeInvalidArgument, string(descriptor.ID), "environment handle is invalid", err,
			)
		}
		handle, err := environmentHandle(&descriptor, encoded.SnapshotDigest)
		if err != nil {
			if domain.IsErrorCode(err, domain.ErrorCodeConflict) ||
				domain.IsErrorCode(err, domain.ErrorCodeUnsupportedVersion) {
				results = append(results, plugin.ReconcileResult{
					HandleID: descriptor.ID, State: plugin.ReconcileStateOrphaned,
				})
				continue
			}
			return nil, err
		}
		state := plugin.ReconcileStateAdopted
		if err := validateWorkspaceState(handle); err != nil {
			if domain.IsErrorCode(err, domain.ErrorCodeConflict) {
				state = plugin.ReconcileStateOrphaned
			} else {
				return nil, err
			}
		}
		results = append(results, plugin.ReconcileResult{HandleID: descriptor.ID, State: state})
	}
	return results, nil
}

func (adapter *Adapter) resolve(
	ctx context.Context,
	payload json.RawMessage,
) (json.RawMessage, *plugin.AdapterHandleValue, error) {
	request, err := decodeRequest[ResolveRequest](payload)
	if err != nil {
		return nil, nil, err
	}
	if err := validateDigest(request.SnapshotDigest); err != nil {
		return nil, nil, err
	}
	if err := validateIdentifier("shell", request.Shell); err != nil {
		return nil, nil, err
	}
	workspace, err := filepath.Abs(request.Workspace)
	if err != nil || request.Workspace == "" {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, request.Workspace, "workspace path is invalid", err)
	}
	workspace, err = filepath.EvalSymlinks(workspace)
	if err != nil {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, request.Workspace, "workspace is unavailable", err)
	}
	workspaceState, err := workspaceFingerprint(workspace)
	if err != nil {
		return nil, nil, err
	}
	reference := request.FlakeReference
	if reference == "" {
		reference = "path:" + workspace
	}
	if strings.HasPrefix(reference, "-") {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, reference, "flake reference is invalid", nil)
	}
	metadataResult, err := adapter.runSuccess(ctx, adapter.config.Environment,
		"flake", "metadata", "--json", "--no-write-lock-file", reference,
	)
	if err != nil {
		return nil, nil, err
	}
	var metadata metadataDocument
	if err := json.Unmarshal(metadataResult.Stdout, &metadata); err != nil || !json.Valid(metadata.Locks) {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, reference, "Nix metadata is incomplete", err)
	}
	systemResult, err := adapter.runSuccess(
		ctx, adapter.config.Environment, "eval", "--raw", "--impure", "--expr", "builtins.currentSystem",
	)
	if err != nil {
		return nil, nil, err
	}
	system := strings.TrimSpace(string(systemResult.Stdout))
	if err := validateIdentifier("system", system); err != nil {
		return nil, nil, err
	}
	attribute := fmt.Sprintf("%s#devShells.%s.%s.drvPath", reference, system, request.Shell)
	derivationResult, err := adapter.runSuccess(
		ctx, adapter.config.Environment, "eval", "--raw", "--no-write-lock-file", attribute,
	)
	if err != nil {
		return nil, nil, err
	}
	derivation := strings.TrimSpace(string(derivationResult.Stdout))
	if !strings.HasPrefix(derivation, "/nix/store/") {
		return nil, nil, adapterError(domain.ErrorCodeInvalidArgument, attribute, "Nix returned an invalid derivation", nil)
	}
	lockHash := sha256.Sum256(metadata.Locks)
	lockDigest := fmt.Sprintf("sha256:%x", lockHash)
	environmentHash := sha256.Sum256([]byte(strings.Join([]string{
		system, reference, request.Shell, derivation, lockDigest, request.SnapshotDigest, workspaceState,
	}, "\x00")))
	environmentID := fmt.Sprintf("sha256:%x", environmentHash)
	opaqueMetadata, err := json.Marshal(struct {
		Fingerprint string          `json:"fingerprint"`
		Locked      json.RawMessage `json:"locked"`
		ResolvedURL string          `json:"resolvedUrl"`
	}{Fingerprint: metadata.Fingerprint, Locked: metadata.Locked, ResolvedURL: metadata.ResolvedURL})
	if err != nil {
		return nil, nil, err
	}
	environment := Environment{
		ID: environmentID, System: system, FlakeReference: reference, Shell: request.Shell,
		Derivation: derivation, LockDigest: lockDigest, SnapshotDigest: request.SnapshotDigest,
		Sandbox: "nix-develop", OpaqueMetadata: opaqueMetadata,
	}
	output, err := json.Marshal(ResolveResult{Environment: environment})
	if err != nil {
		return nil, nil, err
	}
	opaqueHandle, err := json.Marshal(handleValue{
		EnvironmentID: environmentID, Workspace: workspace, WorkspaceState: workspaceState,
		System: system, FlakeReference: reference,
		Shell: request.Shell, Derivation: derivation, SnapshotDigest: request.SnapshotDigest,
	})
	if err != nil {
		return nil, nil, err
	}
	return output, &plugin.AdapterHandleValue{FormatVersion: 2, OpaqueValue: opaqueHandle}, nil
}

func (adapter *Adapter) execute(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[ExecuteRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	handle, err := environmentHandle(envelope.Handle, request.ExpectedSnapshotDigest)
	if err != nil {
		return nil, err
	}
	if err := validateWorkspaceState(handle); err != nil {
		return nil, err
	}
	if len(request.Command) == 0 || request.Command[0] == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "command", "command is empty", nil)
	}
	environment, err := adapter.environment(request.SecretNames)
	if err != nil {
		return nil, err
	}
	installable := handle.FlakeReference + "#" + handle.Shell
	arguments := append([]string{"develop", installable, "--command"}, request.Command...)
	result, err := adapter.runInputIn(ctx, handle.Workspace, environment, []byte(request.Stdin), arguments...)
	if err != nil {
		return nil, err
	}
	return json.Marshal(ExecuteResult{
		EnvironmentID: handle.EnvironmentID, SnapshotDigest: handle.SnapshotDigest,
		ExitCode: result.ExitCode, Stdout: string(result.Stdout), Stderr: string(result.Stderr),
	})
}

func (adapter *Adapter) check(ctx context.Context, envelope plugin.OperationEnvelope) (json.RawMessage, error) {
	request, err := decodeRequest[CheckRequest](envelope.Input)
	if err != nil {
		return nil, err
	}
	handle, err := environmentHandle(envelope.Handle, request.ExpectedSnapshotDigest)
	if err != nil {
		return nil, err
	}
	if err := validateWorkspaceState(handle); err != nil {
		return nil, err
	}
	if len(request.Checks) == 0 {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "checks", "checks are empty", nil)
	}
	checks := make([]CheckResult, 0, len(request.Checks))
	seen := make(map[string]struct{}, len(request.Checks))
	for _, name := range request.Checks {
		if err := validateIdentifier("check", name); err != nil {
			return nil, err
		}
		if _, found := seen[name]; found {
			return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "check is duplicated", nil)
		}
		seen[name] = struct{}{}
		installable := fmt.Sprintf("%s#checks.%s.%s", handle.FlakeReference, handle.System, name)
		result, err := adapter.runIn(
			ctx, handle.Workspace, adapter.config.Environment,
			"build", "--no-link", "--json", "--no-write-lock-file", installable,
		)
		if err != nil {
			return nil, err
		}
		build := json.RawMessage(`[]`)
		if len(result.Stdout) > 0 {
			if !json.Valid(result.Stdout) {
				return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "Nix build returned invalid JSON", nil)
			}
			build = append(json.RawMessage(nil), result.Stdout...)
		}
		checks = append(checks, CheckResult{
			Name: name, ExitCode: result.ExitCode, Build: build, Stderr: string(result.Stderr),
		})
	}
	return json.Marshal(ChecksResult{
		EnvironmentID: handle.EnvironmentID, SnapshotDigest: handle.SnapshotDigest, Checks: checks,
	})
}

func (adapter *Adapter) environment(secretNames []string) ([]string, error) {
	names := append([]string(nil), secretNames...)
	sort.Strings(names)
	for index, name := range names {
		if name == "" || index > 0 && names[index-1] == name {
			return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "secret names must be nonempty and unique", nil)
		}
		if strings.ContainsAny(name, "=\x00") {
			return nil, adapterError(domain.ErrorCodeInvalidArgument, name, "secret name is invalid", nil)
		}
		if _, found := adapter.config.Secrets[name]; !found {
			return nil, adapterError(domain.ErrorCodeUnauthorized, name, "secret is not configured", nil)
		}
	}
	environment := append([]string(nil), adapter.config.Environment...)
	for _, name := range names {
		environment = append(environment, name+"="+adapter.config.Secrets[name])
	}
	return environment, nil
}

func environmentHandle(
	descriptor *plugin.HandleDescriptor,
	expectedSnapshotDigest string,
) (handleValue, error) {
	if descriptor == nil {
		return handleValue{}, adapterError(domain.ErrorCodeInvalidArgument, "environment", "environment handle is required", nil)
	}
	if descriptor.FormatVersion != 2 {
		return handleValue{}, adapterError(
			domain.ErrorCodeUnsupportedVersion, string(descriptor.ID), "environment handle format is unsupported", nil,
		)
	}
	var handle handleValue
	if err := json.Unmarshal(descriptor.OpaqueValue, &handle); err != nil {
		return handleValue{}, adapterError(domain.ErrorCodeInvalidArgument, string(descriptor.ID), "environment handle is invalid", err)
	}
	if err := validateDigest(expectedSnapshotDigest); err != nil {
		return handleValue{}, err
	}
	if handle.EnvironmentID == "" || handle.FlakeReference == "" || handle.Shell == "" ||
		handle.Workspace == "" || handle.WorkspaceState == "" || handle.System == "" ||
		!strings.HasPrefix(handle.Derivation, "/nix/store/") ||
		handle.SnapshotDigest != expectedSnapshotDigest {
		return handleValue{}, adapterError(domain.ErrorCodeConflict, string(descriptor.ID), "environment handle is stale or incomplete", nil)
	}
	return handle, nil
}

func validateWorkspaceState(handle handleValue) error {
	current, err := workspaceFingerprint(handle.Workspace)
	if err != nil {
		return err
	}
	if current != handle.WorkspaceState {
		return adapterError(
			domain.ErrorCodeConflict, handle.Workspace, "workspace changed after environment resolution", nil,
		)
	}
	return nil
}

func workspaceFingerprint(root string) (string, error) {
	digest := sha256.New()
	entries := uint64(0)
	bytesRead := uint64(0)
	err := filepath.WalkDir(root, func(path string, entry os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		entries++
		if entries > 100000 {
			return adapterError(domain.ErrorCodeBudgetExhausted, root, "workspace file limit is reached", nil)
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		_, _ = fmt.Fprintf(digest, "%s\x00%s\x00", filepath.ToSlash(relative), info.Mode().String())
		if info.Mode()&os.ModeSymlink != 0 {
			target, err := os.Readlink(path)
			if err != nil {
				return err
			}
			_, _ = io.WriteString(digest, target)
			return nil
		}
		if !info.Mode().IsRegular() {
			return nil
		}
		bytesRead += uint64(info.Size())
		if bytesRead > 8<<30 {
			return adapterError(domain.ErrorCodeBudgetExhausted, root, "workspace byte limit is reached", nil)
		}
		file, err := os.Open(path)
		if err != nil {
			return err
		}
		_, copyErr := io.Copy(digest, file)
		return errors.Join(copyErr, file.Close())
	})
	if err != nil {
		var domainErr *domain.Error
		if errors.As(err, &domainErr) {
			return "", err
		}
		return "", adapterError(domain.ErrorCodeInternal, root, "workspace cannot be fingerprinted", err)
	}
	return fmt.Sprintf("sha256:%x", digest.Sum(nil)), nil
}

func (adapter *Adapter) run(
	ctx context.Context,
	environment []string,
	arguments ...string,
) (external.Result, error) {
	return adapter.runInput(ctx, environment, nil, arguments...)
}

func (adapter *Adapter) runIn(
	ctx context.Context,
	directory string,
	environment []string,
	arguments ...string,
) (external.Result, error) {
	return adapter.runInputIn(ctx, directory, environment, nil, arguments...)
}

func (adapter *Adapter) runSuccess(
	ctx context.Context,
	environment []string,
	arguments ...string,
) (external.Result, error) {
	result, err := adapter.run(ctx, environment, arguments...)
	if err != nil {
		return result, err
	}
	if result.ExitCode != 0 {
		message := strings.TrimSpace(string(result.Stderr))
		if message == "" {
			message = fmt.Sprintf("Nix exited with status %d", result.ExitCode)
		}
		return result, adapterError(domain.ErrorCodeInternal, strings.Join(arguments, " "), message, nil)
	}
	return result, nil
}

func (adapter *Adapter) runInput(
	ctx context.Context,
	environment []string,
	input []byte,
	arguments ...string,
) (external.Result, error) {
	return adapter.runInputIn(ctx, adapter.config.Directory, environment, input, arguments...)
}

func (adapter *Adapter) runInputIn(
	ctx context.Context,
	directory string,
	environment []string,
	input []byte,
	arguments ...string,
) (external.Result, error) {
	result, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.Executable, Arguments: arguments, Input: input,
		Directory: directory, Environment: environment,
	})
	if err != nil {
		return result, err
	}
	return result, nil
}

type requestDocument interface {
	ResolveRequest | ExecuteRequest | CheckRequest
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

func validateIdentifier(kind string, value string) error {
	if strings.HasPrefix(value, "-") {
		return adapterError(domain.ErrorCodeInvalidArgument, value, kind+" cannot begin with a hyphen", nil)
	}
	return (domain.ResourceReference{Kind: kind, ID: value}).Validate()
}

func validateDigest(value string) error {
	if !strings.HasPrefix(value, "sha256:") || len(value) != len("sha256:")+64 {
		return adapterError(domain.ErrorCodeInvalidArgument, value, "snapshot digest is invalid", nil)
	}
	for _, character := range strings.TrimPrefix(value, "sha256:") {
		if character < '0' || character > '9' && character < 'a' || character > 'f' {
			return adapterError(domain.ErrorCodeInvalidArgument, value, "snapshot digest is invalid", nil)
		}
	}
	return nil
}

func cloneSecrets(secrets map[string]string) map[string]string {
	cloned := make(map[string]string, len(secrets))
	for name, value := range secrets {
		cloned[name] = value
	}
	return cloned
}

func adapterError(code domain.ErrorCode, resource string, message string, err error) error {
	return &domain.Error{Code: code, Op: "use Nix adapter", Resource: resource, Message: message, Err: err}
}
