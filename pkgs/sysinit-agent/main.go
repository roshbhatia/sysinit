// sysinit-agent is one binary hosting the agent runtime commands that used to
package main

import (
	"fmt"
	"os"
	"sort"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/citelock"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/editevent"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/guard"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/note"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/statusline"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/transcript"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/watch"
)

// command is one subcommand.
type command struct {
	name    string
	summary string
	run     func(args []string) int
}

// Registered subcommands.
var commands = map[string]command{
	"agent-state":     {name: "agent-state", summary: agentstate.Summary, run: agentstate.Run},
	"bash-guard":      {name: "bash-guard", summary: guard.BashSummary, run: guard.RunBash},
	"citelock":        {name: "citelock", summary: citelock.Summary, run: citelock.Run},
	"edit-event":      {name: "edit-event", summary: editevent.Summary, run: editevent.Run},
	"exit-code-guard": {name: "exit-code-guard", summary: guard.ExitCodeSummary, run: guard.RunExitCode},
	"note":            {name: "note", summary: note.Summary, run: note.Run},
	"statusline":      {name: "statusline", summary: statusline.Summary, run: statusline.Run},
	"transcript-link": {name: "transcript-link", summary: transcript.Summary, run: transcript.Run},
	"watch":           {name: "watch", summary: watch.Summary, run: watch.Run},
}

func usage(w *os.File) {
	fmt.Fprintf(w, "sysinit-agent: agent runtime commands\n\nUsage:\n  sysinit-agent <command> [args...]\n\nCommands:\n")
	if len(commands) == 0 {
		fmt.Fprintf(w, "  (none registered)\n")
		return
	}
	names := make([]string, 0, len(commands))
	for name := range commands {
		names = append(names, name)
	}
	sort.Strings(names)
	for _, name := range names {
		fmt.Fprintf(w, "  %-16s %s\n", name, commands[name].summary)
	}
}

func main() {
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
		fmt.Fprintf(os.Stderr, "sysinit-agent: unknown command %q\n", os.Args[1])
		usage(os.Stderr)
		os.Exit(2)
	}
	os.Exit(cmd.run(os.Args[2:]))
}
