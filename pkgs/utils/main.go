package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/editevent"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/fftabs"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/statusline"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/watch"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/wezspawn"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/worker"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/workspace"
)

type command struct {
	name    string
	summary string
	run     func(args []string) int
}

var commands = map[string]command{
	"agent-state":  {name: "agent-state", summary: agentstate.Summary, run: agentstate.Run},
	"edit-event":   {name: "edit-event", summary: editevent.Summary, run: editevent.Run},
	"firefox-tabs": {name: "firefox-tabs", summary: fftabs.Summary, run: fftabs.Run},
	"statusline":   {name: "statusline", summary: statusline.Summary, run: statusline.Run},
	"watch":        {name: "watch", summary: watch.Summary, run: watch.Run},
	"wezspawn":     {name: "wezspawn", summary: wezspawn.Summary, run: wezspawn.Run},
	"worker":       {name: "worker", summary: worker.Summary, run: worker.Run},
	"workspace":    {name: "workspace", summary: workspace.Summary, run: workspace.Run},
}

type link struct {
	command string
	args    []string
}

var links = map[string]link{
	"agent-edit-event": {command: "edit-event"},
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
