// sysinit-agent is one binary hosting the agent runtime commands that used to
// be separate shell scripts.
//
// Multi-call rather than one binary per command: every command shares the store,
// lock, and sanitization code in internal/store, so separate binaries would
// either duplicate it or need this module anyway. Each command keeps its current
// name on PATH through a thin shim that execs the matching subcommand, so no
// caller knows the difference.
package main

import (
	"fmt"
	"os"
	"sort"
)

// command is one subcommand. Run receives the arguments after the subcommand
// name and returns the process exit code, so a command can distinguish "denied"
// from "failed" the way the guard scripts do.
type command struct {
	name    string
	summary string
	run     func(args []string) int
}

// Registered subcommands. Empty until the migration phases land one; the binary
// is built and packaged first so the packaging change and the behavior changes
// are never in the same commit.
var commands = map[string]command{}

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
		// Help is the one thing that goes to stdout: a caller asking for it
		// wants to read it, and everything else here keeps stdout for data.
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
