package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/instance"
	"github.com/roshbhatia/sysinit/pkgs/internal/agents"
)

const orcaUsage = `orca: optional local agent orchestration

Usage:
  orca
  orca start [--scope <path>]
  orca stop
  orca status [--json]
  orca list [--json]
  orca prompt
  orca run <agent> [--model <model>] [-- <agent arguments>]

The bare command opens the control UI. Only start creates a broker.
Direct agent commands remain independent of Orca.
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
	case "start", "stop", "status", "list", "prompt", "run", "help", "ui", "-h", "--help":
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
	case "ui":
		if len(args) != 1 {
			fmt.Fprintln(stderr, "ui accepts no arguments")
			return 2
		}
		return runOrcaUI(stdout, stderr)
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
	scope, err := orcaScope(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve scope: %v\n", err)
		return 1
	}
	record, _, err := instance.Candidate(scope)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	if instance.Live(record) {
		fmt.Fprintf(stdout, "orca is running for %s\n", record.Scope)
		return 0
	}
	if err := os.MkdirAll(record.StateDirectory, 0o700); err != nil {
		fmt.Fprintf(stderr, "create state directory: %v\n", err)
		return 1
	}
	service, err := startOrcaService(record)
	if err != nil {
		fmt.Fprintf(stderr, "start broker: %v\n", err)
		return 1
	}
	if !waitForOrca(record, true, 5*time.Second) {
		fmt.Fprintf(stderr, "broker did not start for %s", record.Scope)
		if detail := orcaErrorLog(record); detail != "" {
			fmt.Fprintf(stderr, ": %s", detail)
		}
		fmt.Fprintln(stderr)
		return 1
	}
	fmt.Fprintf(stdout, "orca started for %s (%s)\n", record.Scope, service)
	return 0
}

func runOrcaStop(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 0 {
		fmt.Fprintln(stderr, "stop accepts no arguments")
		return 2
	}
	record, active, err := activeOrca()
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	if !active {
		fmt.Fprintln(stdout, "orca is inactive")
		return 0
	}
	if err := stopOrcaService(record); err != nil {
		fmt.Fprintf(stderr, "stop broker: %v\n", err)
		return 1
	}
	if !waitForOrca(record, false, 5*time.Second) {
		fmt.Fprintf(stderr, "broker did not stop for %s\n", record.Scope)
		return 1
	}
	fmt.Fprintf(stdout, "orca stopped for %s\n", record.Scope)
	return 0
}

func runOrcaStatus(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("status", flag.ContinueOnError)
	flags.SetOutput(stderr)
	jsonOutput := flags.Bool("json", false, "write JSON")
	if err := flags.Parse(args); err != nil {
		return 2
	}
	if flags.NArg() != 0 {
		fmt.Fprintln(stderr, "status accepts no positional arguments")
		return 2
	}
	record, active, err := activeOrca()
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
	record, active, err := activeOrca()
	if err != nil || !active {
		return 0
	}
	fmt.Fprintf(stdout, "orca(%s)", filepath.Base(record.Scope))
	return 0
}

func runOrcaAgent(args []string, stderr io.Writer) int {
	name, model, passthrough, err := parseOrcaRun(args)
	if err != nil {
		fmt.Fprintln(stderr, err)
		return 2
	}
	record, active, err := activeOrca()
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	if !active {
		fmt.Fprintln(stderr, "orca is inactive; run `orca start` or invoke the agent directly")
		return 1
	}
	registry, err := agents.Load()
	if err != nil {
		fmt.Fprintf(stderr, "read agent registry: %v\n", err)
		return 1
	}
	agent, found := registry.Find(name)
	if !found || agent.Command == "" {
		fmt.Fprintf(stderr, "unknown agent %q\n", name)
		return 1
	}
	executable, err := exec.LookPath(agent.Command)
	if err != nil {
		fmt.Fprintf(stderr, "find %s: %v\n", agent.Command, err)
		return 1
	}
	command := []string{executable}
	if model != "" {
		if agent.Launch.ModelFlag == "" {
			fmt.Fprintf(stderr, "%s does not declare model selection\n", name)
			return 1
		}
		command = append(command, agent.Launch.ModelFlag, model)
	}
	command = append(command, passthrough...)
	environment := withEnvironment(os.Environ(), map[string]string{
		"ORCA_AGENT": name, "ORCA_SCOPE": record.Scope,
		"ORCA_SOCKET": record.Socket, "ORCA_STATE_DIR": record.StateDirectory,
	})
	if err := syscall.Exec(executable, command, environment); err != nil {
		fmt.Fprintf(stderr, "start %s: %v\n", name, err)
		return 1
	}
	return 0
}

func parseOrcaRun(args []string) (string, string, []string, error) {
	if len(args) == 0 {
		return "", "", nil, errors.New("usage: orca run <agent> [--model <model>] [-- <agent arguments>]")
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
			return "", "", nil, fmt.Errorf("unknown run option %q; pass agent arguments after --", args[index])
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

func activeOrca() (instance.Record, bool, error) {
	directory, err := os.Getwd()
	if err != nil {
		return instance.Record{}, false, err
	}
	if record, active, err := instance.Active(directory); err != nil || active {
		return record, active, err
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

func startOrcaService(record instance.Record) (string, error) {
	executable := os.Getenv("ORCA_EXECUTABLE")
	if executable == "" {
		var err error
		executable, err = os.Executable()
		if err != nil {
			return "", err
		}
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
		if output, err := exec.Command("systemd-run", args...).CombinedOutput(); err != nil {
			return "", fmt.Errorf("systemd-run: %s: %w", strings.TrimSpace(string(output)), err)
		}
		return "systemd:" + unit, nil
	default:
		return "", fmt.Errorf("background services are unsupported on %s", runtime.GOOS)
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
	return orcaStatus{
		Active: active, Scope: record.Scope, StateDirectory: record.StateDirectory,
		Socket: record.Socket, Service: record.Service, PID: record.PID, StartedAt: record.StartedAt,
	}
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
