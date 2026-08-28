package external

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

const externalRunnerFixture = "COLCHIS_EXTERNAL_RUNNER_FIXTURE"

func TestExternalRunnerFixtureProcess(t *testing.T) {
	switch os.Getenv(externalRunnerFixture) {
	case "orphan":
		executable, err := os.Executable()
		if err != nil {
			os.Exit(2)
		}
		child := exec.Command(executable, "-test.run=^TestExternalRunnerFixtureProcess$")
		child.Env = []string{externalRunnerFixture + "=child"}
		if err := child.Start(); err != nil {
			os.Exit(3)
		}
		os.Exit(0)
	case "parent":
		executable, err := os.Executable()
		if err != nil {
			os.Exit(2)
		}
		child := exec.Command(executable, "-test.run=^TestExternalRunnerFixtureProcess$")
		child.Env = []string{externalRunnerFixture + "=child"}
		if err := child.Start(); err != nil {
			os.Exit(3)
		}
		if err := os.WriteFile(os.Getenv("PID_PATH"), []byte(fmt.Sprintf("%d", child.Process.Pid)), 0o600); err != nil {
			os.Exit(4)
		}
		if err := child.Wait(); err != nil {
			os.Exit(5)
		}
		os.Exit(0)
	case "child":
		time.Sleep(time.Minute)
		os.Exit(0)
	}
}

func TestRunnerPreservesRootExitAfterOrphanCleanup(t *testing.T) {
	t.Parallel()

	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	result, err := NewRunner(1024).Run(ctx, Request{
		Executable: executable, Arguments: []string{"-test.run=^TestExternalRunnerFixtureProcess$"},
		Directory: t.TempDir(), Environment: []string{externalRunnerFixture + "=orphan"},
	})
	if err != nil || result.ExitCode != 0 {
		t.Fatalf("Run() result = %#v, error = %v", result, err)
	}
}

func TestRunnerReportsSignalAsShellExitCode(t *testing.T) {
	t.Parallel()

	result, err := NewRunner(1024).Run(context.Background(), Request{
		Executable: "/bin/sh", Arguments: []string{"-c", "kill -TERM $$"}, Directory: t.TempDir(),
	})
	if err != nil || result.ExitCode != 143 {
		t.Fatalf("Run() result = %#v, error = %v", result, err)
	}
}

func TestRunnerUsesExplicitProcessInputs(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := writeFixture(t, directory, "#!/bin/sh\nread input\nprintf '%s:%s' \"$FIXTURE\" \"$input\"\nexit 7\n")
	result, err := NewRunner(1024).Run(context.Background(), Request{
		Executable: executable, Directory: directory, Environment: []string{"FIXTURE=value"},
		Input: []byte("payload\n"),
	})
	if err != nil {
		t.Fatalf("Run() returned %v", err)
	}
	if result.ExitCode != 7 || string(result.Stdout) != "value:payload" || len(result.Stderr) != 0 {
		t.Fatalf("result = %#v", result)
	}
}

func TestRunnerRejectsExcessOutput(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	executable := writeFixture(t, directory, "#!/bin/sh\nprintf '%s' 'output-too-large'\n")
	result, err := NewRunner(4).Run(context.Background(), Request{
		Executable: executable, Directory: directory,
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeBudgetExhausted) || string(result.Stdout) != "outp" {
		t.Fatalf("Run() result = %#v, error = %v", result, err)
	}
}

func TestRunnerKillsCommandProcessGroupOnCancellation(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	pidPath := filepath.Join(directory, "child.pid")
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan error, 1)
	go func() {
		_, err := NewRunner(1024).Run(ctx, Request{
			Executable: executable, Arguments: []string{"-test.run=^TestExternalRunnerFixtureProcess$"},
			Directory:   directory,
			Environment: []string{externalRunnerFixture + "=parent", "PID_PATH=" + pidPath},
		})
		done <- err
	}()
	var childPID int
	deadline := time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		payload, err := os.ReadFile(pidPath)
		if err == nil {
			if _, scanErr := fmt.Sscanf(strings.TrimSpace(string(payload)), "%d", &childPID); scanErr == nil {
				break
			}
		}
		time.Sleep(10 * time.Millisecond)
	}
	if childPID == 0 {
		cancel()
		t.Fatal("child process identifier was not written")
	}
	cancel()
	if err := <-done; !errors.Is(err, context.Canceled) {
		t.Fatalf("Run() error = %v", err)
	}
	deadline = time.Now().Add(2 * time.Second)
	for time.Now().Before(deadline) {
		err := syscall.Kill(childPID, 0)
		if errors.Is(err, syscall.ESRCH) {
			return
		}
		time.Sleep(10 * time.Millisecond)
	}
	t.Fatalf("child process %d remains alive", childPID)
}

func writeFixture(t *testing.T, directory string, content string) string {
	t.Helper()
	path := filepath.Join(directory, "fixture-command")
	if err := os.WriteFile(path, []byte(content), 0o700); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	return path
}
