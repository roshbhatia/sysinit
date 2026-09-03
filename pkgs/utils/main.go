package main

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/citelock"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/editevent"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/fftabs"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/guard"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/lintgate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/loopgate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/note"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/prosegate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/statusline"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/transcript"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/watch"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/wezspawn"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/worker"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/worklog"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/workspace"
)

type command struct {
	name    string
	summary string
	run     func(args []string) int
}

var commands = map[string]command{
	"agent-state":     {name: "agent-state", summary: agentstate.Summary, run: agentstate.Run},
	"bash-guard":      {name: "bash-guard", summary: guard.BashSummary, run: guard.RunBash},
	"citelock":        {name: "citelock", summary: citelock.Summary, run: citelock.Run},
	"edit-event":      {name: "edit-event", summary: editevent.Summary, run: editevent.Run},
	"exit-code-guard": {name: "exit-code-guard", summary: guard.ExitCodeSummary, run: guard.RunExitCode},
	"firefox-tabs":    {name: "firefox-tabs", summary: fftabs.Summary, run: fftabs.Run},
	"lint-gate":       {name: "lint-gate", summary: lintgate.Summary, run: lintgate.Run},
	"loop-gate":       {name: "loop-gate", summary: loopgate.Summary, run: loopgate.Run},
	"nix-guard":       {name: "nix-guard", summary: guard.NixSummary, run: guard.RunNix},
	"note":            {name: "note", summary: note.Summary, run: note.Run},
	"prose-gate":      {name: "prose-gate", summary: prosegate.Summary, run: prosegate.Run},
	"read-guard":      {name: "read-guard", summary: guard.ReadSummary, run: guard.RunRead},
	"statusline":      {name: "statusline", summary: statusline.Summary, run: statusline.Run},
	"transcript-link": {name: "transcript-link", summary: transcript.Summary, run: transcript.Run},
	"watch":           {name: "watch", summary: watch.Summary, run: watch.Run},
	"wezspawn":        {name: "wezspawn", summary: wezspawn.Summary, run: wezspawn.Run},
	"worker":          {name: "worker", summary: worker.Summary, run: worker.Run},
	"worklog":         {name: "worklog", summary: worklog.Summary, run: worklog.Run},
	"workspace":       {name: "workspace", summary: workspace.Summary, run: workspace.Run},
}

type link struct {
	command string
	args    []string
}

var links = map[string]link{
	"agent-edit-event": {command: "edit-event"},
	"agent-note-open":  {command: "note", args: []string{"list", "--open", "--hook"}},
	"agent-state":      {command: "agent-state"},
	"agent-statusline": {command: "statusline"},
	"agent-watch":      {command: "watch"},
	"bash-guard":       {command: "bash-guard"},
	"citelock":         {command: "citelock"},
	"exit-code-guard":  {command: "exit-code-guard"},
	"firefox-tabs":     {command: "firefox-tabs"},
	"lint-gate":        {command: "lint-gate"},
	"loop-gate":        {command: "loop-gate"},
	"nix-guard":        {command: "nix-guard"},
	"note":             {command: "note"},
	"prose-gate":       {command: "prose-gate"},
	"read-guard":       {command: "read-guard"},
	"transcript-link":  {command: "transcript-link"},
	"wezspawn":         {command: "wezspawn"},
	"worker":           {command: "worker"},
	"worklog":          {command: "worklog"},
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
