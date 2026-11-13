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

func browse(args []string, records []attempt) error {
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
	labels := make([]string, len(attempts))
	for i, a := range attempts {
		id := "pending"
		if a.PueueID != nil {
			id = "#" + strconv.Itoa(*a.PueueID)
		}
		status := state(a.Result)
		if a.Review {
			status = "Success · review"
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
		labels[i] = fmt.Sprintf("%s %s · %s · %s · %s%s", id, status, filepath.Base(a.Cwd), strings.Join(a.Argv, " "), a.ID, link)
	}
	index, err := picker.Pick(labels, "queue> ", false)
	if err != nil || index < 0 {
		return err
	}
	a := attempts[index]
	var labelsActions []string
	var commands [][]string
	if a.Terminal != "" {
		out, err := call("zmx", "list", "--short")
		if err != nil {
			return err
		}
		for _, name := range strings.Split(string(out), "\n") {
			if name == a.Terminal {
				labelsActions = append(labelsActions, "Attach terminal")
				commands = append(commands, []string{"env", "-u", "ZMX_SESSION", "-u", "ZMX_SESSION_PREFIX", "zmx", "attach", a.Terminal})
				break
			}
		}
	}
	if a.PueueID != nil && state(a.Result) != "Missing" {
		labelsActions = append(labelsActions, "View logs · j/k scroll · q quit")
		commands = append(commands, []string{"pueue-task-view", strconv.Itoa(*a.PueueID), "log"})
		if state(a.Result) == "Running" {
			labelsActions = append(labelsActions, "Follow logs · Ctrl-C then j/k scroll · F follow")
			commands = append(commands, []string{"pueue-task-view", strconv.Itoa(*a.PueueID), "follow"})
		}
	}
	if a.Thread != "" {
		labelsActions = append(labelsActions, "Inspect captured conversation")
		commands = append(commands, []string{"atuin", "threads", "show", a.Thread})
	}
	if len(commands) == 0 {
		return errors.New("attempt has no available terminal, logs, or captured conversation")
	}
	selected, err := picker.Pick(labelsActions, "action> ", false)
	if err != nil || selected < 0 {
		return err
	}
	command := commands[selected]
	return viewCommand(command[0], command[1:]...)
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
