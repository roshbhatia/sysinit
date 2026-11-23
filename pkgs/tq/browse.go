package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/picker"
)

func browse(args []string, records []attempt, jobs map[string]job, dir string) error {
	f := flag.NewFlagSet("browse", flag.ContinueOnError)
	thread := f.String("thread", "", "Show attempts linked to this captured conversation")
	if err := f.Parse(args); err != nil {
		return err
	}
	if f.NArg() != 0 {
		return errors.New("browse accepts only --thread ID")
	}
	var attempts []attempt
	for _, a := range records {
		if *thread == "" || a.Thread == *thread {
			attempts = append(attempts, a)
		}
	}
	if len(attempts) == 0 {
		fmt.Fprintln(os.Stderr, "No queue attempts. Link a command with task-queue submit --thread ID -- COMMAND.")
		return nil
	}
	sort.SliceStable(attempts, func(i, j int) bool {
		left, right := attempts[i], attempts[j]
		if active(left) != active(right) {
			return active(left)
		}
		if left.Sequence != right.Sequence {
			return left.Sequence > right.Sequence
		}
		leftID, rightID := -1, -1
		if left.PueueID != nil {
			leftID = *left.PueueID
		}
		if right.PueueID != nil {
			rightID = *right.PueueID
		}
		if leftID != rightID {
			return leftID > rightID
		}
		return left.ID < right.ID
	})
	items := make([]picker.Item, len(attempts))
	for i, a := range attempts {
		id := "pending"
		if a.PueueID != nil {
			id = "#" + strconv.Itoa(*a.PueueID)
		}
		status := state(a.Result)
		if a.Review {
			status = "Succeeded"
		} else if status == "Done" {
			var result struct {
				Done struct {
					Result json.RawMessage `json:"result"`
				} `json:"Done"`
			}
			if err := json.Unmarshal(a.Result, &result); err == nil {
				status = state(result.Done.Result)
			}
		}
		link := ""
		if a.Thread != "" {
			link = " · thread " + a.Thread
		}
		items[i] = picker.Item{
			Title:  strings.Join(a.Argv, " "),
			Detail: fmt.Sprintf("%s %s · %s · %s%s", id, status, filepath.Base(a.Cwd), a.ID, link),
		}
	}
	index, err := picker.Pick(items, "queue> ", false)
	if err != nil || index < 0 {
		return err
	}
	a := attempts[index]
	j, live := jobs[a.ID]
	var labelsActions []string
	var commands [][]string
	if a.Terminal != "" {
		live, err := hasTerminal(a, dir)
		if err != nil {
			return err
		}
		if live {
			labelsActions = append(labelsActions, "Attach terminal")
			commands = append(commands, []string{"attach"})
		}
	}
	if live {
		labelsActions = append(labelsActions, "View logs · j/k scroll · q quit")
		commands = append(commands, []string{"log"})
		if state(j.Status) == "Running" {
			labelsActions = append(labelsActions, "Follow logs · Ctrl-C then j/k scroll · F follow")
			commands = append(commands, []string{"follow"})
		}
	}
	if a.Thread != "" {
		labelsActions = append(labelsActions, "Inspect captured conversation")
		commands = append(commands, []string{"atuin", "threads", "show", a.Thread})
	}
	if len(commands) == 0 {
		return errors.New("attempt has no available terminal, logs, or captured conversation")
	}
	selected, err := picker.Pick(picker.Items(labelsActions), "action> ", false)
	if err != nil || selected < 0 {
		return err
	}
	command := commands[selected]
	switch command[0] {
	case "attach":
		return attachTerminal(a, dir, false)
	case "log":
		return showJobLog(j, true)
	case "follow":
		return followJobLog(j)
	}
	return viewCommand(command[0], command[1:]...)
}

func showJobLog(j job, pager bool) error {
	id := strconv.Itoa(j.ID)
	var logs map[string]struct {
		Task   job    `json:"task"`
		Output string `json:"output"`
	}
	if err := jsonCall(&logs, "pueue", "log", "--json", "--lines", "1000", id); err != nil {
		return err
	}
	log, present := logs[id]
	if !present || !j.sameIdentity(log.Task) {
		return errors.New("job identity changed before reading Pueue logs")
	}
	if !pager {
		_, err := fmt.Fprint(os.Stdout, log.Output)
		return err
	}
	cmd := exec.Command("pueue-task-view", id, "stdin")
	cmd.Stdin = strings.NewReader(log.Output)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	return cmd.Run()
}

func followJobLog(j job) error {
	id := strconv.Itoa(j.ID)
	var current queueSnapshot
	if err := jsonCall(&current, "pueue", "status", "--json"); err != nil {
		return err
	}
	if live, ok := current.Tasks[id]; !ok || !j.sameIdentity(live) {
		return errors.New("job identity changed before following Pueue logs")
	}
	return viewCommand("pueue-task-view", id, "follow")
}

func active(a attempt) bool {
	switch state(a.Result) {
	case "Running", "Paused", "Queued", "Stashed", "Preparing":
		return true
	}
	return false
}

func viewCommand(name string, args ...string) error {
	command := exec.Command(name, args...)
	command.Stdin, command.Stdout, command.Stderr = os.Stdin, os.Stdout, os.Stderr
	return command.Run()
}
