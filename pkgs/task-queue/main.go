package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
)

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
	home, e := os.UserHomeDir()
	if e != nil {
		return 1, e
	}
	base := os.Getenv("XDG_STATE_HOME")
	if base == "" {
		base = filepath.Join(home, ".local/state")
	}
	global := flag.NewFlagSet("task-queue", flag.ContinueOnError)
	dir := global.String("state", filepath.Join(base, "task-queue"), "Execution record directory")
	if e = global.Parse(args); e != nil {
		return 1, e
	}
	args = global.Args()
	if len(args) == 0 {
		_, e := fmt.Fprintln(os.Stdout, "Usage: task-queue [--state DIR] submit|status|reconcile|cancel|resume\nsubmit [--task UUID] [--session NAME | --cwd DIR] [--group NAME] [--terminal] [--retry] -- COMMAND [ARGS...]")
		return 0, e
	}
	*dir, e = filepath.Abs(*dir)
	if e != nil {
		return 1, e
	}
	if e = os.MkdirAll(*dir, 0700); e != nil {
		return 1, e
	}
	action := args[0]
	args = args[1:]
	if action == "run" || action == "terminal-child" {
		if len(args) != 1 {
			return 1, errors.New("one attempt UUID required")
		}
		path, e := recordPath(*dir, args[0])
		if e != nil {
			return 1, e
		}
		var a attempt
		if e = read(path, &a); e != nil {
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
	guard, e := lock(filepath.Join(*dir, "lock"), false)
	if e != nil {
		return 1, e
	}
	defer func() { _ = guard.Close() }()
	var snapshot struct {
		Tasks map[string]job `json:"tasks"`
	}
	if e = jsonCall(&snapshot, "pueue", "status", "--json"); e != nil {
		return 1, e
	}
	jobs := map[string]job{}
	for _, j := range snapshot.Tasks {
		existing, ok := jobs[j.Label]
		if !ok || existing.ID < j.ID {
			jobs[j.Label] = j
		}
	}
	records := []attempt{}
	paths, e := filepath.Glob(filepath.Join(*dir, "*.json"))
	if e != nil {
		return 1, e
	}
	for _, path := range paths {
		var a attempt
		if e = read(path, &a); e != nil {
			return 1, e
		}
		if j, ok := jobs["task-queue:"+a.ID]; ok {
			a.PueueID = &j.ID
			a.Result = j.Status
			a.Review = success(j.Status)
		} else if a.PueueID != nil && state(a.Result) != "Done" {
			a.Result = json.RawMessage(`"Missing"`)
			a.Review = false
		}
		if e = save(path, a); e != nil {
			return 1, e
		}
		records = append(records, a)
	}
	switch action {
	case "status", "reconcile":
		return 0, output(records)
	case "cancel", "resume":
		if len(args) != 1 {
			return 1, errors.New("one attempt UUID required")
		}
		path, e := recordPath(*dir, args[0])
		if e != nil {
			return 1, e
		}
		var a attempt
		if e = read(path, &a); e != nil {
			return 1, e
		}
		j, found := jobs["task-queue:"+a.ID]
		if action == "resume" {
			if a.Cancelled {
				return 1, errors.New("attempt cancelled; submit --retry")
			}
			if !found && a.PueueID == nil {
				if e = enqueue(&a, *dir); e != nil {
					return 1, e
				}
			} else if !found || state(j.Status) != "Stashed" {
				return 1, errors.New("only a stashed attempt can resume")
			}
			_, e = call("pueue", "enqueue", strconv.Itoa(*a.PueueID))
			return 0, e
		}
		if !found {
			return 1, errors.New("job is missing; refusing to infer process identity")
		}
		s := state(j.Status)
		if a.Terminal != "" && (s == "Running" || s == "Paused") {
			c := exec.Command("zmx", "kill", a.Terminal, "--force")
			c.Env = envWithout("ZMX_SESSION", "ZMX_SESSION_PREFIX")
			if e = c.Run(); e != nil {
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
				var current struct {
					Tasks map[string]job `json:"tasks"`
				}
				if queryErr := jsonCall(&current, "pueue", "status", "--json"); queryErr == nil {
					if finished, ok := current.Tasks[strconv.Itoa(j.ID)]; ok && state(finished.Status) == "Done" {
						e = nil
					}
				}
			}
		}
		if e != nil {
			return 1, e
		}
		a.Cancelled = true
		return 0, save(path, a)
	case "submit":
		return submit(args, *dir, records)
	default:
		return 1, fmt.Errorf("unknown action %q", action)
	}
}
