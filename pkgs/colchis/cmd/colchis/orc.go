package main

import (
	"context"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/url"
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
	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
)

const orcUsage = `orc: optional local agent orchestration

Usage:
  orc
  orc start [--scope <path>]
  orc stop [--scope <path>]
  orc status [--scope <path>] [--json]
  orc list [--json]
  orc prompt
  orc run <controller> [--model <model>] [-- <controller arguments>]
  orc resume <controller> [--model <model>] [-- <controller arguments>]
  orc inject [--harness <name>] [--pane <pane-id>] [<session-id>]
  orc eject <session-id>
  orc session <current|list|register|remove|focus|traces>
  orc attach <session-or-worker-id>
  orc view --run <workflow-run-id> [--control <action> --payload <json|@file>]
  orc events [--after <cursor>] [--limit <count>]

Native commands:
  orc workflow <create|run|list|schedule|inspect|export|restart-point|restart-points|forks>
  orc graph patch
  orc replay run
  orc worker <start|list|attach|detach|intervene|policy|cancel|history>
  orc <workspace|artifact|verification|effect|provenance|broker> <action>

Native commands accept --payload <json|@file>, --id, --idempotency-key, and --state-dir.

Session means one registered harness conversation, whether Orc launched or injected it.
Controller means the interactive Claude, Codex, or other top-level process.
Workflow means a durable execution graph. Worker means one broker-managed workflow node session.
The bare command, run, resume, and attach hold a broker lease for their lifetime.
Use start to keep a broker running until stop. Direct controller commands remain independent.
Run starts a new controller. Resume uses the controller's native conversation picker.
Both commands connect the controller to this workspace broker.
Planning and spec authoring belong in dedicated workflow runs.
`

type orcStatus struct {
	Active         bool   `json:"active"`
	Scope          string `json:"scope"`
	StateDirectory string `json:"stateDirectory"`
	Socket         string `json:"socket"`
	Service        string `json:"service,omitempty"`
	PID            int    `json:"pid,omitempty"`
	StartedAt      string `json:"startedAt,omitempty"`
}

func isOrcCommand(command string) bool {
	switch command {
	case "start", "stop", "status", "list", "prompt", "run", "resume", "inject", "eject", "session", "attach", "help", "ui", "-h", "--help":
		return true
	default:
		return false
	}
}

func runOrcCommand(args []string, stdout io.Writer, stderr io.Writer) int {
	switch args[0] {
	case "start":
		return runOrcStart(args[1:], stdout, stderr)
	case "stop":
		return runOrcStop(args[1:], stdout, stderr)
	case "status":
		return runOrcStatus(args[1:], stdout, stderr)
	case "list":
		return runOrcList(args[1:], stdout, stderr)
	case "prompt":
		return runOrcPrompt(args[1:], stdout, stderr)
	case "run":
		return runOrcAgent(args[1:], stderr)
	case "resume":
		return runOrcController(args[1:], stderr, true)
	case "inject":
		return runOrcInject(args[1:], stdout, stderr)
	case "eject":
		return runOrcSessionRemove(args[1:], stdout, stderr)
	case "session":
		return runOrcSession(args[1:], stdout, stderr)
	case "attach":
		return runOrcAttach(args[1:], stdout, stderr)
	case "ui":
		if len(args) != 1 {
			fmt.Fprintln(stderr, "ui accepts no arguments")
			return 2
		}
		return runOrcAutoUI(stdout, stderr)
	case "help", "-h", "--help":
		if len(args) != 1 {
			fmt.Fprintln(stderr, "help accepts no arguments")
			return 2
		}
		fmt.Fprint(stdout, orcUsage)
		return 0
	default:
		return 2
	}
}

func runOrcStart(args []string, stdout io.Writer, stderr io.Writer) int {
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
	record, err := orcStartCandidate(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	var started bool
	var service string
	err = withOrcLeaseLock(record.StateDirectory, func() error {
		var startErr error
		started, service, startErr = startPinnedOrc(record, startOrcInstance)
		return startErr
	})
	if err != nil {
		fmt.Fprintf(stderr, "start broker: %v\n", err)
		return 1
	}
	if !started {
		fmt.Fprintf(stdout, "orc is running for %s\n", record.Scope)
		return 0
	}
	fmt.Fprintf(stdout, "orc started for %s (%s)\n", record.Scope, service)
	return 0
}

func startPinnedOrc(
	record instance.Record,
	start func(instance.Record, bool) (bool, string, error),
) (bool, string, error) {
	wasPinned, err := orcPinned(record.StateDirectory)
	if err != nil {
		return false, "", err
	}
	if err := setOrcPinned(record.StateDirectory, true); err != nil {
		return false, "", err
	}
	started, service, err := start(record, false)
	if err != nil && !wasPinned {
		_ = setOrcPinned(record.StateDirectory, false)
	}
	return started, service, err
}

func runOrcStop(args []string, stdout io.Writer, stderr io.Writer) int {
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
	record, _, err := activeOrc(*scopeFlag)
	if err != nil {
		fmt.Fprintf(stderr, "resolve instance: %v\n", err)
		return 1
	}
	stopped := false
	err = withOrcLeaseLock(record.StateDirectory, func() error {
		if err := setOrcPinned(record.StateDirectory, false); err != nil {
			return err
		}
		current, readErr := instance.Read(filepath.Join(record.StateDirectory, "instance.json"))
		if errors.Is(readErr, os.ErrNotExist) {
			return nil
		}
		if readErr != nil {
			return readErr
		}
		present, presentErr := orcServicePresent(current)
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
		if err := stopOrcService(current); err != nil {
			return err
		}
		if !waitForOrc(current, false, 5*time.Second) {
			return fmt.Errorf("broker did not stop for %s", current.Scope)
		}
		if !waitForOrcService(current, false, 5*time.Second) {
			return fmt.Errorf("broker service did not stop for %s", current.Scope)
		}
		return instance.Remove(current)
	})
	if err != nil {
		fmt.Fprintf(stderr, "stop broker: %v\n", err)
		return 1
	}
	if !stopped {
		fmt.Fprintln(stdout, "orc is inactive")
		return 0
	}
	fmt.Fprintf(stdout, "orc stopped for %s\n", record.Scope)
	return 0
}

func runOrcStatus(args []string, stdout io.Writer, stderr io.Writer) int {
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
	record, active, err := activeOrc(*scopeFlag)
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

func runOrcList(args []string, stdout io.Writer, stderr io.Writer) int {
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
	statuses := make([]orcStatus, 0, len(records))
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

func runOrcPrompt(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 0 {
		fmt.Fprintln(stderr, "prompt accepts no arguments")
		return 2
	}
	if os.Getenv("ORC_SCOPE") == "" {
		return 0
	}
	fmt.Fprint(stdout, "|⚔|")
	return 0
}

func runOrcAgent(args []string, stderr io.Writer) int {
	return runOrcController(args, stderr, false)
}

func runOrcAttach(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "usage: orc attach <session-id>")
		return 2
	}
	lease, err := acquireOrcLease()
	if err != nil {
		fmt.Fprintf(stderr, "start broker lease: %v\n", err)
		return 1
	}
	defer func() {
		if err := lease.release(); err != nil {
			fmt.Fprintf(stderr, "release broker lease: %v\n", err)
		}
	}()
	if session, found, lookupErr := instance.SessionByID(lease.record, args[0]); lookupErr != nil {
		fmt.Fprintf(stderr, "read session: %v\n", lookupErr)
		return 1
	} else if found {
		return focusOrcSession(session, stdout, stderr)
	}
	return runOrcWorkerUI(lease.record, domain.SessionID(args[0]), stdout, stderr)
}

func runOrcController(args []string, stderr io.Writer, resume bool) int {
	action := "run"
	if resume {
		action = "resume"
	}
	name, model, passthrough, err := parseOrcController(args, action)
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
	lease, err := acquireOrcLease()
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
	if err := recordAgentUse(name); err != nil {
		fmt.Fprintf(stderr, "record agent use: %v\n", err)
		return 1
	}
	directory, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(stderr, "resolve controller directory: %v\n", err)
		return 1
	}
	identity, _, _ := plugin.ProcessIdentity(os.Getpid())
	identifier, err := localCommandID()
	if err != nil {
		fmt.Fprintf(stderr, "create controller session id: %v\n", err)
		return 1
	}
	session, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: "session-" + identifier, Harness: name, Directory: directory, Pane: os.Getenv("WEZTERM_PANE"),
		Mux: currentWezTermMuxID(), PID: os.Getpid(),
		ProcessIdentity: identity,
		Status:          "working", Reason: action, Registration: "spawned",
		Capabilities: []string{"observe", "focus", "trace"},
	})
	if err != nil {
		fmt.Fprintf(stderr, "register controller session: %v\n", err)
		return 1
	}
	environment := withEnvironment(os.Environ(), map[string]string{
		"ORC_AGENT": name, "ORC_SCOPE": record.Scope,
		"ORC_SOCKET": record.Socket, "ORC_STATE_DIR": record.StateDirectory, "ORC_SESSION_ID": session.ID,
	})
	// Exec keeps the lease PID attached to the agent without a supervising wrapper process.
	if err := syscall.Exec(executable, command, environment); err != nil {
		fmt.Fprintf(stderr, "start %s: %v\n", name, err)
		return 1
	}
	return 0
}

func parseOrcController(args []string, action string) (string, string, []string, error) {
	if len(args) == 0 {
		return "", "", nil, fmt.Errorf(
			"usage: orc %s <controller> [--model <model>] [-- <controller arguments>]", action,
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

func runOrcSession(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) == 0 {
		fmt.Fprintln(stderr, "usage: orc session <current|list|register|remove|focus|traces>")
		return 2
	}
	switch args[0] {
	case "current":
		return runOrcSessionCurrent(args[1:], stdout, stderr)
	case "list":
		return runOrcSessionList(args[1:], stdout, stderr)
	case "register":
		return runOrcSessionRegister(args[1:], stdout, stderr)
	case "remove":
		return runOrcSessionRemove(args[1:], stdout, stderr)
	case "focus":
		return runOrcSessionFocus(args[1:], stdout, stderr)
	case "traces":
		return runOrcSessionTraces(args[1:], stdout, stderr)
	default:
		fmt.Fprintf(stderr, "unknown session action %q\n", args[0])
		return 2
	}
}

func runOrcSessionCurrent(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("session current", flag.ContinueOnError)
	flags.SetOutput(stderr)
	jsonOutput := flags.Bool("json", false, "write JSON")
	quiet := flags.Bool("quiet", false, "write no output")
	if err := flags.Parse(args); err != nil || flags.NArg() != 0 {
		return 2
	}
	record, active, err := activeOrc("")
	if err == nil && active {
		var found bool
		var session instance.Session
		session, found, err = instance.CurrentSession(record)
		if err == nil && found {
			if *quiet {
				return 0
			}
			if *jsonOutput {
				if err := json.NewEncoder(stdout).Encode(session); err != nil {
					fmt.Fprintf(stderr, "write current session: %v\n", err)
					return 1
				}
			} else {
				fmt.Fprintln(stdout, session.ID)
			}
			return 0
		}
	}
	if !*quiet {
		if err == nil {
			err = errors.New("this process is not registered with Orc")
		}
		fmt.Fprintf(stderr, "current session: %v\n", err)
	}
	return 1
}

func runOrcSessionList(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("session list", flag.ContinueOnError)
	flags.SetOutput(stderr)
	jsonOutput := flags.Bool("json", false, "write JSON")
	if err := flags.Parse(args); err != nil || flags.NArg() != 0 {
		return 2
	}
	record, active, err := activeOrc("")
	if err != nil || !active {
		if err == nil {
			err = errors.New("orc is inactive for this directory")
		}
		fmt.Fprintf(stderr, "list sessions: %v\n", err)
		return 1
	}
	sessions, err := controlPlaneSessions(record)
	if err != nil {
		fmt.Fprintf(stderr, "list sessions: %v\n", err)
		return 1
	}
	if *jsonOutput {
		if err := json.NewEncoder(stdout).Encode(sessions); err != nil {
			fmt.Fprintf(stderr, "write sessions: %v\n", err)
			return 1
		}
		return 0
	}
	for _, session := range sessions {
		fmt.Fprintf(stdout, "%s\t%s\t%s\t%s\t%s\n", session.ID, session.Harness, session.Status,
			session.Registration, session.Pane)
	}
	return 0
}

func runOrcSessionRegister(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("session register", flag.ContinueOnError)
	flags.SetOutput(stderr)
	id := flags.String("id", os.Getenv("ORC_SESSION_ID"), "Orc session id")
	harness := flags.String("harness", firstValue(os.Getenv("ORC_AGENT"), os.Getenv("AGENT")), "harness name")
	native := flags.String("native-id", nativeSessionID(), "harness session id")
	trace := flags.String("trace-id", "", "Traces session id")
	pane := flags.String("pane", "", "WezTerm pane id")
	mux := flags.Int("mux", currentWezTermMuxID(), "WezTerm mux process id")
	pid := flags.Int("pid", os.Getppid(), "harness process id")
	status := flags.String("status", "working", "session status")
	reason := flags.String("reason", "", "session status detail")
	source := flags.String("source", "registered", "registration source")
	capabilities := flags.String("capabilities", "observe,focus,trace", "comma-separated capabilities")
	jsonOutput := flags.Bool("json", false, "write JSON")
	if err := flags.Parse(args); err != nil || flags.NArg() != 0 {
		return 2
	}
	directory, err := os.Getwd()
	if err != nil {
		fmt.Fprintf(stderr, "register session: %v\n", err)
		return 1
	}
	record, active, err := activeOrc("")
	if err != nil {
		fmt.Fprintf(stderr, "register session: %v\n", err)
		return 1
	}
	// Hooks treat an absent broker as success, so direct harness launches stay independent.
	if !active {
		return 0
	}
	identity, _, _ := plugin.ProcessIdentity(*pid)
	registered, err := instance.RegisterSession(record, instance.SessionRegistration{
		ID: *id, Harness: *harness, NativeSessionID: *native, TraceSessionID: *trace,
		Directory: directory, Pane: *pane, Mux: *mux, PID: *pid, ProcessIdentity: identity, Status: *status,
		Reason: *reason, Registration: *source, Capabilities: splitComma(*capabilities),
	})
	if err != nil {
		fmt.Fprintf(stderr, "register session: %v\n", err)
		return 1
	}
	if *jsonOutput {
		if err := json.NewEncoder(stdout).Encode(registered); err != nil {
			fmt.Fprintf(stderr, "write session: %v\n", err)
			return 1
		}
	} else {
		fmt.Fprintln(stdout, registered.ID)
	}
	return 0
}

func runOrcSessionRemove(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "usage: orc session remove <session-id>")
		return 2
	}
	record, active, err := activeOrc("")
	if err != nil || !active {
		if err == nil {
			err = errors.New("orc is inactive for this directory")
		}
		fmt.Fprintf(stderr, "remove session: %v\n", err)
		return 1
	}
	if err := instance.RemoveSession(record, args[0]); err != nil {
		fmt.Fprintf(stderr, "remove session: %v\n", err)
		return 1
	}
	fmt.Fprintf(stdout, "removed %s\n", args[0])
	return 0
}

func runOrcSessionFocus(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "usage: orc session focus <session-id>")
		return 2
	}
	record, _, err := activeOrc("")
	if err != nil {
		fmt.Fprintf(stderr, "focus session: %v\n", err)
		return 1
	}
	session, found, err := findControlSession(record, args[0])
	if err != nil || !found {
		if err == nil {
			err = fmt.Errorf("session %q was not found", args[0])
		}
		fmt.Fprintf(stderr, "focus session: %v\n", err)
		return 1
	}
	return focusOrcSession(session, stdout, stderr)
}

func runOrcSessionTraces(args []string, stdout io.Writer, stderr io.Writer) int {
	if len(args) != 1 {
		fmt.Fprintln(stderr, "usage: orc session traces <session-id>")
		return 2
	}
	record, _, err := activeOrc("")
	if err != nil {
		fmt.Fprintf(stderr, "open Traces: %v\n", err)
		return 1
	}
	session, found, err := findControlSession(record, args[0])
	if err != nil || !found {
		if err == nil {
			err = fmt.Errorf("session %q was not found", args[0])
		}
		fmt.Fprintf(stderr, "open Traces: %v\n", err)
		return 1
	}
	return traceOrcSession(session, stdout, stderr)
}

func runOrcInject(args []string, stdout io.Writer, stderr io.Writer) int {
	flags := flag.NewFlagSet("inject", flag.ContinueOnError)
	flags.SetOutput(stderr)
	if len(args) > 1 && !strings.HasPrefix(args[0], "-") {
		args = append(append([]string(nil), args[1:]...), args[0])
	}
	pane := flags.String("pane", os.Getenv("WEZTERM_PANE"), "WezTerm pane id")
	harness := flags.String("harness", "", "harness name")
	native := flags.String("native-id", "", "harness session id")
	mux := flags.Int("mux", currentWezTermMuxID(), "WezTerm mux process id")
	if err := flags.Parse(args); err != nil || flags.NArg() > 1 {
		return 2
	}
	record, active, err := activeOrc("")
	if err != nil || !active {
		if err == nil {
			err = errors.New("start Orc before injecting a session")
		}
		fmt.Fprintf(stderr, "inject session: %v\n", err)
		return 1
	}
	sessions, err := controlPlaneSessions(record)
	if err != nil {
		fmt.Fprintf(stderr, "inject session: %v\n", err)
		return 1
	}
	wanted := ""
	if flags.NArg() == 1 {
		wanted = flags.Arg(0)
	}
	if wanted == "" && *pane == "" {
		*pane = os.Getenv("WEZTERM_PANE")
	}
	for _, session := range sessions {
		if wanted != "" && session.ID != wanted {
			continue
		}
		if wanted == "" && (*pane == "" || session.Pane != *pane || *mux > 0 && session.Mux != *mux ||
			*harness != "" && session.Harness != *harness) {
			continue
		}
		if session.Status == "disconnected" || !orcSessionProcessLive(session) {
			continue
		}
		registered, registerErr := instance.RegisterSession(record, instance.SessionRegistration{
			ID: session.ID, Harness: session.Harness, NativeSessionID: session.NativeSessionID,
			TraceSessionID: session.TraceSessionID, Directory: session.Directory, Pane: session.Pane, Mux: session.Mux,
			PID: session.PID, ProcessIdentity: session.ProcessIdentity,
			Status: session.Status, Reason: session.Reason, Registration: "injected",
			Capabilities: session.Capabilities,
		})
		if registerErr != nil {
			fmt.Fprintf(stderr, "inject session: %v\n", registerErr)
			return 1
		}
		fmt.Fprintf(stdout, "injected %s\n", registered.ID)
		return 0
	}
	if *harness != "" && *pane != "" {
		live, available := liveWezTermPanes()
		paneProcess, found := live[*pane]
		if !available || !found {
			fmt.Fprintf(stderr, "inject session: pane %s is not live\n", *pane)
			return 1
		}
		if *mux <= 0 || *mux != currentWezTermMuxID() {
			fmt.Fprintln(stderr, "inject session: pane injection needs a verified mux id")
			return 1
		}
		directory := paneProcess.Directory
		if directory == "" || !instance.Contains(record.Scope, directory) {
			fmt.Fprintln(stderr, "inject session: pane is outside this Orc workspace")
			return 1
		}
		capabilities := []string{"observe", "focus"}
		if *native != "" {
			capabilities = append(capabilities, "trace")
		}
		identity, _, _ := plugin.ProcessIdentity(paneProcess.PID)
		registered, registerErr := instance.RegisterSession(record, instance.SessionRegistration{
			ID: wanted, Harness: *harness, NativeSessionID: *native, TraceSessionID: *native,
			Directory: directory, Pane: *pane, Mux: *mux, PID: paneProcess.PID, ProcessIdentity: identity,
			Status: "working", Reason: "injected",
			Registration: "injected", Capabilities: capabilities,
		})
		if registerErr != nil {
			fmt.Fprintf(stderr, "inject session: %v\n", registerErr)
			return 1
		}
		fmt.Fprintf(stdout, "injected %s\n", registered.ID)
		return 0
	}
	fmt.Fprintln(stderr, "inject session: no matching live harness pane")
	return 1
}

func currentWezTermMuxID() int {
	name := filepath.Base(os.Getenv("WEZTERM_UNIX_SOCKET"))
	const prefix = "gui-sock-"
	if strings.HasPrefix(name, prefix) {
		pid, err := strconv.Atoi(strings.TrimPrefix(name, prefix))
		if err == nil && pid > 0 {
			return pid
		}
	}
	output, err := exec.Command("wezterm", "cli", "--no-auto-start", "list-clients", "--format", "json").Output()
	if err != nil {
		return 0
	}
	var clients []struct {
		PID         int             `json:"pid"`
		FocusedPane json.RawMessage `json:"focused_pane_id"`
	}
	if json.Unmarshal(output, &clients) != nil {
		return 0
	}
	pane := os.Getenv("WEZTERM_PANE")
	for _, client := range clients {
		if client.PID > 0 && (len(clients) == 1 || strings.Trim(string(client.FocusedPane), "\"") == pane) {
			return client.PID
		}
	}
	return 0
}

func controlPlaneSessions(record instance.Record) ([]instance.Session, error) {
	registered, err := instance.Sessions(record)
	if err != nil {
		return nil, err
	}
	byPane := make(map[string]int, len(registered))
	for index, session := range registered {
		if session.Pane != "" {
			key := fmt.Sprintf("%s:%d:%s:%d", session.Harness, session.Mux, session.Pane, session.ProcessIdentity)
			if _, found := byPane[key]; !found {
				byPane[key] = index
			}
		}
	}
	observed, err := observedHarnessSessions(record)
	if err != nil {
		return nil, err
	}
	for _, session := range observed {
		key := fmt.Sprintf("%s:%d:%s:%d", session.Harness, session.Mux, session.Pane, session.ProcessIdentity)
		if index, found := byPane[key]; found {
			registered[index].Status = session.Status
			registered[index].Reason = session.Reason
			registered[index].PID = session.PID
			registered[index].ProcessIdentity = session.ProcessIdentity
			registered[index].UpdatedAt = session.UpdatedAt
			continue
		}
		registered = append(registered, session)
	}
	for index := range registered {
		if registered[index].Registration != "observed" && registered[index].Status != "disconnected" &&
			!orcSessionProcessLive(registered[index]) {
			registered[index].Status = "disconnected"
			registered[index].Reason = "process exited"
		}
	}
	sort.SliceStable(registered, func(first, second int) bool {
		return registered[first].UpdatedAt > registered[second].UpdatedAt
	})
	return registered, nil
}

func observedHarnessSessions(record instance.Record) ([]instance.Session, error) {
	live, available := liveWezTermPanes()
	if !available {
		return nil, nil
	}
	mux := currentWezTermMuxID()
	if mux <= 0 {
		return nil, nil
	}
	registry, registryErr := agents.Load()
	harnessByCommand := make(map[string]string)
	if registryErr == nil {
		harnessByCommand = make(map[string]string, len(registry.Agents))
		for _, agent := range registry.Agents {
			if agent.Command != "" {
				harnessByCommand[filepath.Base(agent.Command)] = agent.Name
			}
		}
	}
	entries, err := os.ReadDir(paths.AgentPanes())
	if errors.Is(err, os.ErrNotExist) {
		entries = nil
	}
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	var sessions []instance.Session
	seen := make(map[string]bool, len(entries))
	for _, entry := range entries {
		if entry.IsDir() || filepath.Ext(entry.Name()) != ".json" {
			continue
		}
		data, readErr := os.ReadFile(filepath.Join(paths.AgentPanes(), entry.Name()))
		if readErr != nil {
			continue
		}
		var pane struct {
			Pane     json.RawMessage `json:"pane"`
			Mux      int             `json:"mux"`
			Agent    string          `json:"agent"`
			Status   string          `json:"status"`
			Reason   string          `json:"reason"`
			Worktree string          `json:"worktree"`
			Since    int64           `json:"since"`
		}
		if json.Unmarshal(data, &pane) != nil || pane.Agent == "" || pane.Worktree == "" {
			continue
		}
		paneID := strings.Trim(string(pane.Pane), "\"")
		paneProcess, found := live[paneID]
		if !found || pane.Mux != mux || !instance.Contains(record.Scope, pane.Worktree) {
			continue
		}
		if detected := harnessByCommand[filepath.Base(paneProcess.Command)]; detected != "" && detected != pane.Agent {
			continue
		}
		if paneProcess.PID <= 0 {
			continue
		}
		identity, found, identityErr := plugin.ProcessIdentity(paneProcess.PID)
		if identityErr != nil || !found {
			continue
		}
		updated := time.Unix(pane.Since, 0).UTC().Format(time.RFC3339Nano)
		digest := sha256.Sum256([]byte(fmt.Sprintf("%s\x00%d\x00%s\x00%d", pane.Agent, pane.Mux, paneID, identity)))
		sessions = append(sessions, instance.Session{
			Version: instance.SessionVersion, ID: pane.Agent + "-" + fmt.Sprintf("%x", digest[:6]),
			Role: "controller", Harness: pane.Agent, Scope: record.Scope, Directory: pane.Worktree,
			Pane: paneID, Mux: pane.Mux, PID: paneProcess.PID, ProcessIdentity: identity,
			Status: pane.Status, Reason: pane.Reason, Registration: "observed",
			Capabilities: []string{"observe", "focus"}, StartedAt: updated, UpdatedAt: updated,
		})
		seen[paneID] = true
	}
	if registryErr != nil {
		return sessions, nil
	}
	now := time.Now().UTC().Format(time.RFC3339Nano)
	for paneID, pane := range live {
		if seen[paneID] || pane.PID <= 0 || !instance.Contains(record.Scope, pane.Directory) {
			continue
		}
		harness := harnessByCommand[filepath.Base(pane.Command)]
		if harness == "" {
			continue
		}
		identity, found, identityErr := plugin.ProcessIdentity(pane.PID)
		if identityErr != nil || !found {
			continue
		}
		digest := sha256.Sum256([]byte(fmt.Sprintf("%s\x00%d\x00%s\x00%d", harness, mux, paneID, identity)))
		sessions = append(sessions, instance.Session{
			Version: instance.SessionVersion, ID: harness + "-" + fmt.Sprintf("%x", digest[:6]),
			Role: "controller", Harness: harness, Scope: record.Scope, Directory: pane.Directory,
			Pane: paneID, Mux: mux, PID: pane.PID, ProcessIdentity: identity,
			Status: "working", Reason: "discovered", Registration: "observed",
			Capabilities: []string{"observe", "focus"}, StartedAt: now, UpdatedAt: now,
		})
	}
	return sessions, nil
}

type liveWezTermPane struct {
	PID       int
	Command   string
	Directory string
}

func liveWezTermPanes() (map[string]liveWezTermPane, bool) {
	output, err := exec.Command("wezterm", "cli", "--no-auto-start", "list", "--format", "json").Output()
	if err != nil {
		return nil, false
	}
	var rows []struct {
		Pane json.RawMessage `json:"pane_id"`
		PID  int             `json:"pid"`
		TTY  string          `json:"tty_name"`
		Cwd  string          `json:"cwd"`
	}
	if json.Unmarshal(output, &rows) != nil {
		return nil, false
	}
	result := make(map[string]liveWezTermPane, len(rows))
	for _, row := range rows {
		foregroundPID, command := foregroundProcess(row.TTY)
		if row.PID <= 0 {
			row.PID = foregroundPID
		}
		result[strings.Trim(string(row.Pane), "\"")] = liveWezTermPane{
			PID: row.PID, Command: command, Directory: wezTermDirectory(row.Cwd),
		}
	}
	return result, true
}

func foregroundProcess(tty string) (int, string) {
	if tty = filepath.Base(tty); tty == "." || tty == "" {
		return 0, ""
	}
	ps := "/bin/ps"
	if _, err := os.Stat(ps); err != nil {
		ps, err = exec.LookPath("ps")
		if err != nil {
			return 0, ""
		}
	}
	output, err := exec.Command(ps, "-o", "pid=,tpgid=,comm=", "-t", tty).Output()
	if err != nil {
		return 0, ""
	}
	for _, line := range strings.Split(string(output), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 3 {
			continue
		}
		pid, pidErr := strconv.Atoi(fields[0])
		group, groupErr := strconv.Atoi(fields[1])
		if pidErr == nil && groupErr == nil && pid > 0 && pid == group {
			return pid, strings.Join(fields[2:], " ")
		}
	}
	return 0, ""
}

func wezTermDirectory(value string) string {
	parsed, err := url.Parse(value)
	if err != nil || parsed.Scheme != "file" {
		return ""
	}
	return parsed.Path
}

func findControlSession(record instance.Record, id string) (instance.Session, bool, error) {
	sessions, err := controlPlaneSessions(record)
	if err != nil {
		return instance.Session{}, false, err
	}
	for _, session := range sessions {
		if session.ID == id {
			return session, true, nil
		}
	}
	matches := make([]instance.Session, 0, 1)
	for _, session := range sessions {
		if strings.HasPrefix(session.ID, id) {
			matches = append(matches, session)
		}
	}
	if len(matches) == 1 {
		return matches[0], true, nil
	}
	if len(matches) > 1 {
		return instance.Session{}, false, fmt.Errorf("session prefix %q is ambiguous", id)
	}
	return instance.Session{}, false, nil
}

func focusOrcSession(session instance.Session, stdout io.Writer, stderr io.Writer) int {
	if session.Pane == "" {
		fmt.Fprintln(stderr, "focus session: this session has no terminal pane")
		return 1
	}
	if session.Mux <= 0 {
		fmt.Fprintln(stderr, "focus session: this session has no WezTerm mux")
		return 1
	}
	command := exec.Command("wezterm", "cli", "--no-auto-start", "activate-pane", "--pane-id", session.Pane)
	if currentWezTermMuxID() != session.Mux {
		socket, found := wezTermSocketForMux(session.Mux)
		if !found {
			fmt.Fprintln(stderr, "focus session: the session WezTerm mux is unavailable")
			return 1
		}
		command.Env = withEnvironment(os.Environ(), map[string]string{"WEZTERM_UNIX_SOCKET": socket})
	}
	if output, err := command.CombinedOutput(); err != nil {
		fmt.Fprintf(stderr, "focus session: %s: %v\n", strings.TrimSpace(string(output)), err)
		return 1
	}
	fmt.Fprintf(stdout, "focused %s\n", session.ID)
	return 0
}

func wezTermSocketForMux(mux int) (string, bool) {
	current := os.Getenv("WEZTERM_UNIX_SOCKET")
	if filepath.Base(current) == fmt.Sprintf("gui-sock-%d", mux) {
		if info, err := os.Stat(current); err == nil && info.Mode()&os.ModeSocket != 0 {
			return current, true
		}
	}
	directories := []string{os.Getenv("XDG_DATA_HOME")}
	if home, err := os.UserHomeDir(); err == nil {
		directories = append(directories, filepath.Join(home, ".local", "share"))
	}
	for _, directory := range directories {
		if directory == "" {
			continue
		}
		candidate := filepath.Join(directory, "wezterm", fmt.Sprintf("gui-sock-%d", mux))
		if info, err := os.Stat(candidate); err == nil && info.Mode()&os.ModeSocket != 0 {
			return candidate, true
		}
	}
	return "", false
}

func traceOrcSession(session instance.Session, stdout io.Writer, stderr io.Writer) int {
	id := firstValue(session.TraceSessionID, session.NativeSessionID)
	if id == "" {
		fmt.Fprintln(stderr, "open Traces: this session has no telemetry session id")
		return 1
	}
	command := exec.Command("traces", "--session", id)
	command.Stdin = os.Stdin
	command.Stdout = stdout
	command.Stderr = stderr
	if err := command.Run(); err != nil {
		fmt.Fprintf(stderr, "open Traces: %v\n", err)
		return 1
	}
	return 0
}

func nativeSessionID() string {
	for _, key := range []string{"CLAUDE_CODE_SESSION_ID", "CODEX_SESSION_ID", "CODEX_THREAD_ID"} {
		if value := os.Getenv(key); value != "" {
			return value
		}
	}
	return ""
}

func firstValue(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}

func splitComma(value string) []string {
	var values []string
	for _, part := range strings.Split(value, ",") {
		if part = strings.TrimSpace(part); part != "" {
			values = append(values, part)
		}
	}
	return values
}

func orcScope(configured string) (string, error) {
	if configured != "" {
		return instance.Physical(configured)
	}
	directory, err := os.Getwd()
	if err != nil {
		return "", err
	}
	return instance.DefaultScope(directory)
}

func orcStartCandidate(configured string) (instance.Record, error) {
	if configured != "" {
		scope, err := orcScope(configured)
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

func activeOrc(configured string) (instance.Record, bool, error) {
	if configured != "" {
		scope, err := orcScope(configured)
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

func resolveOrcPaths(override string) (config.Paths, error) {
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

func startOrcService(record instance.Record, automatic bool) (string, error) {
	executable, err := orcExecutable()
	if err != nil {
		return "", err
	}
	logPath := filepath.Join(record.StateDirectory, "broker.log")
	errorPath := filepath.Join(record.StateDirectory, "broker.error.log")
	switch runtime.GOOS {
	case "darwin":
		label := "org.sysinit.orc." + record.Key
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
		unit := "orc-" + record.Key + ".service"
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

func orcServicePresent(record instance.Record) (bool, error) {
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

func stopOrcService(record instance.Record) error {
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

func waitForOrc(record instance.Record, wantLive bool, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if instance.Live(record) == wantLive {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	return instance.Live(record) == wantLive
}

func orcErrorLog(record instance.Record) string {
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

func statusOf(record instance.Record, active bool) orcStatus {
	status := orcStatus{
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

func startOrcInstance(record instance.Record, automatic bool) (bool, string, error) {
	current, readErr := instance.Read(filepath.Join(record.StateDirectory, "instance.json"))
	if readErr == nil && current.Stopping {
		if !waitForOrc(current, false, 5*time.Second) {
			return false, "", fmt.Errorf("stopping broker did not exit for %s", current.Scope)
		}
		if !waitForOrcService(current, false, 5*time.Second) {
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
		executable, err := orcExecutable()
		if err != nil {
			return false, "", err
		}
		if current.Executable != executable {
			current.Stopping = true
			if err := instance.Write(current); err != nil {
				return false, "", err
			}
			if err := stopOrcService(current); err != nil {
				return false, "", err
			}
			if !waitForOrc(current, false, 5*time.Second) {
				return false, "", fmt.Errorf("outdated broker did not stop for %s", current.Scope)
			}
			if !waitForOrcService(current, false, 5*time.Second) {
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
		present, err := orcServicePresent(current)
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
	service, err := startOrcService(record, automatic)
	if err != nil {
		return false, "", err
	}
	if !waitForOrc(record, true, 5*time.Second) {
		message := fmt.Sprintf("broker did not start for %s", record.Scope)
		if detail := orcErrorLog(record); detail != "" {
			message += ": " + detail
		}
		failed := record
		failed.Service = service
		stopErr := stopOrcService(failed)
		if stopErr != nil {
			message += "; cleanup failed: " + stopErr.Error()
		} else if !waitForOrcService(failed, false, 5*time.Second) {
			message += "; cleanup left the service registered"
		}
		return false, "", errors.New(message)
	}
	return true, service, nil
}

func orcExecutable() (string, error) {
	executable := os.Getenv("ORC_EXECUTABLE")
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

func waitForOrcService(record instance.Record, wantPresent bool, timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		present, err := orcServicePresent(record)
		if err == nil && present == wantPresent {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	present, err := orcServicePresent(record)
	return err == nil && present == wantPresent
}

type orcLease struct {
	record instance.Record
	path   string
}

type orcLeaseRecord struct {
	PID      int    `json:"pid"`
	Identity uint64 `json:"identity"`
}

func runOrcAutoUI(stdout io.Writer, stderr io.Writer) int {
	lease, err := acquireOrcLease()
	if err != nil {
		fmt.Fprintf(stderr, "start broker lease: %v\n", err)
		return 1
	}
	defer func() {
		if err := lease.release(); err != nil {
			fmt.Fprintf(stderr, "release broker lease: %v\n", err)
		}
	}()
	return runOrcUI(stdout, stderr)
}

func acquireOrcLease() (orcLease, error) {
	candidate, err := orcStartCandidate("")
	if err != nil {
		return orcLease{}, err
	}
	var lease orcLease
	err = withOrcLeaseLock(candidate.StateDirectory, func() error {
		if _, err := cleanOrcLeases(candidate.StateDirectory); err != nil {
			return err
		}
		if instance.Live(candidate) {
			current, err := instance.Read(filepath.Join(candidate.StateDirectory, "instance.json"))
			if err != nil {
				return err
			}
			if !current.Automatic {
				lease.record, err = refreshPinnedOrc(candidate, startOrcInstance)
				return err
			}
		}
		directory := orcLeaseDirectory(candidate.StateDirectory)
		if err := os.MkdirAll(directory, 0o700); err != nil {
			return err
		}
		lease.path, err = createOrcLease(directory)
		if err != nil {
			return err
		}
		if _, _, err := startOrcInstance(candidate, true); err != nil {
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

func refreshPinnedOrc(
	candidate instance.Record,
	start func(instance.Record, bool) (bool, string, error),
) (instance.Record, error) {
	if _, _, err := start(candidate, false); err != nil {
		return instance.Record{}, err
	}
	return instance.Read(filepath.Join(candidate.StateDirectory, "instance.json"))
}

func (lease orcLease) release() error {
	if lease.path == "" {
		return nil
	}
	return withOrcLeaseLock(lease.record.StateDirectory, func() error {
		if err := os.Remove(lease.path); err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		remaining, err := cleanOrcLeases(lease.record.StateDirectory)
		if err != nil || remaining != 0 {
			return err
		}
		if activeOrcSessionProcess(lease.record) {
			return nil
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
		if err := stopOrcService(current); err != nil {
			return err
		}
		if !waitForOrc(current, false, 5*time.Second) {
			return fmt.Errorf("broker did not stop for %s", current.Scope)
		}
		if !waitForOrcService(current, false, 5*time.Second) {
			return fmt.Errorf("broker service did not stop for %s", current.Scope)
		}
		return nil
	})
}

func orcLeaseDirectory(stateDirectory string) string {
	return filepath.Join(stateDirectory, "leases")
}

func orcPinPath(stateDirectory string) string {
	return filepath.Join(stateDirectory, "pinned")
}

func orcPinned(stateDirectory string) (bool, error) {
	_, err := os.Stat(orcPinPath(stateDirectory))
	if err == nil {
		return true, nil
	}
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	return false, err
}

func automaticOrcBroker(stateDirectory string, requested bool) (bool, error) {
	if !requested {
		return false, nil
	}
	pinned, err := orcPinned(stateDirectory)
	return !pinned, err
}

func setOrcPinned(stateDirectory string, pinned bool) error {
	path := orcPinPath(stateDirectory)
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

func withOrcLeaseLock(stateDirectory string, action func() error) error {
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

func cleanOrcLeases(stateDirectory string) (int, error) {
	entries, err := os.ReadDir(orcLeaseDirectory(stateDirectory))
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
		path := filepath.Join(orcLeaseDirectory(stateDirectory), entry.Name())
		data, readErr := os.ReadFile(path)
		var lease orcLeaseRecord
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

func createOrcLease(directory string) (string, error) {
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
		err = json.NewEncoder(file).Encode(orcLeaseRecord{PID: os.Getpid(), Identity: identity})
	}
	err = errors.Join(err, file.Close())
	if err != nil {
		_ = os.Remove(path)
		return "", err
	}
	return path, nil
}

func monitorAutomaticBroker(ctx context.Context, stateDirectory string, stop context.CancelFunc) {
	monitorAutomaticBrokerWithRetire(ctx, stateDirectory, stopOrcService, stop)
}

func monitorAutomaticBrokerWithRetire(
	ctx context.Context,
	stateDirectory string,
	retire func(instance.Record) error,
	stop context.CancelFunc,
) {
	monitorAutomaticBrokerWithInterval(ctx, stateDirectory, retire, stop, 2*time.Second)
}

func monitorAutomaticBrokerWithInterval(
	ctx context.Context,
	stateDirectory string,
	retire func(instance.Record) error,
	stop context.CancelFunc,
	interval time.Duration,
) {
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			stopBroker := false
			var stoppedRecord instance.Record
			err := withOrcLeaseLock(stateDirectory, func() error {
				record, readErr := instance.Read(filepath.Join(stateDirectory, "instance.json"))
				if readErr == nil && !record.Automatic {
					return errBrokerPinned
				}
				if readErr != nil && !errors.Is(readErr, os.ErrNotExist) {
					return readErr
				}
				remaining, countErr := cleanOrcLeases(stateDirectory)
				if countErr != nil || remaining != 0 || readErr != nil || activeOrcSessionProcess(record) {
					return countErr
				}
				record.Stopping = true
				if err := instance.Write(record); err != nil {
					return err
				}
				stopBroker = true
				stoppedRecord = record
				return nil
			})
			if errors.Is(err, errBrokerPinned) {
				return
			}
			if err == nil && stopBroker && retire(stoppedRecord) == nil {
				stop()
				return
			}
		}
	}
}

var errBrokerPinned = errors.New("broker is pinned")

func activeOrcSessionProcess(record instance.Record) bool {
	sessions, err := instance.Sessions(record)
	if err != nil {
		return false
	}
	for _, session := range sessions {
		if session.Status == "disconnected" {
			continue
		}
		if orcSessionProcessLive(session) {
			return true
		}
	}
	return false
}

func orcSessionProcessLive(session instance.Session) bool {
	if session.PID <= 0 || session.ProcessIdentity == 0 {
		return false
	}
	identity, found, err := plugin.ProcessIdentity(session.PID)
	return err == nil && found && identity == session.ProcessIdentity
}

func orcRecentDirectory() string {
	return filepath.Join(filepath.Dir(instance.BaseDirectory()), "recent")
}

func recordAgentUse(name string) error {
	if name == "" || filepath.Base(name) != name {
		return errors.New("agent name is not safe for history")
	}
	directory := orcRecentDirectory()
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
		if info, err := os.Stat(filepath.Join(orcRecentDirectory(), agent.Name)); err == nil {
			recent[agent.Name] = info.ModTime()
		}
	}
	sort.SliceStable(available, func(first int, second int) bool {
		return recent[available[first].Name].After(recent[available[second].Name])
	})
}
