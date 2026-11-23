package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
)

const usage = `Usage: task-queue [--state DIR] COMMAND [ARGS...]

  submit [OPTIONS] -- COMMAND [ARGS...]  Queue a command. See task-queue submit --help.
  status, snapshot                    Read attempts and live status as JSON.
  browse [--thread ID]                 Browse attempts, terminals, and logs.
  attach UUID [--focus-only]           Open or focus an attempt in its terminal provider.
  thread UUID                          Show an attempt's captured conversation.
  logs UUID [--pager | --follow]       Read verified log output for an attempt.
  reconcile                            Save live status to the attempt records.
  cancel UUID                          Cancel a queued or running attempt.
  resume UUID                          Resume an attempt that has not started.

Use Taskwarrior UUIDs with submit --task and attempt UUIDs with thread, cancel, and resume.`

func main() {
	code, e := run(os.Args[1:])
	if e != nil {
		fmt.Fprintln(os.Stderr, "task-queue:", e)
		if code == 0 {
			code = 1
		}
	}
	os.Exit(code)
}

func run(args []string) (int, error) {
	if len(args) == 1 && args[0] == "wezterm-provider" {
		return 0, serveWezTerm()
	}
	home, e := os.UserHomeDir()
	if e != nil {
		return 1, e
	}
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		base = filepath.Join(home, ".local/state")
	}
	global := flag.NewFlagSet("task-queue", flag.ContinueOnError)
	dir := global.String("state", defaultStateDir(base), "Execution record directory")
	var usageErr error
	global.Usage = func() { _, usageErr = fmt.Fprintln(os.Stdout, usage) }
	if e = global.Parse(args); e != nil {
		if errors.Is(e, flag.ErrHelp) {
			return 0, usageErr
		}
		return 1, e
	}
	args = global.Args()
	if len(args) == 0 || (len(args) == 1 && args[0] == "help") {
		global.Usage()
		return 0, usageErr
	}
	action := args[0]
	args = args[1:]
	*dir, e = filepath.Abs(*dir)
	if e != nil {
		return 1, e
	}
	var attemptPath string
	var request submission
	switch action {
	case "submit":
		request, e = parseSubmission(args)
		if errors.Is(e, flag.ErrHelp) {
			return 0, nil
		}
		if e != nil {
			return 1, e
		}
	case "status", "snapshot", "reconcile":
		if len(args) != 0 {
			return 1, fmt.Errorf("%s accepts no arguments", action)
		}
	case "logs", "attach":
		if len(args) < 1 || len(args) > 2 {
			return 1, fmt.Errorf("%s requires one attempt UUID and at most one option", action)
		}
		option := "--pager | --follow"
		valid := len(args) == 1 || args[1] == "--pager" || args[1] == "--follow"
		if action == "attach" {
			option = "--focus-only"
			valid = len(args) == 1 || args[1] == option
		}
		if !valid {
			return 1, fmt.Errorf("usage: task-queue %s UUID [%s]", action, option)
		}
		if attemptPath, e = recordPath(*dir, args[0]); e != nil {
			return 1, e
		}
	case "thread", "cancel", "resume", "run", "terminal-child":
		if len(args) != 1 {
			return 1, errors.New("one attempt UUID required")
		}
		if attemptPath, e = recordPath(*dir, args[0]); e != nil {
			return 1, e
		}
	case "browse":
	default:
		return 1, fmt.Errorf("unknown action %q; see task-queue --help", action)
	}
	readOnly := action == "status" || action == "snapshot" || action == "browse" || action == "thread" || action == "logs" || action == "attach"
	if readOnly {
		if action == "status" || action == "snapshot" {
			if _, err := os.Stat(*dir); os.IsNotExist(err) {
				return 0, output([]attempt{})
			} else if err != nil {
				return 1, err
			}
		}
	} else if e = os.MkdirAll(*dir, 0700); e != nil {
		return 1, e
	}
	if action == "thread" || action == "attach" {
		var a attempt
		if e = read(attemptPath, &a); e != nil {
			return 1, e
		}
		if action == "attach" {
			return 0, attachTerminal(a, *dir, len(args) == 2)
		}
		if a.Thread == "" {
			return 1, errors.New("attempt has no linked conversation; submit with --thread ID")
		}
		return 0, viewCommand("atuin", "threads", "show", a.Thread)
	}
	if action == "run" || action == "terminal-child" {
		var a attempt
		if e = read(attemptPath, &a); e != nil {
			return 1, e
		}
		if action == "terminal-child" {
			return execute(a, *dir, true)
		}
		f, e := os.OpenFile(filepath.Join(*dir, a.ID+".started"), os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0600)
		if e != nil {
			return 1, fmt.Errorf("attempt already started; submit --retry: %w", e)
		}
		_ = f.Close()
		if a.Terminal != "" {
			return terminalRun(a, *dir)
		}
		return execute(a, *dir, false)
	}
	if !readOnly {
		guard, err := lock(filepath.Join(*dir, "lock"), false)
		if err != nil {
			return 1, err
		}
		defer func() { _ = guard.Close() }()
	}
	var snapshot queueSnapshot
	if e = jsonCall(&snapshot, "pueue", "status", "--json"); e != nil {
		return 1, e
	}
	jobs := map[string]job{}
	for _, j := range snapshot.Tasks {
		id, managed := attemptID(j.Label)
		if !managed {
			continue
		}
		existing, ok := jobs[id]
		if !ok || existing.ID < j.ID {
			jobs[id] = j
		}
	}
	records := []attempt{}
	var target *attempt
	paths, e := filepath.Glob(filepath.Join(*dir, "*.json"))
	if e != nil {
		return 1, e
	}
	for _, path := range paths {
		var a attempt
		if e = read(path, &a); e != nil {
			return 1, e
		}
		if j, ok := jobs[a.ID]; ok {
			if a.Sequence == 0 && a.CreatedAt.IsZero() {
				a.CreatedAt = j.CreatedAt
			}
			a.PueueID = &j.ID
			a.Result = j.Status
			a.Review = success(j.Status)
		} else if a.PueueID != nil && state(a.Result) != "Done" {
			a.Result = json.RawMessage(`"Missing"`)
			a.Review = false
		}
		if path == attemptPath {
			target = &a
		}
		records = append(records, a)
	}
	switch action {
	case "browse":
		return 0, browse(args, records, jobs, *dir)
	case "logs":
		if target == nil {
			return 1, fmt.Errorf("attempt %s: %w", args[0], os.ErrNotExist)
		}
		j, live := jobs[target.ID]
		if !live {
			return 1, errors.New("attempt has no current Pueue job")
		}
		if len(args) == 2 && args[1] == "--follow" && state(j.Status) == "Running" {
			return 0, followJobLog(j)
		}
		return 0, showJobLog(j, len(args) == 2)
	case "status", "snapshot":
		return 0, output(records)
	case "reconcile":
		for i, a := range records {
			if e = save(paths[i], a); e != nil {
				return 1, e
			}
		}
		return 0, output(records)
	case "cancel", "resume":
		if target == nil {
			return 1, fmt.Errorf("attempt %s: %w", args[0], os.ErrNotExist)
		}
		a := target
		j, found := jobs[a.ID]
		if action == "resume" {
			if a.Cancelled {
				return 1, errors.New("attempt cancelled; submit --retry")
			}
			if !found && a.PueueID == nil {
				if e = enqueue(a, *dir); e != nil {
					return 1, e
				}
			} else if !found || state(j.Status) != "Stashed" {
				return 1, errors.New("only a stashed attempt can resume")
			} else if e = save(attemptPath, a); e != nil {
				return 1, e
			}
			_, e = call("pueue", "enqueue", strconv.Itoa(*a.PueueID))
			return 0, e
		}
		if !found {
			return 1, errors.New("job is missing; refusing to infer process identity")
		}
		s := state(j.Status)
		if a.Terminal != "" && (s == "Running" || s == "Paused") {
			if e = killTerminal(*a, *dir); e != nil {
				return 1, e
			}
		}
		switch s {
		case "Queued", "Stashed", "Locked":
			_, e = call("pueue", "remove", strconv.Itoa(j.ID))
		case "Done":
		default:
			_, e = call("pueue", "kill", strconv.Itoa(j.ID))
			if e != nil && a.Terminal != "" {
				var current queueSnapshot
				if queryErr := jsonCall(&current, "pueue", "status", "--json"); queryErr == nil {
					if finished, ok := current.Tasks[strconv.Itoa(j.ID)]; ok && j.sameIdentity(finished) && state(finished.Status) == "Done" {
						e = nil
					}
				}
			}
		}
		if e != nil {
			return 1, e
		}
		a.Cancelled = true
		return 0, save(attemptPath, a)
	case "submit":
		return submit(request, *dir, records)
	default:
		return 1, fmt.Errorf("unknown action %q", action)
	}
}
