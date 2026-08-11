package vcs

import (
	"fmt"
	"strings"
)

// Text renders a diff for a terminal reader. It leads with the summary, because
// the first thing a reviewer needs is the size of what they are about to read.
func (d *Diff) Text() string {
	var b strings.Builder
	files, added, deleted := d.Stats()

	if d.Note != "" {
		fmt.Fprintf(&b, "No diff: %s\n", d.Note)
		return b.String()
	}
	if files == 0 {
		fmt.Fprintf(&b, "No changes against %s.\n", d.Base)
		return b.String()
	}

	noun := "files"
	if files == 1 {
		noun = "file"
	}
	fmt.Fprintf(&b, "%d %s changed against %s: +%d -%d\n", files, noun, d.Base, added, deleted)

	for _, f := range d.Files {
		b.WriteString("\n")
		switch f.Status {
		case StatusRenamed:
			fmt.Fprintf(&b, "%s (renamed from %s)\n", f.Path, f.OldPath)
		case StatusBinary:
			fmt.Fprintf(&b, "%s (binary)\n", f.Path)
		default:
			fmt.Fprintf(&b, "%s (%s)\n", f.Path, f.Status)
		}
		for _, h := range f.Hunks {
			fmt.Fprintf(&b, "  %s  [%s]\n", h.Header, h.Identity)
			for _, l := range h.Lines {
				fmt.Fprintf(&b, "  %s%s\n", marker(l.Kind), l.Text)
			}
		}
	}
	return b.String()
}

func marker(kind string) string {
	switch kind {
	case LineAdd:
		return "+"
	case LineDelete:
		return "-"
	default:
		return " "
	}
}
