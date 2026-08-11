package review

import (
	"fmt"
	"strings"
)

// Markdown renders a status as the brief an agent acts on. It leads with the
// verdict, then the work the verdict implies, in the order the author should
// deal with it: removals first (a task the reviewer wants gone should not be
// started), then comments, then what moved after the review.
func Markdown(st *Status) string {
	var b strings.Builder
	fmt.Fprintf(&b, "# Review: %s\n\n", st.Change)

	if !st.Reviewed {
		b.WriteString("Decision: none recorded. This change has not been reviewed.\n")
		return b.String()
	}

	fmt.Fprintf(&b, "Decision: %s\n", st.Decision)
	if st.Stale {
		fmt.Fprintf(&b, "Status: stale. The artifacts changed after this decision (reviewed %s, now %s).\n",
			st.ReviewHash, st.ChangeHash)
	} else {
		b.WriteString("Status: current. The artifacts match what was reviewed.\n")
	}

	if st.Note != "" {
		b.WriteString("\n## Note\n\n")
		b.WriteString(st.Note)
		b.WriteString("\n")
	}

	for _, a := range st.Annotations {
		if a.Scope == ScopeChange && strings.TrimSpace(a.Comment) != "" {
			b.WriteString("\n## Change comment\n\n")
			b.WriteString(a.Comment)
			b.WriteString("\n")
			break
		}
	}

	if len(st.Dropped) > 0 {
		b.WriteString("\n## Requested removals\n\n")
		for _, is := range st.Dropped {
			writeItem(&b, is)
		}
	}

	var comments []ItemStatus
	for _, is := range st.Items {
		if is.Comment != "" && is.Action != ActionDrop {
			comments = append(comments, is)
		}
	}
	if len(comments) > 0 {
		b.WriteString("\n## Comments\n\n")
		for _, is := range comments {
			writeItem(&b, is)
		}
	}

	if len(st.Hunks) > 0 {
		b.WriteString("\n## Code comments\n\n")
		for _, h := range st.Hunks {
			loc := h.File
			if h.Header != "" {
				loc += " " + oneLine(h.Header)
			}
			fmt.Fprintf(&b, "- %s\n", loc)
			for _, line := range strings.Split(strings.TrimSpace(h.Comment), "\n") {
				fmt.Fprintf(&b, "  > %s\n", strings.TrimSpace(line))
			}
		}
	}

	var moved []ItemStatus
	for _, is := range st.Items {
		if is.Drift == DriftNew || is.Drift == DriftChanged {
			moved = append(moved, is)
		}
	}
	if len(moved) > 0 {
		b.WriteString("\n## Changed since review\n\n")
		for _, is := range moved {
			fmt.Fprintf(&b, "- [%s] %s (%s)\n", is.Phase, oneLine(is.Text), is.Drift)
		}
	}

	if st.BaseCommit != "" {
		fmt.Fprintf(&b, "\nCode reviewed from %s. Run `specutil review diff %s` for what moved since.\n",
			shortSHA(st.BaseCommit), st.Change)
	}

	if len(st.Dropped) == 0 && len(comments) == 0 && len(moved) == 0 && len(st.Hunks) == 0 {
		b.WriteString("\nNo open comments and no drift since the review.\n")
	}
	return b.String()
}

// shortSHA abbreviates a commit for a human reader.
func shortSHA(s string) string {
	if len(s) > 12 {
		return s[:12]
	}
	return s
}

func writeItem(b *strings.Builder, is ItemStatus) {
	fmt.Fprintf(b, "- [%s] %s\n", is.Phase, oneLine(is.Text))
	if is.Comment != "" {
		for _, line := range strings.Split(strings.TrimSpace(is.Comment), "\n") {
			fmt.Fprintf(b, "  > %s\n", strings.TrimSpace(line))
		}
	}
}

// oneLine flattens a task's text so a multi-line item still renders as one
// bullet.
func oneLine(s string) string {
	return strings.Join(strings.Fields(s), " ")
}
