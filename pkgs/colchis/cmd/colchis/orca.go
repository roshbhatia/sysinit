package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strconv"
	"strings"
	"syscall"
	"time"

	"golang.org/x/sys/unix"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

const orcaUsage = `orca: optional local agent orchestration

Usage:
  orca
  orca start [--scope <path>]
  orca stop [--scope <path>]
  orca status [--scope <path>] [--json]
  orca list [--json]
  orca prompt
  orca run <controller> [--model <model>] [-- <controller arguments>]
  orca resume <controller> [--model <model>] [-- <controller arguments>]
  orca attach <worker-id>
  orca view --run <workflow-run-id> [--control <action> --payload <json|@file>]
  orca events [--after <cursor>] [--limit <count>]

Native commands:
  orca workflow <create|run|list|schedule|inspect|export|restart-point|restart-points|forks>
  orca graph patch
  orca replay run
  orca worker <start|list|attach|detach|intervene|policy|cancel|history>
  orca <workspace|artifact|verification|effect|provenance|broker> <action>

Native commands accept --payload <json|@file>, --id, --idempotency-key, and --state-dir.

Controller means the interactive Claude, Codex, or other top-level process.
Workflow means a durable execution graph. Worker means one broker-managed workflow node session.
The bare command, run, resume, and attach hold a broker lease for their lifetime.
Use start to keep a broker running until stop. Direct controller commands remain independent.
Run starts a new controller. Resume uses the controller's native conversation picker.
Both commands connect the controller to this workspace broker.
Planning and spec authoring belong in dedicated workflow runs.
`

type orcaStatus struct {
	Active         bool   `json:"active"`
	Scope          string `json:"scope"`
	StateDirectory string `json:"stateDirectory"`
	Socket         string `json:"socket"`
	Service        string `json:"service,omitempty"`
	PID            int    `json:"pid,omitempty"`
	StartedAt      string `json:"startedAt,omitempty"`
}

func isOrcaCommand(command string) bool {
	switch command {
	case "start", "stop", "status", "list", "prompt", "run", "resume", "attach", "help", "ui", "-h", "--help":
		return true
	default:
		return false
	}
}

func runOrcaCommand(args []string, stdout io.Writer, stderr io.Writer) int {
	switch args[0] {
	case "start":
		return runOrcaStart(args[1:], stdout, stderr)
	case "stop":
		return runOrcaStop(args[1:], stdout, stderr)
	case "status":
		return runOrcaStatus(args[1:], stdout, stderr)
	case "list":
		return runOrcaList(args[1:], stdout, stderr)
	case "prompt":
		return runOrcaPrompt(args[1:], stdout, stderr)
	case "run":
		return runOrcaAgent(args[1:], stderr)
	case "resume":
		return runOrcaController(args[1:], stderr, true)
	case "attach":
		return runOrcaAttach(args[1:], stdout, stderr)
	case "ui":
		if len(args) != 1 {
			fmt.Fprintln(stderr, "ui accepts no arguments")
			return 2
		}
		return runOrcaAutoUI(stdout, stderr)
	case "help", "-h", "--help":
		if len(args) != 1 {
			fmt.Fprintln(stderr, "help accepts no arguments")
			return 2
		}
		fmt.Fprint(stdout, orcaUsage)
		return 0
	default:
		return 2
	}
}

func runOrcaStart(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("start", flag.ContinueOnError)
	flags.SetOutput(stderr)
	scopeFlag := flags.String("scope", "", "workspace scope")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "start accepts no positional arguments")
		return 2
	}
	record, err := orcaStartCandidate(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	var started bool
	var service string
	err = withOrcaLeaseLock(record.StateDirectory, func() error {
		var startErr error
		started, service, startErr = startPinnedOrca(record, startOrcaInstance)
		return startErr
	})
	if err != nil {
		fmt.Fprintf(stderr, "start broker: %v\n", err)
		return 1
	}
	if !started {
		fmt.Fprintf(stdout, "orca is running for %s\n", record.Scope)
		return 0
	}
	fmt.Fprintf(stdout, "orca started for %s (%s)\n", record.Scope, service)
	return 0
}

func startPinnedOrca(
	record instance.Record,
	start func(instance.Record, bool) (bool, string, error),
) (bool, string, error) {
	wasPinned, err := orcaPinned(record.StateDirectory)
	if err != nil {
		return false, "", err
	}
	if err := setOrcaPinned(record.StateDirectory, true); err != nil {
		return false, "", err
	}
	started, service, err := start(record, false)
	if err != nil && !wasPinned {
		_ = setOrcaPinned(record.StateDirectory, false)
	}
	return started, service, err
}

func runOrcaStop(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("stop", flag.ContinueOnError)
	flags.SetOutput(stderr)
	scopeFlag := flags.String("scope", "", "workspace scope")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "stop accepts no arguments")
		return 2
	}
	record, _, err := activeOrca(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	stopped := false
	err = withOrcaLeaseLock(record.StateDirectory, func() error {
		if err := setOrcaPinned(record.StateDirectory, false); err != nil {
			return err
		}
		current, readErr := instance.Read(filepath.Join(record.StateDirectory, "instance.json"))
		if errors.Is(readErr, os.ErrNotExist) {
			return nil
		}
		if readErr != nil {
			return readErr
		}
		present, presentErr := orcaServicePresent(current)
		if presentErr != nil {
			return presentErr
		}
		if !instance.Live(current) && !present {
			return instance.Remove(current)
		}
		current.Stopping = true
		if err := instance.Write(current); err != nil {
			return err
		}
		stopped = true
		if err := stopOrcaService(current); err != nil {
			return err
		}
		if !waitForOrca(current, false, 5*time.Second) {
			return fmt.Errorf("broker did not stop for %s", current.Scope)
		}
		if !waitForOrcaService(current, false, 5*time.Second) {
			return fmt.Errorf("broker service did not stop for %s", current.Scope)
		}
		return instance.Remove(current)
	})
	if err != nil {
		fmt.Fprintf(stderr, "stop broker: %v\n", err)
		return 1
	}
	if !stopped {
		fmt.Fprintln(stdout, "orca is inactive")
		return 0
	}
	fmt.Fprintf(stdout, "orca stopped for %s\n", record.Scope)
	return 0
}

func runOrcaStatus(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("status", flag.ContinueOnError)
	flags.SetOutput(stderr)
	scopeFlag := flags.String("scope", "", "workspace scope")
	jsonOutput := flags.Bool("json", false, "write JSON")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "status accepts no positional arguments")
		return 2
	}
	record, active, err := activeOrca(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	status := statusOf(record, active)
	if *jsonOutput {
		if err := json.NewEncoder(stdout).Encode(status); err != nil {
			fmt.Fprintf(stderr, "write status: %v\n", err)
			return 1
		}
	} else if active {
		fmt.Fprintf(stdout, "running\t%s\n", record.Scope)
	} else {
		fmt.Fprintf(stdout, "inactive\t%s\n", record.Scope)
	}
	if !active {
		return 1
	}
	return 0
}

func runOrcaList(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("list", flag.ContinueOnError)
	flags.SetOutput(stderr)
	jsonOutput := flags.Bool("json", false, "write JSON")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "list accepts no positional arguments")
		return 2
	}
	records, err := instance.List()
	if err != nil {
		fmt.Fprintf(stderr, "list instances: %v\n", err)
		return 1
	}
	statuses := make([]orcaStatus, 0, len(records))
	for _, record := range records {
		if instance.Live(record) {
			statuses = append(statuses, statusOf(record, true))
		}
	}
	if *jsonOutput {
		if err := json.NewEncoder(stdout).Encode(statuses); err != nil {
			fmt.Fprintf(stderr, "write instances: %v\n", err)
			return 1
		}
		return 0
	}
	for _, status := range statuses {
		fmt.Fprintf(stdout, "%s\t%d\t%s\n", status.Scope, status.PID, status.Service)
	}
	return 0
}

func runOrcaPrompt(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 0 {
		fmt.Fprintln(stderr, "prompt accepts no arguments")
		return 2
	}
	record, active, err := activeOrca("")
	if err != nil || !active {
		return 0
	}
	fmt.Fprintf(stdout, "orca(%s)", filepath.Base(record.Scope))
	return 0
}

func runOrcaAgent(args []string, stderr io.Writer) int {
	return runOrcaController(args, stderr, false)
}

func runOrcaAttach(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "usage: orca attach <worker-id>")
		return 2
	}
	lease, err := acquireOrcaLease()
	if err != nil {
		fmt.Fprintf(stderr, "start broker lease: %v\n", err)
		return 1
	}
	defer func() {
		if err := lease.release(); err != nil {
			fmt.Fprintf(stderr, "release broker lease: %v\n", err)
		}
	}()
	return runOrcaWorkerUI(lease.record, domain.SessionID(args[0]), stdout, stderr)
}

func runOrcaController(args []string, stderr io.Writer, resume bool) int {
	action := "run"
	if resume {
		action = "resume"
	}
	name, model, passthrough, err := parseOrcaController(args, action)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 2
	}
	registry, err := agents.Load()
	if err != nil {
		fmt.Fprintf(stderr, "read agent registry: %v\n", err)
		return 1
	}
	agent, found := registry.Find(name)
	if !found || agent.Command == "" {
		fmt.Fprintf(stderr, "unknown controller %q\n", name)
		return 1
	}
	executable, err := exec.LookPath(agent.Command)
	if err != nil {
		fmt.Fprintf(stderr, "find %s: %v\n", agent.Command, err)
		return 1
	}
	lease, err := acquireOrcaLease()
	if err != nil {
		fmt.Fprintf(stderr, "start broker lease: %v\n", err)
		return 1
	}
	defer func() {
		if err := lease.release(); err != nil {
			fmt.Fprintf(stderr, "release broker lease: %v\n", err)
		}
	}()
	record := lease.record
	command := []string{executable}
	if model != "" {
		if agent.Launch.ModelFlag == "" {
			fmt.Fprintf(stderr, "%s does not declare model selection\n", name)
			return 1
		}
		command = append(command, agent.Launch.ModelFlag, model)
	}
	if resume {
		if len(agent.Launch.ResumeArgs) == 0 {
			fmt.Fprintf(stderr, "%s does not declare conversation resume support\n", name)
			return 1
		}
		command = append(command, agent.Launch.ResumeArgs...)
	}
	command = append(command, passthrough...)
	environment := withEnvironment(os.Environ(), map[string]string{
		"ORCA_AGENT": name, "ORCA_SCOPE": record.Scope,
		"ORCA_SOCKET": record.Socket, "ORCA_STATE_DIR": record.StateDirectory,
	})
	if err := recordAgentUse(name); err != nil {
		fmt.Fprintf(stderr, "record agent use: %v\n", err)
		return 1
	}
	// Exec keeps the lease PID attached to the agent without a supervising wrapper process.
	if err := syscall.Exec(executable, command, environment); err != nil {
		fmt.Fprintf(stderr, "start %s: %v\n", name, err)
		return 1
	}
	return 0
}

func parseOrcaController(args []string, action string) (string, string, []string, error) {
	if len(args) == 0 {
		return "", "", nil, fmt.Errorf(
			"usage: orca %s <controller> [--model <model>] [-- <controller arguments>]", action,
		)
	}
	name := args[0]
	model := ""
	passthrough := make([]string, 0)
	for index := 1; index < len(args); index++ {
		switch args[index] {
		case "--model":
			if index+1 >= len(args) {
				return "", "", nil, errors.New("--model requires a value")
			}
			model = args[index+1]
			index++
		case "--":
			passthrough = append(passthrough, args[index+1:]...)
			return name, model, passthrough, nil
		default:
			return "", "", nil, fmt.Errorf(
				"unknown %s option %q; pass controller arguments after --", action, args[index],
			)
		}
	}
	return name, model, passthrough, nil
}

func orcaScope(configured string) (string, error) {
	if configured != "" {
		return instance.Physical(configured)
	}
	directory, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return instance.DefaultScope(directory)
}

func orcaStartCandidate(configured string) (instance.Record, error) {
	if configured != "" {
		scope, err := orcaScope(configured)
		if err != nil {
			return instance.Record{}, err
		}
		record, _, err := instance.Candidate(scope)
		return record, err
	}
	directory, err := os.Getwd()
	if err != nil {
		return instance.Record{}, err
	}
	if record, found, err := instance.Match(directory); err != nil || found {
		return record, err
	}
	scope, err := instance.DefaultScope(directory)
	if err != nil {
		return instance.Record{}, err
	}
	record, _, err := instance.Candidate(scope)
	return record, err
}

func activeOrca(configured string) (instance.Record, bool, error) {
	if configured != "" {
		scope, err := orcaScope(configured)
		if err != nil {
			return instance.Record{}, false, err
		}
		record, _, err := instance.Candidate(scope)
		if err != nil {
			return instance.Record{}, false, err
		}
		current, readErr := instance.Read(filepath.Join(record.StateDirectory, "instance.json"))
		if readErr == nil {
			return current, instance.Live(current), nil
		}
		if !errors.Is(readErr, os.ErrNotExist) {
			return instance.Record{}, false, readErr
		}
		return record, false, nil
	}
	directory, err := os.Getwd()
	if err != nil {
		return instance.Record{}, false, err
	}
	if record, found, err := instance.Match(directory); err != nil || found {
		return record, found && instance.Live(record), err
	}
	scope, err := instance.DefaultScope(directory)
	if err != nil {
		return instance.Record{}, false, err
	}
	record, _, err := instance.Candidate(scope)
	return record, false, err
}

func resolveOrcaPaths(override string) (config.Paths, error) {
	if override != "" {
		return config.ResolvePaths(override)
	}
	directory, err := os.Getwd()
	if err != nil {
		return config.Paths{}, err
	}
	if record, active, err := instance.Active(directory); err != nil {
		return config.Paths{}, err
	} else if active {
		return config.ResolvePaths(record.StateDirectory)
	}
	scope, err := instance.DefaultScope(directory)
	if err != nil {
		return config.Paths{}, err
	}
	_, resolved, err := instance.Candidate(scope)
	return resolved, err
}

func startOrcaService(record instance.Record, automatic bool) (string, error) {
	executable, err := orcaExecutable()
	if err != nil {
		return "", err
	}
	logPath := filepath.Join(record.StateDirectory, "broker.log")
	errorPath := filepath.Join(record.StateDirectory, "broker.error.log")
	switch runtime.GOOS {
	case "darwin":
		label := "org.sysinit.orca." + record.Key
		target := fmt.Sprintf("gui/%d/%s", os.Getuid(), label)
		if exec.Command("/bin/launchctl", "print", target).Run() == nil {
			if err := exec.Command("/bin/launchctl", "remove", label).Run(); err != nil {
				return "", err
			}
		}
		args := []string{
			"submit", "-l", label, "-o", logPath, "-e", errorPath, "--",
			executable, "serve", "--workspace", record.Scope,
			"--state-dir", record.StateDirectory, "--service", "launchd:" + label,
		}
		if automatic {
			args = append(args, "--automatic")
		}
		if output, err := exec.Command("/bin/launchctl", args...).CombinedOutput(); err != nil {
			return "", fmt.Errorf("launchctl submit: %s: %w", strings.TrimSpace(string(output)), err)
		}
		return "launchd:" + label, nil
	case "linux":
		unit := "orca-" + record.Key + ".service"
		_ = exec.Command("systemctl", "--user", "reset-failed", unit).Run()
		args := []string{
			"--user", "--unit", unit, "--property", "Restart=on-failure",
			"--property", "RestartSec=2s", "--working-directory", record.Scope,
			executable, "serve", "--workspace", record.Scope,
			"--state-dir", record.StateDirectory, "--service", "systemd:" + unit,
		}
		if automatic {
			args = append(args, "--automatic")
		}
		if output, err := exec.Command("systemd-run", args...).CombinedOutput(); err != nil {
			return "", fmt.Errorf("systemd-run: %s: %w", strings.TrimSpace(string(output)), err)
		}
		return "systemd:" + unit, nil
	default:
		return "", fmt.Errorf("background services are unsupported on %s", runtime.GOOS)
	}
}

func orcaServicePresent(record instance.Record) (bool, error) {
	switch {
	case strings.HasPrefix(record.Service, "launchd:"):
		label := strings.TrimPrefix(record.Service, "launchd:")
		target := fmt.Sprintf("gui/%d/%s", os.Getuid(), label)
		err := exec.Command("/bin/launchctl", "print", target).Run()
		if err == nil {
			return true, nil
		}
		var exit *exec.ExitError
		if errors.As(err, &exit) {
			return false, nil
		}
		return false, err
	case strings.HasPrefix(record.Service, "systemd:"):
		unit := strings.TrimPrefix(record.Service, "systemd:")
		output, err := exec.Command(
			"systemctl", "--user", "show", "--property", "LoadState", "--value", unit,
		).CombinedOutput()
		if err != nil {
			return false, fmt.Errorf("systemctl show: %s: %w", strings.TrimSpace(string(output)), err)
		}
		return strings.TrimSpace(string(output)) != "not-found", nil
	default:
		return false, nil
	}
}

func stopOrcaService(record instance.Record) error {
	var stopErr error
	switch {
	case strings.HasPrefix(record.Service, "launchd:"):
		label := strings.TrimPrefix(record.Service, "launchd:")
		if output, err := exec.Command("/bin/launchctl", "remove", label).CombinedOutput(); err != nil {
			stopErr = fmt.Errorf("launchctl remove: %s: %w", strings.TrimSpace(string(output)), err)
		}
	case strings.HasPrefix(record.Service, "systemd:"):
		unit := strings.TrimPrefix(record.Service, "systemd:")
		if output, err := exec.Command("systemctl", "--user", "stop", unit).CombinedOutput(); err != nil {
			stopErr = fmt.Errorf("systemctl stop: %s: %w", strings.TrimSpace(string(output)), err)
		}
	default:
		process, err := os.FindProcess(record.PID)
		if err != nil {
			return err
		}
		stopErr = process.Signal(syscall.SIGTERM)
	}
	return stopErr
}

func waitForOrca(record instance.Record, wantLive bool, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if instance.Live(record) == wantLive {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	return instance.Live(record) == wantLive
}

func orcaErrorLog(record instance.Record) string {
	data, err := os.ReadFile(filepath.Join(record.StateDirectory, "broker.error.log"))
	if err != nil {
		return ""
	}
	trimmed := strings.TrimSpace(string(data))
	if len(trimmed) > 1000 {
		trimmed = trimmed[len(trimmed)-1000:]
	}
	return trimmed
}

func statusOf(record instance.Record, active bool) orcaStatus {
	status := orcaStatus{
		Active: active, Scope: record.Scope, StateDirectory: record.StateDirectory,
		Socket: record.Socket,
	}
	if active {
		status.Service = record.Service
		status.PID = record.PID
		status.StartedAt = record.StartedAt
	}
	return status
}

func withEnvironment(current []string, values map[string]string) []string {
	kept := make([]string, 0, len(current)+len(values))
	for _, entry := range current {
		name, _, found := strings.Cut(entry, "=")
		if _, replaced := values[name]; found && replaced {
			continue
		}
		kept = append(kept, entry)
	}
	for name, value := range values {
		kept = append(kept, name+"="+value)
	}
	return kept
}

func startOrcaInstance(record instance.Record, automatic bool) (bool, string, error) {
	current, readErr := instance.Read(filepath.Join(record.StateDirectory, "instance.json"))
	if readErr == nil && current.Stopping {
		if !waitForOrca(current, false, 5*time.Second) {
			return false, "", fmt.Errorf("stopping broker did not exit for %s", current.Scope)
		}
		if !waitForOrcaService(current, false, 5*time.Second) {
			return false, "", fmt.Errorf("stopping broker service remains registered for %s", current.Scope)
		}
		if err := instance.Remove(current); err != nil {
			return false, "", err
		}
		current = instance.Record{}
		readErr = os.ErrNotExist
	}
	if instance.Live(record) {
		if readErr != nil {
			return false, "", readErr
		}
		executable, err := orcaExecutable()
		if err != nil {
			return false, "", err
		}
		if current.Executable != executable {
			current.Stopping = true
			if err := instance.Write(current); err != nil {
				return false, "", err
			}
			if err := stopOrcaService(current); err != nil {
				return false, "", err
			}
			if !waitForOrca(current, false, 5*time.Second) {
				return false, "", fmt.Errorf("outdated broker did not stop for %s", current.Scope)
			}
			if !waitForOrcaService(current, false, 5*time.Second) {
				return false, "", fmt.Errorf("outdated broker service remains registered for %s", current.Scope)
			}
			if err := instance.Remove(current); err != nil {
				return false, "", err
			}
			current = instance.Record{}
			readErr = os.ErrNotExist
		} else {
			if !automatic && current.Automatic {
				current.Automatic = false
				if err := instance.Write(current); err != nil {
					return false, "", err
				}
			}
			return false, current.Service, nil
		}
	}
	if readErr == nil {
		present, err := orcaServicePresent(current)
		if err != nil {
			return false, "", err
		}
		if present {
			return false, "", fmt.Errorf("broker service is registered but unresponsive for %s", current.Scope)
		}
	} else if !errors.Is(readErr, os.ErrNotExist) {
		return false, "", readErr
	}
	if err := os.MkdirAll(record.StateDirectory, 0o700); err != nil {
		return false, "", fmt.Errorf("create state directory: %w", err)
	}
	service, err := startOrcaService(record, automatic)
	if err != nil {
		return false, "", err
	}
	if !waitForOrca(record, true, 5*time.Second) {
		message := fmt.Sprintf("broker did not start for %s", record.Scope)
		if detail := orcaErrorLog(record); detail != "" {
			message += ": " + detail
		}
		failed := record
		failed.Service = service
		stopErr := stopOrcaService(failed)
		if stopErr != nil {
			message += "; cleanup failed: " + stopErr.Error()
		} else if !waitForOrcaService(failed, false, 5*time.Second) {
			message += "; cleanup left the service registered"
		}
		return false, "", errors.New(message)
	}
	return true, service, nil
}

func orcaExecutable() (string, error) {
	executable := os.Getenv("ORCA_EXECUTABLE")
	if executable == "" {
		var err error
		executable, err = os.Executable()
		if err != nil {
			return "", err
		}
	} else {
		var err error
		executable, err = filepath.Abs(executable)
		if err != nil {
			return "", err
		}
	}
	return filepath.EvalSymlinks(executable)
}

func waitForOrcaService(record instance.Record, wantPresent bool, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		present, err := orcaServicePresent(record)
		if err == nil && present == wantPresent {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	present, err := orcaServicePresent(record)
	return err == nil && present == wantPresent
}

type orcaLease struct {
	record instance.Record
	path   string
}

type orcaLeaseRecord struct {
	PID      int    `json:"pid"`
	Identity uint64 `json:"identity"`
}

func runOrcaAutoUI(stdout io.Writer, stderr io.Writer) int {
	lease, err := acquireOrcaLease()
	if err != nil {
		fmt.Fprintf(stderr, "start broker lease: %v\n", err)
		return 1
	}
	defer func() {
		if err := lease.release(); err != nil {
			fmt.Fprintf(stderr, "release broker lease: %v\n", err)
		}
	}()
	return runOrcaUI(stdout, stderr)
}

func acquireOrcaLease() (orcaLease, error) {
	candidate, err := orcaStartCandidate("")
	if err != nil {
		return orcaLease{}, err
	}
	var lease orcaLease
	err = withOrcaLeaseLock(candidate.StateDirectory, func() error {
		if _, err := cleanOrcaLeases(candidate.StateDirectory); err != nil {
			return err
		}
		if instance.Live(candidate) {
			current, err := instance.Read(filepath.Join(candidate.StateDirectory, "instance.json"))
			if err != nil {
				return err
			}
			if !current.Automatic {
				lease.record, err = refreshPinnedOrca(candidate, startOrcaInstance)
				return err
			}
		}
		directory := orcaLeaseDirectory(candidate.StateDirectory)
		if err := os.MkdirAll(directory, 0o700); err != nil {
			return err
		}
		lease.path, err = createOrcaLease(directory)
		if err != nil {
			return err
		}
		if _, _, err := startOrcaInstance(candidate, true); err != nil {
			_ = os.Remove(lease.path)
			return err
		}
		current, err := instance.Read(filepath.Join(candidate.StateDirectory, "instance.json"))
		if err != nil {
			_ = os.Remove(lease.path)
			return err
		}
		lease.record = current
		return nil
	})
	return lease, err
}

func refreshPinnedOrca(
	candidate instance.Record,
	start func(instance.Record, bool) (bool, string, error),
) (instance.Record, error) {
	if _, _, err := start(candidate, false); err != nil {
		return instance.Record{}, err
	}
	return instance.Read(filepath.Join(candidate.StateDirectory, "instance.json"))
}

func (lease orcaLease) release() error {
	if lease.path == "" {
		return nil
	}
	return withOrcaLeaseLock(lease.record.StateDirectory, func() error {
		if err := os.Remove(lease.path); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		remaining, err := cleanOrcaLeases(lease.record.StateDirectory)
		if err != nil || remaining != 0 {
			return err
		}
		current, err := instance.Read(filepath.Join(lease.record.StateDirectory, "instance.json"))
		if errors.Is(err, os.ErrNotExist) {
			return nil
		}
		if err != nil || !current.Automatic || !instance.Live(current) {
			return err
		}
		current.Stopping = true
		if err := instance.Write(current); err != nil {
			return err
		}
		if err := stopOrcaService(current); err != nil {
			return err
		}
		if !waitForOrca(current, false, 5*time.Second) {
			return fmt.Errorf("broker did not stop for %s", current.Scope)
		}
		if !waitForOrcaService(current, false, 5*time.Second) {
			return fmt.Errorf("broker service did not stop for %s", current.Scope)
		}
		return nil
	})
}

func orcaLeaseDirectory(stateDirectory string) string {
	return filepath.Join(stateDirectory, "leases")
}

func orcaPinPath(stateDirectory string) string {
	return filepath.Join(stateDirectory, "pinned")
}

func orcaPinned(stateDirectory string) (bool, error) {
	_, err := os.Stat(orcaPinPath(stateDirectory))
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}

func automaticOrcaBroker(stateDirectory string, requested bool) (bool, error) {
	if !requested {
		return false, nil
	}
	pinned, err := orcaPinned(stateDirectory)
	return !pinned, err
}

func setOrcaPinned(stateDirectory string, pinned bool) error {
	path := orcaPinPath(stateDirectory)
	if !pinned {
		if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		return nil
	}
	if err := os.MkdirAll(stateDirectory, 0o700); err != nil {
		return err
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	return file.Close()
}

func withOrcaLeaseLock(stateDirectory string, action func() error) error {
	if err := os.MkdirAll(stateDirectory, 0o700); err != nil {
		return err
	}
	lock, err := os.OpenFile(filepath.Join(stateDirectory, ".leases.lock"), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return err
	}
	defer lock.Close()
	if err := unix.Flock(int(lock.Fd()), unix.LOCK_EX); err != nil {
		return err
	}
	defer unix.Flock(int(lock.Fd()), unix.LOCK_UN)
	return action()
}

func cleanOrcaLeases(stateDirectory string) (int, error) {
	entries, err := os.ReadDir(orcaLeaseDirectory(stateDirectory))
	if errors.Is(err, os.ErrNotExist) {
		return 0, nil
	}
	if err != nil {
		return 0, err
	}
	remaining := 0
	for _, entry := range entries {
		if entry.IsDir() {
			remaining++
			continue
		}
		path := filepath.Join(orcaLeaseDirectory(stateDirectory), entry.Name())
		data, readErr := os.ReadFile(path)
		var lease orcaLeaseRecord
		decodeErr := json.Unmarshal(data, &lease)
		alive := false
		if readErr == nil && decodeErr == nil && lease.PID > 0 && lease.Identity > 0 {
			identity, found, identityErr := plugin.ProcessIdentity(lease.PID)
			if identityErr != nil {
				return 0, identityErr
			}
			alive = found && identity == lease.Identity
		}
		if !alive {
			if err := os.Remove(path); err != nil && !errors.Is(err, os.ErrNotExist) {
				return 0, err
			}
			continue
		}
		remaining++
	}
	return remaining, nil
}

func createOrcaLease(directory string) (string, error) {
	identity, found, err := plugin.ProcessIdentity(os.Getpid())
	if err != nil {
		return "", err
	}
	if !found {
		return "", syscall.ESRCH
	}
	file, err := os.CreateTemp(directory, strconv.Itoa(os.Getpid())+"-")
	if err != nil {
		return "", err
	}
	path := file.Name()
	if chmodErr := file.Chmod(0o600); chmodErr != nil {
		err = chmodErr
	} else {
		err = json.NewEncoder(file).Encode(orcaLeaseRecord{PID: os.Getpid(), Identity: identity})
	}
	err = errors.Join(err, file.Close())
	if err != nil {
		_ = os.Remove(path)
		return "", err
	}
	return path, nil
}

func monitorAutomaticBroker(ctx context.Context, stateDirectory string, stop context.CancelFunc) {
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			stopBroker := false
			err := withOrcaLeaseLock(stateDirectory, func() error {
				record, readErr := instance.Read(filepath.Join(stateDirectory, "instance.json"))
				if readErr == nil && !record.Automatic {
					return errBrokerPinned
				}
				if readErr != nil && !errors.Is(readErr, os.ErrNotExist) {
					return readErr
				}
				remaining, countErr := cleanOrcaLeases(stateDirectory)
				if countErr != nil || remaining != 0 || readErr != nil {
					return countErr
				}
				record.Stopping = true
				if err := instance.Write(record); err != nil {
					return err
				}
				stopBroker = true
				stop()
				return nil
			})
			if errors.Is(err, errBrokerPinned) {
				return
			}
			if err == nil && stopBroker {
				return
			}
		}
	}
}

var errBrokerPinned = errors.New("broker is pinned")

func orcaRecentDirectory() string {
	return filepath.Join(filepath.Dir(instance.BaseDirectory()), "recent")
}

func recordAgentUse(name string) error {
	if name == "" || filepath.Base(name) != name {
		return errors.New("agent name is not safe for history")
	}
	directory := orcaRecentDirectory()
	if err := os.MkdirAll(directory, 0o700); err != nil {
		return err
	}
	file, err := os.OpenFile(filepath.Join(directory, name), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o600)
	if err != nil {
		return err
	}
	_, writeErr := fmt.Fprintln(file, time.Now().UTC().Format(time.RFC3339Nano))
	return errors.Join(writeErr, file.Close())
}

func sortAgentsByRecency(available []agents.Agent) {
	recent := make(map[string]time.Time, len(available))
	for _, agent := range available {
		if info, err := os.Stat(filepath.Join(orcaRecentDirectory(), agent.Name)); err == nil {
			recent[agent.Name] = info.ModTime()
		}
	}
	sort.SliceStable(available, func(first int, second int) bool {
		return recent[available[first].Name].After(recent[available[second].Name])
	})
}
