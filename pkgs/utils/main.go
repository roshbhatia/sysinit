package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/forward"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/statusline"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/wezspawn"
)

type command struct {
	name    string
	summary string
	run     func(args []string) int
}

var commands = map[string]command{
	"agent-state": {
		name:    "agent-state",
		summary: "publish pane status",
		run:     forward.Command("SYSINIT_AGENT_STATE", "agent-state"),
	},
	"firefox-tabs": {
		name:    "firefox-tabs",
		summary: "read Firefox session tabs",
		run:     forward.Command("SYSINIT_FIREFOX_TABS", "firefox-tabs"),
	},
	"statusline": {
		name:    "statusline",
		summary: statusline.Summary,
		run:     statusline.Run,
	},
	"watch": {
		name:    "watch",
		summary: "view worker logs and pane status",
		run:     forward.Command("SYSINIT_AGENT_WATCH", "agent-watch"),
	},
	"wezspawn": {
		name:    "wezspawn",
		summary: wezspawn.Summary,
		run:     wezspawn.Run,
	},
	"worker": {
		name:    "worker",
		summary: "run a command in a reused pane",
		run:     forward.Command("SYSINIT_WORKER", "worker"),
	},
	"workspace": {
		name:    "workspace",
		summary: "inspect workspace repositories and changes",
		run:     forward.Command("SYSINIT_WORKSPACE", "ws"),
	},
}

type link struct {
	command string
	args    []string
}

var links = map[string]link{
	"agent-state":      {command: "agent-state"},
	"agent-statusline": {command: "statusline"},
	"agent-watch":      {command: "watch"},
	"firefox-tabs":     {command: "firefox-tabs"},
	"wezspawn":         {command: "wezspawn"},
	"worker":           {command: "worker"},
	"ws":               {command: "workspace"},
}

const usageHeader = `utils: the commands that used to be shell scripts

Usage:
  utils <command> [args...]

Commands:
`

func usage(w *os.File) {
	_, _ = fmt.Fprint(w, usageHeader)
	names := make([]string, 0, len(commands))
	for name := range commands {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		_, _ = fmt.Fprintf(w, "  %-16s %s\n", name, commands[name].summary)
	}

	_, _ = fmt.Fprintf(w, "\nEach of these names runs one command directly:\n")
	installed := make([]string, 0, len(links))
	for name := range links {
		installed = append(installed, name)
	}
	sort.Strings(installed)
	for _, name := range installed {
		l := links[name]
		spelled := l.command
		for _, arg := range l.args {
			spelled += " " + arg
		}
		_, _ = fmt.Fprintf(w, "  %-16s utils %s\n", name, spelled)
	}
}

func main() {
	if l, ok := links[filepath.Base(os.Args[0])]; ok {
		args := make([]string, 0, len(l.args)+len(os.Args)-1)
		args = append(args, l.args...)
		args = append(args, os.Args[1:]...)
		os.Exit(commands[l.command].run(args))
	}

	if len(os.Args) < 2 {
		usage(os.Stderr)
		os.Exit(2)
	}
	switch os.Args[1] {
	case "-h", "--help", "help":
		usage(os.Stdout)
		return
	}
	cmd, ok := commands[os.Args[1]]
	if !ok {
		fmt.Fprintf(os.Stderr, "utils: unknown command %q\n", os.Args[1])
		usage(os.Stderr)
		os.Exit(2)
	}
	os.Exit(cmd.run(os.Args[2:]))
}
