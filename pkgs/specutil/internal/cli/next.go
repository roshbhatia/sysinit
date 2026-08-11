package cli

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/roshbhatia/specutil/internal/lifecycle"
	"github.com/spf13/cobra"
)

func newNextCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "next [change]",
		Short: "Report which subtasks are runnable now",
		Long: "Answers one question: what runs now.\n\n" +
			"A tasks.md declares a shape, a dependency edge per subtask, and a stop\n" +
			"condition. Without a consumer those declarations are documentation, and the\n" +
			"work gets done top to bottom whatever the graph says. This reads them.\n\n" +
			"Readiness never crosses a phase, because a phase is a boundary between runs.\n" +
			"The reported phase is the lowest-numbered one still holding pending work; the\n" +
			"ready set is every pending subtask in it whose dependencies are complete.\n\n" +
			"A graph phase with more than one runnable subtask reports concurrent, so the\n" +
			"caller can fan out. A loop phase does not: its next iteration reads the state\n" +
			"the current one writes. Owner gates and adversarial reviews are never counted\n" +
			"as fan-out work.\n\n" +
			"Exit codes:\n" +
			"  0  a ready set was reported, or every task is complete\n" +
			"  2  work remains but nothing is runnable, which means a dependency cycle\n\n" +
			"Typical invocations:\n" +
			"  specutil next                      # the active change\n" +
			"  specutil next my-change            # one change\n" +
			"  specutil next --as json | jq       # drive a runner from the ready set",
		Args: cobra.MaximumNArgs(1),
		RunE: runNext,
	}
	cmd.Flags().String("change", "", "report a single change (or pass as positional arg)")
	cmd.Flags().String("as", "text", "output format: text|json")
	cmd.Flags().StringP("out", "o", "", "write output to a file instead of stdout")
	return cmd
}

func runNext(cmd *cobra.Command, args []string) error {
	c, err := resolveChange(cmd, args)
	if err != nil {
		return err
	}
	emitWarnings(cmd, c.Warnings)

	n := lifecycle.ComputeNext(c)

	format, _ := cmd.Flags().GetString("as")
	if format == "json" {
		body, merr := json.MarshalIndent(n, "", "  ")
		if merr != nil {
			return merr
		}
		if werr := writeOut(cmd, append(body, '\n')); werr != nil {
			return werr
		}
	} else if werr := writeOut(cmd, []byte(renderNext(n))); werr != nil {
		return werr
	}

	// Pending work with an empty ready set is a cycle. It is a distinct exit code
	// so a runner loop halts instead of spinning on an empty answer.
	if !n.Done && len(n.Ready) == 0 {
		return errDependencyCycle{change: n.Change}
	}
	return nil
}

// errDependencyCycle signals pending work with an empty ready set. main maps it
// to exit code 2 so a runner loop halts instead of spinning on an empty answer.
type errDependencyCycle struct{ change string }

func (e errDependencyCycle) Error() string {
	return fmt.Sprintf("%s: work remains but no subtask is runnable, so its dependencies form a cycle", e.change)
}

// IsDependencyCycle reports that `next` found pending work it cannot schedule.
func IsDependencyCycle(err error) bool {
	_, ok := err.(errDependencyCycle)
	return ok
}

func renderNext(n lifecycle.Next) string {
	var b strings.Builder
	if n.Done {
		fmt.Fprintf(&b, "%s: every task is complete\n", n.Change)
		return b.String()
	}

	shape := n.Shape
	if shape == "" {
		shape = "no shape declared"
	}
	fmt.Fprintf(&b, "%s\nphase %s. %s (%s)\n", n.Change, n.Phase, n.PhaseName, shape)

	if n.Stop != "" {
		fmt.Fprintf(&b, "\nstop: %s\n", n.Stop)
	}

	fmt.Fprintf(&b, "\nready (%d)", len(n.Ready))
	switch {
	case n.Concurrent:
		fmt.Fprint(&b, ", runnable concurrently")
	case n.Shape == "graph" && !n.EdgesDeclared && len(n.Ready) > 1:
		fmt.Fprint(&b, ", order unstated: the phase declares no `deps:`, so run them in listed order")
	}
	fmt.Fprint(&b, ":\n")
	for _, t := range n.Ready {
		fmt.Fprintf(&b, "  %-6s %-8s %s%s\n", t.ID, label(t), firstWords(t.Text, 14), "")
	}
	if len(n.Ready) == 0 {
		fmt.Fprint(&b, "  none\n")
	}

	if len(n.Blocked) > 0 {
		fmt.Fprintf(&b, "\nblocked (%d):\n", len(n.Blocked))
		for _, t := range n.Blocked {
			fmt.Fprintf(&b, "  %-6s waits on %s\n", t.ID, strings.Join(t.WaitsOn, ", "))
		}
	}
	return b.String()
}

func label(t lifecycle.Task) string {
	switch {
	case t.Adverse:
		return "review"
	case t.Gate:
		return t.Kind
	case t.Kind == "" || t.Kind == "plain":
		return "task"
	default:
		return t.Kind
	}
}

// firstWords keeps a listing to one line per subtask.
func firstWords(text string, n int) string {
	words := strings.Fields(text)
	if len(words) <= n {
		return strings.Join(words, " ")
	}
	return strings.Join(words[:n], " ") + " ..."
}
