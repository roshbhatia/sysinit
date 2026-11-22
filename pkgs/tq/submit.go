package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

type submission struct {
	taskID   string
	session  string
	thread   string
	cwd      string
	group    string
	terminal bool
	retry    bool
	argv     []string
}

func parseSubmission(args []string) (submission, error) {
	var plan submission
	f := flag.NewFlagSet("submit", flag.ContinueOnError)
	f.Usage = func() {
		if _, err := fmt.Fprintln(f.Output(), "Usage: tq submit [OPTIONS] -- COMMAND [ARGS...]"); err == nil {
			f.PrintDefaults()
		}
	}
	f.StringVar(&plan.taskID, "task", "", "Full Taskwarrior UUID")
	f.StringVar(&plan.session, "session", "", "Existing seshy session")
	f.StringVar(&plan.thread, "thread", "", "Exact Atuin captured-thread ID")
	f.StringVar(&plan.cwd, "cwd", "", "Working directory")
	f.StringVar(&plan.group, "group", "agents", "Pueue group")
	f.BoolVar(&plan.terminal, "terminal", false, "Attachable WezTerm mux terminal")
	f.BoolVar(&plan.retry, "retry", false, "New attempt after completion")
	if err := f.Parse(args); err != nil {
		return plan, err
	}
	plan.argv = f.Args()
	if len(plan.argv) == 0 {
		return plan, errors.New("pass an explicit command after --")
	}
	if plan.session != "" && plan.cwd != "" {
		return plan, errors.New("choose --session or --cwd")
	}
	return plan, nil
}

func submit(plan submission, dir string, records []attempt) (int, error) {
	var e error
	if plan.thread != "" {
		var captured []struct {
			ID string `json:"atuin_id"`
		}
		if e = jsonCall(&captured, "atuin", "threads", "list", "--style", "json"); e != nil {
			return 1, e
		}
		found := false
		for _, entry := range captured {
			found = found || entry.ID == plan.thread
		}
		if !found {
			return 1, errors.New("use an exact captured-thread ID from threads list --style json")
		}
	}
	taskID := strings.ToLower(plan.taskID)
	cwd := plan.cwd
	var t task
	if taskID != "" {
		t, e = validateTask(taskID)
		if e != nil {
			return 1, e
		}
		if t.Repo == "" && cwd == "" && plan.session == "" {
			return 1, errors.New("task has no repo; specify --cwd or --session")
		}
	}
	env := map[string]string{}
	if plan.session != "" {
		var session struct {
			Version string            `json:"version"`
			Cwd     string            `json:"cwd"`
			Command []string          `json:"command"`
			Env     map[string]string `json:"environment"`
		}
		if e = jsonCall(&session, "sy", "open", plan.session, "--format", "json"); e != nil {
			return 1, e
		}
		if session.Version != "seshy.open/v1" || len(session.Command) != 0 {
			return 1, errors.New("unsupported seshy launch plan")
		}
		cwd = session.Cwd
		env = session.Env
	}
	if env == nil {
		env = map[string]string{}
	}
	for _, key := range []string{"PATH", "TASKRC", "TASKDATA", "PUEUE_CONFIG_PATH"} {
		if _, exists := env[key]; !exists {
			if value, present := os.LookupEnv(key); present {
				env[key] = value
			}
		}
	}
	if cwd == "" {
		cwd = t.Repo
	}
	if cwd == "" {
		cwd, e = os.Getwd()
		if e != nil {
			return 1, e
		}
	}
	cwd, e = filepath.Abs(cwd)
	if e != nil {
		return 1, e
	}
	cwd, e = filepath.EvalSymlinks(cwd)
	if e != nil {
		return 1, e
	}
	info, e := os.Stat(cwd)
	if e != nil {
		return 1, e
	}
	if !info.IsDir() {
		return 1, errors.New("working directory is not a directory")
	}
	var lastSequence uint64
	for _, a := range records {
		lastSequence = max(lastSequence, a.Sequence)
		if taskID != "" && a.Task == taskID {
			finished := state(a.Result) == "Done" || (a.Cancelled && state(a.Result) == "Missing")
			if !finished || !plan.retry {
				return 1, errors.New("attempt already exists; inspect status, then --retry after completion")
			}
		}
	}
	var groups map[string]json.RawMessage
	if e = jsonCall(&groups, "pueue", "group", "--json"); e != nil {
		return 1, e
	}
	if _, ok := groups[plan.group]; !ok {
		if _, e = call("pueue", "group", "add", plan.group); e != nil {
			return 1, e
		}
	}
	a := attempt{
		ID:       uuid(),
		Task:     taskID,
		Argv:     plan.argv,
		Cwd:      cwd,
		Env:      env,
		Session:  plan.session,
		Thread:   plan.thread,
		Group:    plan.group,
		Sequence: lastSequence + 1,
		Result:   json.RawMessage(`"Preparing"`),
	}
	if plan.terminal {
		a.Terminal = "pq-" + a.ID[:12]
	}
	if e = save(filepath.Join(dir, a.ID+".json"), a); e != nil {
		return 1, e
	}
	if e = enqueue(&a, dir); e != nil {
		return 1, e
	}
	if _, e = call("pueue", "enqueue", strconv.Itoa(*a.PueueID)); e != nil {
		return 1, e
	}
	return 0, output(a)
}
