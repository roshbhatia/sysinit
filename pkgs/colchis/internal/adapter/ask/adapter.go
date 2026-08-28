package ask

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
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/external"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	resultmodel "github.com/roshbhatia/sysinit/pkgs/colchis/internal/result"
)

const (
	AdapterID      = "ask"
	OperationStart = "agent-runtime.start"
)

type CommandRunner interface {
	Run(context.Context, external.Request) (external.Result, error)
}

type Config struct {
	Executable          string
	Directory           string
	RuntimeDirectory    string
	Environment         []string
	DangerouslyAllowAll bool
}

type Adapter struct {
	runner CommandRunner
	config Config
}

type StartRequest struct {
	Prompt               string          `json:"prompt"`
	Input                string          `json:"input,omitempty"`
	Provider             string          `json:"provider"`
	Model                string          `json:"model,omitempty"`
	ResponseSchema       json.RawMessage `json:"responseSchema"`
	ResponseSchemaDigest string          `json:"responseSchemaDigest"`
}

type StartResult struct {
	Status   string          `json:"status"`
	Provider string          `json:"provider"`
	Model    string          `json:"model,omitempty"`
	Value    json.RawMessage `json:"value,omitempty"`
	Question string          `json:"question,omitempty"`
	Stderr   string          `json:"stderr,omitempty"`
}

type handleValue struct {
	Status       string `json:"status"`
	Provider     string `json:"provider"`
	Model        string `json:"model,omitempty"`
	ResultDigest string `json:"resultDigest,omitempty"`
	Question     string `json:"question,omitempty"`
}

func New(config Config, runner CommandRunner) (*Adapter, error) {
	if runner == nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "runner", "runner is nil", nil)
	}
	if config.Executable == "" {
		resolved, err := exec.LookPath("ask")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "ask", err.Error(), err)
		}
		config.Executable = resolved
	}
	executable, err := filepath.Abs(config.Executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "ask", "executable path is invalid", err)
	}
	directory, err := filepath.Abs(config.Directory)
	if err != nil || config.Directory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "ask", "working directory is invalid", err)
	}
	runtimeDirectory, err := filepath.Abs(config.RuntimeDirectory)
	if err != nil || config.RuntimeDirectory == "" {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "ask", "runtime directory is invalid", err)
	}
	info, err := os.Stat(runtimeDirectory)
	if err != nil || !info.IsDir() {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, runtimeDirectory, "runtime directory does not exist", err)
	}
	config.Executable = executable
	config.Directory = directory
	config.RuntimeDirectory = runtimeDirectory
	config.Environment = append([]string(nil), config.Environment...)
	return &Adapter{runner: runner, config: config}, nil
}

func NewLocal(directory string, runtimeDirectory string, maxOutputBytes uint64) (*Adapter, error) {
	return New(Config{
		Directory: directory, RuntimeDirectory: runtimeDirectory, Environment: os.Environ(),
		DangerouslyAllowAll: os.Getenv("COLCHIS_PLUGIN_ISOLATION") == "dangerously-allow-all",
	}, external.NewRunner(maxOutputBytes))
}

func (adapter *Adapter) Invoke(
	ctx context.Context,
	envelope plugin.OperationEnvelope,
	emit plugin.EventEmitter,
) (plugin.OperationResult, error) {
	if envelope.Operation != OperationStart {
		return plugin.OperationResult{}, adapterError(
			domain.ErrorCodeNotFound, envelope.Operation, "operation is unknown", nil,
		)
	}
	if err := validateJobPolicy(envelope.JobPolicy, adapter.config.DangerouslyAllowAll); err != nil {
		return plugin.OperationResult{}, err
	}
	request, err := decodeRequest(envelope.Input)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if err := validateIdentifier("provider", request.Provider); err != nil {
		return plugin.OperationResult{}, err
	}
	if request.Model != "" {
		if err := validateIdentifier("model", request.Model); err != nil {
			return plugin.OperationResult{}, err
		}
	}
	validator, err := resultmodel.NewValidator(
		request.ResponseSchema, request.ResponseSchemaDigest, 0, 8<<20,
	)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	schemaPath, err := adapter.writeSchema(request.ResponseSchema)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	defer func() { _ = os.Remove(schemaPath) }()
	if emit != nil {
		if err := emit("agent.started", json.RawMessage(`{"runtime":"ask"}`)); err != nil {
			return plugin.OperationResult{}, err
		}
	}
	arguments := []string{
		"--quiet", "--provider", request.Provider, "--schema", "@" + schemaPath,
	}
	if request.Model != "" {
		arguments = append(arguments, "--model", request.Model)
	}
	if deadline, found := ctx.Deadline(); found {
		remaining := time.Until(deadline)
		if remaining <= 0 {
			return plugin.OperationResult{}, context.DeadlineExceeded
		}
		timeout := remaining.Truncate(time.Second)
		if timeout < time.Second {
			timeout = time.Second
		}
		arguments = append(arguments, "--timeout", timeout.String())
	}
	arguments = append(arguments, "--", request.Prompt)
	commandResult, err := adapter.runner.Run(ctx, external.Request{
		Executable: adapter.config.Executable, Arguments: arguments, Input: []byte(request.Input),
		Directory: adapter.config.Directory, Environment: adapter.config.Environment,
	})
	if err != nil {
		return plugin.OperationResult{}, err
	}
	result := StartResult{Provider: request.Provider, Model: request.Model}
	handle := handleValue{Provider: request.Provider, Model: request.Model}
	switch commandResult.ExitCode {
	case 0:
		value := bytes.TrimSpace(commandResult.Stdout)
		if decision := validator.Validate(value, 0); !decision.Accepted {
			return plugin.OperationResult{}, adapterError(
				domain.ErrorCodeInvalidArgument, request.Provider,
				"ask output violates the requested schema: "+decision.Feedback, nil,
			)
		}
		digest := sha256.Sum256(value)
		result.Status = "completed"
		result.Value = append(json.RawMessage(nil), value...)
		result.Stderr = strings.TrimSpace(string(commandResult.Stderr))
		handle.Status = result.Status
		handle.ResultDigest = fmt.Sprintf("sha256:%x", digest)
	case 3:
		question := questionFromStderr(string(commandResult.Stderr))
		if question == "" {
			return plugin.OperationResult{}, adapterError(
				domain.ErrorCodeInternal, request.Provider, "ask requested input without a question", nil,
			)
		}
		result.Status = "needs-input"
		result.Question = question
		handle.Status = result.Status
		handle.Question = question
	default:
		message := strings.TrimSpace(string(commandResult.Stderr))
		if message == "" {
			message = fmt.Sprintf("ask exited with status %d", commandResult.ExitCode)
		}
		return plugin.OperationResult{}, adapterError(domain.ErrorCodeInternal, request.Provider, message, nil)
	}
	output, err := json.Marshal(result)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	opaque, err := json.Marshal(handle)
	if err != nil {
		return plugin.OperationResult{}, err
	}
	if emit != nil {
		event, marshalErr := json.Marshal(struct {
			Status string `json:"status"`
		}{Status: result.Status})
		if marshalErr != nil {
			return plugin.OperationResult{}, marshalErr
		}
		if err := emit("agent.completed", event); err != nil {
			return plugin.OperationResult{}, err
		}
	}
	return plugin.OperationResult{
		ID: envelope.ID, State: domain.OperationStateSucceeded, SessionState: askSessionState(result.Status),
		Output: output,
		Handle: &plugin.AdapterHandleValue{FormatVersion: 1, OpaqueValue: opaque},
	}, nil
}

func validateJobPolicy(policy *domain.JobPolicy, dangerouslyAllowAll bool) error {
	if policy == nil {
		return adapterError(domain.ErrorCodeInvalidArgument, "job-policy", "job policy is required", nil)
	}
	if err := policy.Validate(); err != nil {
		return err
	}
	filesystem := domain.FilesystemPolicyReadOnly
	network := domain.NetworkPolicyDeny
	if dangerouslyAllowAll {
		filesystem = domain.FilesystemPolicyDangerFullAccess
		network = domain.NetworkPolicyAllow
	}
	if policy.Approvals != domain.ApprovalPolicyNever || policy.Filesystem != filesystem || policy.Network != network {
		return adapterError(
			domain.ErrorCodeInvalidArgument, "job-policy",
			"ask job policy exceeds or conflicts with its plugin isolation profile", nil,
		)
	}
	return nil
}

func askSessionState(status string) domain.SessionState {
	if status == "completed" {
		return domain.SessionStateCompleted
	}
	return domain.SessionStateWaiting
}

func (adapter *Adapter) Reconcile(
	_ context.Context,
	handles []plugin.HandleDescriptor,
) ([]plugin.ReconcileResult, error) {
	results := make([]plugin.ReconcileResult, 0, len(handles))
	for _, descriptor := range handles {
		var handle handleValue
		if err := json.Unmarshal(descriptor.OpaqueValue, &handle); err != nil {
			return nil, adapterError(domain.ErrorCodeInvalidArgument, string(descriptor.ID), "ask handle is invalid", err)
		}
		state := plugin.ReconcileStateOrphaned
		if handle.Status == "completed" {
			state = plugin.ReconcileStateCompleted
		}
		results = append(results, plugin.ReconcileResult{HandleID: descriptor.ID, State: state})
	}
	return results, nil
}

func (adapter *Adapter) writeSchema(schema json.RawMessage) (string, error) {
	file, err := os.CreateTemp(adapter.config.RuntimeDirectory, "ask-schema-*.json")
	if err != nil {
		return "", adapterError(domain.ErrorCodeInternal, "schema", err.Error(), err)
	}
	path := file.Name()
	if err := file.Chmod(0o600); err != nil {
		_ = file.Close()
		_ = os.Remove(path)
		return "", adapterError(domain.ErrorCodeInternal, path, err.Error(), err)
	}
	if _, err := file.Write(schema); err != nil {
		_ = file.Close()
		_ = os.Remove(path)
		return "", adapterError(domain.ErrorCodeInternal, path, err.Error(), err)
	}
	if err := file.Close(); err != nil {
		_ = os.Remove(path)
		return "", adapterError(domain.ErrorCodeInternal, path, err.Error(), err)
	}
	return path, nil
}

func decodeRequest(payload json.RawMessage) (StartRequest, error) {
	var request StartRequest
	decoder := json.NewDecoder(bytes.NewReader(payload))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(&request); err != nil {
		return StartRequest{}, adapterError(domain.ErrorCodeInvalidArgument, "request", err.Error(), err)
	}
	var trailing json.RawMessage
	if err := decoder.Decode(&trailing); err != io.EOF {
		return StartRequest{}, adapterError(domain.ErrorCodeInvalidArgument, "request", "request has trailing JSON", err)
	}
	if request.Prompt == "" || !json.Valid(request.ResponseSchema) || request.ResponseSchemaDigest == "" {
		return StartRequest{}, adapterError(domain.ErrorCodeInvalidArgument, "request", "prompt and response schema are required", nil)
	}
	return request, nil
}

func questionFromStderr(value string) string {
	value = strings.TrimSpace(value)
	const marker = "the agent needs to know:"
	index := strings.Index(value, marker)
	if index < 0 {
		return ""
	}
	return strings.TrimSpace(value[index+len(marker):])
}

func validateIdentifier(kind string, value string) error {
	if strings.HasPrefix(value, "-") {
		return adapterError(domain.ErrorCodeInvalidArgument, value, kind+" cannot begin with a hyphen", nil)
	}
	return (domain.ResourceReference{Kind: kind, ID: value}).Validate()
}

func adapterError(code domain.ErrorCode, resource string, message string, err error) error {
	return &domain.Error{Code: code, Op: "use ask adapter", Resource: resource, Message: message, Err: err}
}
