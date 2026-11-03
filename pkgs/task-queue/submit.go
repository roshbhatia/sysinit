package main

import (
	"encoding/json"
	"errors"
	"flag"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

func submit(args []string, dir string, records []attempt) (int, error) {
	var e error
	f := flag.NewFlagSet("submit", flag.ContinueOnError)
	taskID := f.String("task", "", "Full Taskwarrior UUID")
	session := f.String("session", "", "Existing seshy session")
	cwd := f.String("cwd", "", "Working directory")
	group := f.String("group", "agents", "Pueue group")
	terminal := f.Bool("terminal", false, "Attachable zmx session")
	retry := f.Bool("retry", false, "New attempt after completion")
	if e = f.Parse(args); e != nil {
		return 1, e
	}
	argv := f.Args()
	if len(argv) == 0 {
		return 1, errors.New("pass an explicit command after --")
	}
	*taskID = strings.ToLower(*taskID)
	var t task
	if *taskID != "" {
		t, e = validateTask(*taskID)
		if e != nil {
			return 1, e
		}
		if t.Repo == "" && *cwd == "" && *session == "" {
			return 1, errors.New("task has no repo; specify --cwd or --session")
		}
	}
	env := map[string]string{}
	if *session != "" {
		if *cwd != "" {
			return 1, errors.New("choose --session or --cwd")
		}
		var plan struct {
			Version string            `json:"version"`
			Cwd     string            `json:"cwd"`
			Command []string          `json:"command"`
			Env     map[string]string `json:"environment"`
		}
		if e = jsonCall(&plan, "sy", "open", *session, "--format", "json"); e != nil {
			return 1, e
		}
		if plan.Version != "seshy.open/v1" || len(plan.Command) != 0 {
			return 1, errors.New("unsupported seshy launch plan")
		}
		*cwd = plan.Cwd
		env = plan.Env
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
	if *cwd == "" {
		*cwd = t.Repo
	}
	if *cwd == "" {
		*cwd, e = os.Getwd()
		if e != nil {
			return 1, e
		}
	}
	*cwd, e = filepath.Abs(*cwd)
	if e != nil {
		return 1, e
	}
	*cwd, e = filepath.EvalSymlinks(*cwd)
	if e != nil {
		return 1, e
	}
	info, e := os.Stat(*cwd)
	if e != nil {
		return 1, e
	}
	if !info.IsDir() {
		return 1, errors.New("working directory is not a directory")
	}
	for _, a := range records {
		if *taskID != "" && a.Task == *taskID {
			finished := state(a.Result) == "Done" || (a.Cancelled && state(a.Result) == "Missing")
			if !finished || !*retry {
				return 1, errors.New("attempt already exists; inspect status, then --retry after completion")
			}
		}
	}
	var groups map[string]json.RawMessage
	if e = jsonCall(&groups, "pueue", "group", "--json"); e != nil {
		return 1, e
	}
	if _, ok := groups[*group]; !ok {
		if _, e = call("pueue", "group", "add", *group); e != nil {
			return 1, e
		}
	}
	a := attempt{
		ID:      uuid(),
		Task:    *taskID,
		Argv:    argv,
		Cwd:     *cwd,
		Env:     env,
		Session: *session,
		Group:   *group,
		Result:  json.RawMessage(`"Preparing"`),
	}
	if *terminal {
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
