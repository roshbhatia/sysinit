package ui

import (
	"fmt"
	"io"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

// Print writes the tree once, for the non-interactive paths. It draws no
// columns and no colour, because its reader is a pipe or a scrollback rather
// than a pane that can be scrolled.
func Print(out io.Writer, one *session.Session) {
	fmt.Fprintf(out, "%s %s  %d spans\n", one.Service, one.Title(), one.Count)
	for _, root := range one.Roots {
		fmt.Fprintf(out, "%d. %s  %s%s\n", root.Turn, root.Label, duration(root.Duration()), ask(root.Prompt))
		printKids(out, root, "   ")
	}
}

func printKids(out io.Writer, node *session.Node, prefix string) {
	for at, kid := range node.Children {
		branch, tail := "├─ ", "│  "
		if at == len(node.Children)-1 {
			branch, tail = "└─ ", "   "
		}
		note := kid.Note
		if note != "" {
			note = "  " + note
		}
		fmt.Fprintf(out, "%s%s%s  %s%s\n", prefix, branch, kid.Label, duration(kid.Duration()), note)
		printKids(out, kid, prefix+tail)
	}
}

// ask is the turn's prompt, cut to one line. A whole prompt would bury the
// tree it heads.
func ask(prompt string) string {
	if prompt == "" {
		return ""
	}
	one := oneLine(prompt)
	if len(one) > 72 {
		one = one[:71] + "…"
	}
	return "  " + one
}
