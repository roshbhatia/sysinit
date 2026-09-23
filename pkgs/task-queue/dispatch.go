package main

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

func taskRecord(id string) (task, error) {
	var rows []task
	if !validID(id) {
		return task{}, errors.New("use a full Taskwarrior UUID")
	}
	if e := jsonCall(&rows, "taskwarrior", "rc.context:none", id, "export"); e != nil {
		return task{}, e
	}
	if len(rows) != 1 || rows[0].UUID != id {
		return task{}, errors.New("task UUID did not resolve uniquely")
	}
	return rows[0], nil
}

func validateTask(id string) (task, error) {
	t, e := taskRecord(id)
	if e != nil {
		return t, e
	}
	if t.Status != "pending" {
		return t, errors.New("task must be pending and not waiting")
	}
	for _, tag := range t.Tags {
		if tag == "blocked" {
			return t, errors.New("task is marked blocked")
		}
	}
	for _, dep := range t.Depends {
		d, e := taskRecord(dep)
		if e != nil {
			return t, e
		}
		if d.Status != "completed" {
			return t, errors.New("task has an incomplete dependency")
		}
	}
	return t, nil
}

func shellQuote(s string) string { return "'" + strings.ReplaceAll(s, "'", "'\"'\"'") + "'" }

func enqueue(a *attempt, dir string) error {
	self, e := os.Executable()
	if e != nil {
		return e
	}
	command := shellQuote(self) + " --state " + shellQuote(dir) + " run " + shellQuote(a.ID)
	b, e := call("pueue", "add", "--stashed", "--print-task-id", "--group", a.Group, "--label", "task-queue:"+a.ID, "--working-directory", a.Cwd, "--", command)
	if e != nil {
		return e
	}
	id, e := strconv.Atoi(strings.TrimSpace(string(b)))
	if e != nil {
		return e
	}
	a.PueueID = &id
	a.Result = json.RawMessage(`"Stashed"`)
	return save(filepath.Join(dir, a.ID+".json"), a)
}
