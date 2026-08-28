package openspec

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const defaultMaxOutputBytes uint64 = 4 << 20

type Runner interface {
	RunJSON(context.Context, ...string) (json.RawMessage, error)
}

type CLIRunner struct {
	executable       string
	workingDirectory string
	maxOutputBytes   uint64
}

func NewCLIRunner(executable string, workingDirectory string, maxOutputBytes uint64) (*CLIRunner, error) {
	if executable == "" {
		resolved, err := exec.LookPath("openspec")
		if err != nil {
			return nil, adapterError(domain.ErrorCodeNotFound, "find OpenSpec CLI", "openspec", err.Error(), err)
		}
		executable = resolved
	}
	absoluteExecutable, err := filepath.Abs(executable)
	if err != nil {
		return nil, adapterError(domain.ErrorCodeInvalidArgument, "configure OpenSpec CLI", executable, err.Error(), err)
	}
	absoluteWorkingDirectory, err := filepath.Abs(workingDirectory)
	if err != nil || workingDirectory == "" {
		return nil, adapterError(
			domain.ErrorCodeInvalidArgument, "configure OpenSpec CLI", workingDirectory,
			"working directory is invalid", err,
		)
	}
	if maxOutputBytes == 0 {
		maxOutputBytes = defaultMaxOutputBytes
	}
	return &CLIRunner{
		executable: absoluteExecutable, workingDirectory: absoluteWorkingDirectory,
		maxOutputBytes: maxOutputBytes,
	}, nil
}

func (runner *CLIRunner) RunJSON(ctx context.Context, arguments ...string) (json.RawMessage, error) {
	command := exec.Command(runner.executable, arguments...)
	command.Dir = runner.workingDirectory
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdout := &boundedOutput{remaining: runner.maxOutputBytes}
	stderr := &boundedOutput{remaining: runner.maxOutputBytes}
	command.Stdout = stdout
	command.Stderr = stderr
	if err := command.Start(); err != nil {
		return nil, adapterError(domain.ErrorCodeInternal, "run OpenSpec CLI", runner.executable, err.Error(), err)
	}
	supervisor, err := plugin.SuperviseStartedCommand(command)
	if err != nil {
		_ = syscall.Kill(-command.Process.Pid, syscall.SIGKILL)
		_ = command.Wait()
		return nil, adapterError(domain.ErrorCodeInternal, "supervise OpenSpec CLI", runner.executable, err.Error(), err)
	}
	waited := make(chan error, 1)
	go func() { waited <- supervisor.Wait() }()
	select {
	case err = <-waited:
	case <-ctx.Done():
		terminateErr := supervisor.Terminate()
		waitErr := <-waited
		err = errors.Join(ctx.Err(), terminateErr, waitErr)
	}
	if stdout.truncated {
		return nil, adapterError(
			domain.ErrorCodeBudgetExhausted, "read OpenSpec CLI", runner.executable,
			"JSON output exceeded its byte limit", nil,
		)
	}
	if err != nil {
		if unavailableInstruction(arguments, stdout.Bytes()) {
			return nil, adapterError(
				domain.ErrorCodeNotFound, "run OpenSpec CLI", arguments[1],
				"selected schema does not expose this instruction", err,
			)
		}
		message := stderr.String()
		if message == "" {
			message = err.Error()
		}
		return nil, adapterError(domain.ErrorCodeInternal, "run OpenSpec CLI", runner.executable, message, err)
	}
	payload := stdout.Bytes()
	if !json.Valid(payload) {
		return nil, adapterError(
			domain.ErrorCodeInvalidArgument, "decode OpenSpec CLI", runner.executable,
			"command returned invalid JSON", nil,
		)
	}
	return append(json.RawMessage(nil), payload...), nil
}

func unavailableInstruction(arguments []string, payload []byte) bool {
	if len(arguments) < 2 || arguments[0] != "instructions" || !json.Valid(payload) {
		return false
	}
	var response struct {
		Status []struct {
			Severity string `json:"severity"`
			Code     string `json:"code"`
			Message  string `json:"message"`
		} `json:"status"`
	}
	if err := json.Unmarshal(payload, &response); err != nil {
		return false
	}
	prefix := "Artifact '" + arguments[1] + "' not found in schema '"
	for _, status := range response.Status {
		if status.Severity == "error" && status.Code == "change_error" && strings.HasPrefix(status.Message, prefix) {
			return true
		}
	}
	return false
}

type boundedOutput struct {
	buffer    bytes.Buffer
	remaining uint64
	truncated bool
}

func (output *boundedOutput) Write(value []byte) (int, error) {
	requested := len(value)
	if uint64(requested) > output.remaining {
		value = value[:output.remaining]
		output.truncated = true
	}
	_, _ = output.buffer.Write(value)
	output.remaining -= uint64(len(value))
	return requested, nil
}

func (output *boundedOutput) Bytes() []byte {
	return append([]byte(nil), output.buffer.Bytes()...)
}

func (output *boundedOutput) String() string {
	return output.buffer.String()
}

func adapterError(
	code domain.ErrorCode,
	operation string,
	resource string,
	message string,
	err error,
) error {
	return &domain.Error{Code: code, Op: operation, Resource: resource, Message: message, Err: err}
}
