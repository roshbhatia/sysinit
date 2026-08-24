// Package diffview renders a unified diff as a folding file tree whose hunks
// hang under the outline symbol that owns them, annotated with the call edges
// the edit added or removed.
//
// ast-grep outline names what a file declares, git diff names which lines
// moved, and calldiff names which call edges the move added or removed. All
// three carry a file and a line, so a symbol range is the join key: a hunk
// belongs to the symbol whose range holds its first new line, and so does a
// call site. A language none of them can read renders as a flat list of hunks.
package diffview

import "strings"

// Line is one diff line. kind is ' ' carried, '+' added, '-' removed.
type Line struct {
	Kind byte
	Text string
}

type Hunk struct {
	OldAt, NewAt int
	Sym          string
	Lines        []Line
}

type File struct {
	Path     string
	Add, Del int
	Hunks    []Hunk
}

// Symbol is one outline entry, with the line range it spans in the new file.
type Symbol struct {
	Kind     string
	Name     string
	From, To int
}

// Edge is one call site in the new file, which is what calldiff reports.
type Edge struct {
	Line  int
	Added bool
}

// Parse reads a unified diff. A patch can touch several files, so the path
// comes off each +++ header rather than from the caller. The tree then matches
// the patch, not the command that produced it.
func Parse(src string) []File {
	out := []File{}
	var f *File
	var h *Hunk
	closeHunk := func() {
		if f != nil && h != nil {
			f.Hunks = append(f.Hunks, *h)
		}
		h = nil
	}
	closeFile := func() {
		closeHunk()
		if f != nil {
			out = append(out, *f)
		}
		f = nil
	}
	for _, ln := range strings.Split(src, "\n") {
		switch {
		case strings.HasPrefix(ln, "--- "):
		case strings.HasPrefix(ln, "+++ "):
			closeFile()
			path := strings.TrimSpace(strings.TrimPrefix(ln, "+++ "))
			path = strings.TrimPrefix(path, "b/")
			f = &File{Path: path}
		// git marks a file with no trailing newline with a backslash line. It
		// is not a diff line, and read as one it prints as a blank carried row.
		case strings.HasPrefix(ln, "\\ "):
		case strings.HasPrefix(ln, "@@"):
			closeHunk()
			nh := Hunk{OldAt: 1, NewAt: 1}
			head, sym, _ := strings.Cut(strings.TrimPrefix(ln, "@@"), "@@")
			nh.Sym = strings.TrimSpace(sym)
			for _, part := range strings.Fields(head) {
				n := lineStart(part)
				if strings.HasPrefix(part, "-") {
					nh.OldAt = n
				} else if strings.HasPrefix(part, "+") {
					nh.NewAt = n
				}
			}
			h = &nh
		case h != nil && ln != "":
			d := Line{Kind: ln[0], Text: expandTabs(ln[1:])}
			switch d.Kind {
			case '+':
				f.Add++
			case '-':
				f.Del++
			default:
				d.Kind = ' '
			}
			h.Lines = append(h.Lines, d)
		case h != nil:
			h.Lines = append(h.Lines, Line{Kind: ' '})
		}
	}
	closeFile()
	return out
}

// lineStart reads the first number out of a -66,6 or +66,13 range.
func lineStart(part string) int {
	digits, n := strings.TrimLeft(part, "-+"), 0
	if i := strings.IndexByte(digits, ','); i >= 0 {
		digits = digits[:i]
	}
	for _, c := range digits {
		if c < '0' || c > '9' {
			return 1
		}
		n = n*10 + int(c-'0')
	}
	if n < 1 {
		return 1
	}
	return n
}

// A terminal renders a tab over 4 columns, and lipgloss counts it as 1, so a
// Go patch tears the side by side divider unless the tabs come out first.
func expandTabs(s string) string {
	if !strings.Contains(s, "\t") {
		return s
	}
	b := &strings.Builder{}
	col := 0
	for _, r := range s {
		if r != '\t' {
			b.WriteRune(r)
			col++
			continue
		}
		n := 4 - col%4
		b.WriteString(strings.Repeat(" ", n))
		col += n
	}
	return b.String()
}

// sbsRow is one printed line of the side by side view. A row with only one
// side filled is a pure insert or a pure delete, and the blank opposite half
// says so without a marker glyph.
type sbsRow struct {
	oldNo, newNo int
	oldTx, newTx string
	oldOn, newOn bool
	carried      bool
}

func sbsRows(h Hunk) []sbsRow {
	out, o, n, i := []sbsRow{}, h.OldAt, h.NewAt, 0
	for i < len(h.Lines) {
		if h.Lines[i].Kind == ' ' {
			t := h.Lines[i].Text
			out = append(out, sbsRow{oldNo: o, newNo: n, oldTx: t, newTx: t, carried: true})
			o, n, i = o+1, n+1, i+1
			continue
		}
		dels, adds := []string{}, []string{}
		for i < len(h.Lines) && h.Lines[i].Kind == '-' {
			dels = append(dels, h.Lines[i].Text)
			i++
		}
		for i < len(h.Lines) && h.Lines[i].Kind == '+' {
			adds = append(adds, h.Lines[i].Text)
			i++
		}
		for k := 0; k < max(len(dels), len(adds)); k++ {
			r := sbsRow{}
			if k < len(dels) {
				r.oldNo, r.oldTx, r.oldOn = o, dels[k], true
				o++
			}
			if k < len(adds) {
				r.newNo, r.newTx, r.newOn = n, adds[k], true
				n++
			}
			out = append(out, r)
		}
	}
	return out
}

type treeNode struct {
	name string
	file *File
	kids []*treeNode
}

func (n *treeNode) insert(f *File) {
	parts, cur := strings.Split(f.Path, "/"), n
	for i, p := range parts {
		leaf, found := i == len(parts)-1, (*treeNode)(nil)
		for _, k := range cur.kids {
			if k.name == p && (k.file != nil) == leaf {
				found = k
				break
			}
		}
		if found == nil {
			found = &treeNode{name: p}
			if leaf {
				found.file = f
			}
			cur.kids = append(cur.kids, found)
		}
		cur = found
	}
}

// A chain of directories with one child each spends a level of indent per
// segment and says nothing. Merging the chain into one label gives that indent
// back to the diff body.
func (n *treeNode) collapse() {
	for _, k := range n.kids {
		k.collapse()
	}
	if n.file == nil && len(n.kids) == 1 && n.kids[0].file == nil {
		k := n.kids[0]
		n.name, n.kids = n.name+"/"+k.name, k.kids
	}
}
