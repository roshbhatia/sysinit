package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"slices"
	"strings"
	"time"
)

type task struct {
	UUID           string   `json:"uuid"`
	Description    string   `json:"description"`
	Status         string   `json:"status"`
	Start          string   `json:"start,omitempty"`
	Project        string   `json:"project,omitempty"`
	Repo           string   `json:"repo,omitempty"`
	Kind           string   `json:"kind,omitempty"`
	LinearID       string   `json:"linearid,omitempty"`
	LinearAssigned string   `json:"linearassigned,omitempty"`
	LinearState    string   `json:"linearstatetype,omitempty"`
	Tags           []string `json:"tags,omitempty"`
	Urgency        float64  `json:"urgency"`
}

type attempt struct {
	ID      string          `json:"id"`
	Task    string          `json:"task"`
	PueueID *int            `json:"pueue_id,omitempty"`
	Result  json.RawMessage `json:"result,omitempty"`
	Review  bool            `json:"review"`
}

type workspace struct {
	ID    string `json:"id"`
	Task  string `json:"task"`
	Cwd   string `json:"cwd"`
	Agent string `json:"agent"`
}

type card struct {
	Task       task        `json:"task"`
	Attempt    *attempt    `json:"attempt,omitempty"`
	Workspaces []workspace `json:"workspaces,omitempty"`
}

type lane struct {
	Name  string `json:"name"`
	Cards []card `json:"cards"`
}

type board struct {
	Version string   `json:"version"`
	Scope   string   `json:"scope"`
	Lanes   []lane   `json:"lanes"`
	Errors  []string `json:"errors,omitempty"`
}

func projectBoard(tasks, blocked []task, attempts []attempt, workspaces []workspace, scope string) board {
	b := board{Version: "sysinit.task-board/v1", Scope: scope, Lanes: []lane{
		{Name: "Ready", Cards: []card{}},
		{Name: "In Progress", Cards: []card{}},
		{Name: "Blocked / Waiting", Cards: []card{}},
		{Name: "Review", Cards: []card{}},
		{Name: "Backlog", Cards: []card{}},
	}}
	blockedByDependency := map[string]bool{}
	for _, t := range blocked {
		blockedByDependency[t.UUID] = true
	}
	latest := map[string]*attempt{}
	for _, a := range attempts {
		if a.Task == "" {
			continue
		}
		previous := latest[a.Task]
		if previous == nil || a.PueueID != nil && (previous.PueueID == nil || *a.PueueID > *previous.PueueID) {
			latest[a.Task] = &a
		}
	}
	byTask := map[string][]workspace{}
	for _, w := range workspaces {
		byTask[w.Task] = append(byTask[w.Task], w)
	}
	for _, t := range tasks {
		if t.Kind == "idea" || t.Kind == "note" || t.LinearAssigned == "no" {
			continue
		}
		c := card{Task: t, Attempt: latest[t.UUID], Workspaces: byTask[t.UUID]}
		index := 0
		switch {
		case t.Status == "waiting" || blockedByDependency[t.UUID] || slices.Contains(t.Tags, "blocked"):
			index = 2
		case c.Attempt != nil && c.Attempt.Review:
			index = 3
		case t.Start != "":
			index = 1
		case slices.Contains(t.Tags, "backlog") || slices.Contains(t.Tags, "inbox") || t.LinearState == "backlog" || t.LinearState == "triage":
			index = 4
		}
		b.Lanes[index].Cards = append(b.Lanes[index].Cards, c)
	}
	for _, column := range b.Lanes {
		slices.SortStableFunc(column.Cards, func(a, b card) int {
			if a.Task.Urgency > b.Task.Urgency {
				return -1
			}
			if a.Task.Urgency < b.Task.Urgency {
				return 1
			}
			return strings.Compare(a.Task.UUID, b.Task.UUID)
		})
	}
	return b
}

type filters struct {
	Context, Repo, Project string
	All                    bool
	Terms                  []string
}

func runCommand(name string, args ...string) ([]byte, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	out, err := exec.CommandContext(ctx, name, args...).Output()
	if e, ok := err.(*exec.ExitError); ok && len(e.Stderr) > 0 {
		return nil, fmt.Errorf("%s: %s", name, strings.TrimSpace(string(e.Stderr)))
	}
	return out, err
}

func readJSON[T any](name string, args ...string) (T, error) {
	var result T
	out, err := runCommand(name, args...)
	if err == nil {
		err = json.Unmarshal(out, &result)
	}
	return result, err
}

func (f filters) taskArgs() []string {
	if f.Context == "" {
		return nil
	}
	return []string{"rc.context:" + f.Context}
}

func (f filters) collect() (board, error) {
	scope := "current context"
	var terms []string
	repo := f.Repo
	if repo == "" && f.Project == "" && !f.All && len(f.Terms) == 0 {
		if root, err := runCommand("git", "rev-parse", "--show-toplevel"); err == nil {
			repo = strings.TrimSpace(string(root))
		}
	}
	if repo != "" {
		terms = append(terms, "repo:"+repo)
		scope = repo
	}
	if f.Project != "" {
		terms = append(terms, "project:"+f.Project)
		scope = f.Project
	}
	terms = append(terms, f.Terms...)
	prefix := append(f.taskArgs(), "(", "+PENDING", "or", "+WAITING", ")")
	tasks, err := readJSON[[]task]("taskwarrior", append(append(slices.Clone(prefix), terms...), "export")...)
	if err != nil {
		return board{}, err
	}
	if len(tasks) == 0 && repo != "" && f.Repo == "" {
		scope = "current context"
		terms = f.Terms
		tasks, err = readJSON[[]task]("taskwarrior", append(append(slices.Clone(prefix), terms...), "export")...)
		if err != nil {
			return board{}, err
		}
	}
	blocked, err := readJSON[[]task]("taskwarrior", append(append(append(slices.Clone(prefix), terms...), "+BLOCKED"), "export")...)
	if err != nil {
		return board{}, err
	}
	attempts, queueErr := readJSON[[]attempt]("tq", "snapshot")
	workspaces, workspaceErr := readJSON[[]workspace]("agent-workspace", "list")
	result := projectBoard(tasks, blocked, attempts, workspaces, scope)
	if queueErr != nil {
		result.Errors = append(result.Errors, "Queue: "+queueErr.Error())
	}
	if workspaceErr != nil {
		result.Errors = append(result.Errors, "Workspaces: "+workspaceErr.Error())
	}
	return result, nil
}
