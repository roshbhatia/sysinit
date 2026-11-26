package main

import (
	"bytes"
	"cmp"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
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
	Annotations    []struct {
		Entry       string `json:"entry"`
		Description string `json:"description"`
	} `json:"annotations,omitempty"`
}

type attempt struct {
	ID        string          `json:"id"`
	Task      string          `json:"task"`
	Cwd       string          `json:"cwd,omitempty"`
	Sequence  uint64          `json:"sequence,omitempty"`
	CreatedAt time.Time       `json:"created_at,omitzero"`
	PueueID   *int            `json:"pueue_id,omitempty"`
	Result    json.RawMessage `json:"result,omitempty"`
	Review    bool            `json:"review"`
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

func (c card) reviewDirectory() (string, error) {
	dir := c.Task.Repo
	switch {
	case c.Attempt != nil && c.Attempt.Cwd != "":
		dir = c.Attempt.Cwd
	case len(c.Workspaces) == 1:
		dir = c.Workspaces[0].Cwd
	case len(c.Workspaces) > 1:
		return "", fmt.Errorf("more than one linked workspace; open the intended workspace to review it")
	}
	if !filepath.IsAbs(dir) {
		return "", fmt.Errorf("this task needs an absolute checkout or directory to open review")
	}
	return dir, nil
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
	type selection struct {
		current *attempt
		count   int
		undated bool
		tied    bool
	}
	latest := map[string]selection{}
	for _, a := range attempts {
		if a.Task == "" {
			continue
		}
		selected := latest[a.Task]
		selected.count++
		selected.undated = selected.undated || (a.Sequence == 0 && a.CreatedAt.IsZero())
		order := 1
		if previous := selected.current; previous != nil {
			order = cmp.Compare(a.Sequence, previous.Sequence)
			if a.Sequence == 0 && previous.Sequence == 0 {
				order = a.CreatedAt.Compare(previous.CreatedAt)
			}
		}
		if order > 0 {
			selected.current = &a
			selected.tied = false
		} else if order == 0 {
			selected.tied = true
		}
		latest[a.Task] = selected
	}
	byTask := map[string][]workspace{}
	for _, w := range workspaces {
		byTask[w.Task] = append(byTask[w.Task], w)
	}
	for _, t := range tasks {
		if t.Kind == "idea" || t.Kind == "note" || t.LinearAssigned == "no" {
			continue
		}
		selected := latest[t.UUID]
		c := card{Task: t, Attempt: selected.current, Workspaces: byTask[t.UUID]}
		if selected.tied || (selected.count > 1 && selected.undated && selected.current.Sequence == 0) {
			c.Attempt = nil
			b.Errors = append(b.Errors, "Queue: unable to determine latest attempt for task "+t.UUID)
		}
		index := 0
		switch {
		case t.Status == "waiting" || blockedByDependency[t.UUID] || slices.Contains(t.Tags, "blocked"):
			index = 2
		case slices.Contains(t.Tags, "review"):
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
	All, Workspaces        bool
	Terms                  []string
}

func runCommand(name string, args ...string) ([]byte, string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer cancel()
	var stderr bytes.Buffer
	cmd := exec.CommandContext(ctx, name, args...)
	cmd.Stderr = &stderr
	out, err := cmd.Output()
	diagnostics := strings.TrimSpace(stderr.String())
	if err != nil && diagnostics != "" {
		return nil, "", fmt.Errorf("%s: %s: %w", name, diagnostics, err)
	}
	return out, diagnostics, err
}

func readJSON[T any](name string, args ...string) (T, error) {
	var result T
	out, _, err := runCommand(name, args...)
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
		if root, _, err := runCommand("git", "rev-parse", "--show-toplevel"); err == nil {
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
	var attempts []attempt
	var queueErr error
	if path, err := exec.LookPath("task-queue"); err == nil {
		attempts, queueErr = readJSON[[]attempt](path, "status")
	}
	var workspaces []workspace
	var diagnostics string
	var workspaceErr error
	if f.Workspaces {
		var workspaceJSON []byte
		workspaceJSON, diagnostics, workspaceErr = runCommand("agent-workspace", "list")
		if workspaceErr == nil {
			workspaceErr = json.Unmarshal(workspaceJSON, &workspaces)
		}
	}
	result := projectBoard(tasks, blocked, attempts, workspaces, scope)
	if queueErr != nil {
		result.Errors = append(result.Errors, "Queue: "+queueErr.Error())
	}
	if workspaceErr != nil {
		result.Errors = append(result.Errors, "Workspaces: "+workspaceErr.Error())
	} else if diagnostics != "" {
		result.Errors = append(result.Errors, "Workspaces: "+diagnostics)
	}
	return result, nil
}
