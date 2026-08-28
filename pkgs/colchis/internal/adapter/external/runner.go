package external

import (
	"bytes"
	"context"
	"errors"
	"os/exec"
	"path/filepath"
	"syscall"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const defaultMaxBytes uint64 = 8 << 20

type Request struct {
	Executable  string
	Arguments   []string
	Input       []byte
	Directory   string
	Environment []string
}

type Result struct {
	Stdout   []byte
	Stderr   []byte
	ExitCode int
}

type Runner struct {
	maxBytes uint64
}

func NewRunner(maxBytes uint64) *Runner {
	if maxBytes == 0 {
		maxBytes = defaultMaxBytes
	}
	return &Runner{maxBytes: maxBytes}
}

func (runner *Runner) Run(ctx context.Context, request Request) (Result, error) {
	if request.Executable == "" || request.Directory == "" {
		return Result{}, invalidRequest("executable and working directory are required", nil)
	}
	executable, err := filepath.Abs(request.Executable)
	if err != nil {
		return Result{}, invalidRequest("executable path is invalid", err)
	}
	directory, err := filepath.Abs(request.Directory)
	if err != nil {
		return Result{}, invalidRequest("working directory is invalid", err)
	}
	if uint64(len(request.Input)) > runner.maxBytes {
		return Result{}, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "run external adapter", Resource: executable,
			Message: "command input exceeded its byte limit",
		}
	}
	command := exec.Command(executable, request.Arguments...)
	command.Dir = directory
	command.Env = append([]string(nil), request.Environment...)
	command.Stdin = bytes.NewReader(request.Input)
	command.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	stdout := &boundedBuffer{remaining: runner.maxBytes}
	stderr := &boundedBuffer{remaining: runner.maxBytes}
	command.Stdout = stdout
	command.Stderr = stderr
	if err := command.Start(); err != nil {
		return Result{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "start external adapter", Resource: executable,
			Message: err.Error(), Err: err,
		}
	}
	supervisor, err := plugin.SuperviseStartedCommand(command)
	if err != nil {
		_ = command.Process.Kill()
		_ = command.Wait()
		return Result{}, &domain.Error{
			Code: domain.ErrorCodeInternal, Op: "supervise external adapter", Resource: executable,
			Message: err.Error(), Err: err,
		}
	}
	done := make(chan error, 1)
	go func() { done <- supervisor.Wait() }()
	var waitErr error
	select {
	case waitErr = <-done:
	case <-ctx.Done():
		killErr := supervisor.Terminate()
		waitErr = <-done
		if killErr != nil {
			return Result{}, errors.Join(ctx.Err(), killErr, waitErr)
		}
		return Result{
			Stdout: stdout.Bytes(), Stderr: stderr.Bytes(), ExitCode: exitCode(waitErr),
		}, ctx.Err()
	}
	result := Result{Stdout: stdout.Bytes(), Stderr: stderr.Bytes(), ExitCode: exitCode(waitErr)}
	if stdout.truncated || stderr.truncated {
		return result, &domain.Error{
			Code: domain.ErrorCodeBudgetExhausted, Op: "read external adapter", Resource: executable,
			Message: "command output exceeded its byte limit",
		}
	}
	if waitErr != nil {
		var exitError *exec.ExitError
		if !errors.As(waitErr, &exitError) {
			return result, &domain.Error{
				Code: domain.ErrorCodeInternal, Op: "wait for external adapter", Resource: executable,
				Message: waitErr.Error(), Err: waitErr,
			}
		}
	}
	return result, nil
}

type boundedBuffer struct {
	buffer    bytes.Buffer
	remaining uint64
	truncated bool
}

func (buffer *boundedBuffer) Write(value []byte) (int, error) {
	requested := len(value)
	if uint64(requested) > buffer.remaining {
		value = value[:buffer.remaining]
		buffer.truncated = true
	}
	_, _ = buffer.buffer.Write(value)
	buffer.remaining -= uint64(len(value))
	return requested, nil
}

func (buffer *boundedBuffer) Bytes() []byte {
	return append([]byte(nil), buffer.buffer.Bytes()...)
}

func exitCode(err error) int {
	if err == nil {
		return 0
	}
	var exitError *exec.ExitError
	if errors.As(err, &exitError) {
		if status, ok := exitError.Sys().(syscall.WaitStatus); ok && status.Signaled() {
			return 128 + int(status.Signal())
		}
		return exitError.ExitCode()
	}
	return -1
}

func invalidRequest(message string, err error) error {
	return &domain.Error{
		Code: domain.ErrorCodeInvalidArgument, Op: "configure external adapter",
		Resource: "command", Message: message, Err: err,
	}
}
