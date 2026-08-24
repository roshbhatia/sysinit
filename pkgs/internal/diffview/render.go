package diffview

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
)

// The view answers three questions in the order a reader asks them. What
// changed: an eza shaped tree of the touched files, with the churn on each
// file line. How it changed: the hunks inlined under their own file, side by
// side where the pane is wide enough. Why: every hunk repeats the enclosing
// symbol from the unified header, so a hunk read halfway down the pane still
// names the function it belongs to.
//
// It renders its own ANSI rather than going through glamour, because the tree
// rail has to survive on the same line as a coloured diff body, and a chroma
// diff lexer only colours a line that starts with a plus or a minus.

const (
	// eza draws a tree in four columns per level. Matching it keeps the view
	// consistent with the shell the reader just came from.
	treeGuide = "│   "
	treeGap   = "    "
	treeTee   = "├── "
	treeEnd   = "└── "
	// A side by side half narrower than this wraps every second line, which
	// costs more than the alignment buys. Below it the view falls back to
	// unified.
	sbsMinText = 32
	numWidth   = 4
)

// Options is one render. Symbols and Edges are keyed on the same paths the
// files carry, and a path missing from either just renders without that layer.
type Options struct {
	Files   []File
	Width   int
	Symbols map[string][]Symbol
	Edges   map[string][]Edge
}

func Render(o Options) string {
	if len(o.Files) == 0 {
		return ""
	}
	width := max(20, o.Width)
	root := &treeNode{}
	add, del := 0, 0
	for i := range o.Files {
		root.insert(&o.Files[i])
		add, del = add+o.Files[i].Add, del+o.Files[i].Del
	}
	// The root carries no name, so it never merges. Its children do.
	for _, k := range root.kids {
		k.collapse()
	}

	b := &strings.Builder{}
	fmt.Fprintf(b, "%s   %s  %s\n\n",
		title.Render(fmt.Sprintf("%d %s", len(o.Files), plural(len(o.Files), "file"))),
		live.Render(fmt.Sprintf("+%d", add)),
		bad.Render(fmt.Sprintf("-%d", del)))
	// eza prints the root of a tree with no connector, so the first level here
	// gets none either.
	for _, k := range root.kids {
		if k.file == nil {
			b.WriteString(accent.Render(k.name+"/") + "\n")
			o.emitTree(b, k, "", width)
			continue
		}
		o.emitFile(b, k.file, "", "", width)
	}
	return strings.TrimRight(b.String(), "\n")
}

func (o Options) emitTree(b *strings.Builder, n *treeNode, prefix string, width int) {
	for i, k := range n.kids {
		conn, guide := treeTee, treeGuide
		if i == len(n.kids)-1 {
			conn, guide = treeEnd, treeGap
		}
		if k.file == nil {
			b.WriteString(rule.Render(prefix+conn) + accent.Render(k.name+"/") + "\n")
			o.emitTree(b, k, prefix+guide, width)
			continue
		}
		o.emitFile(b, k.file, prefix+conn, prefix+guide, width)
	}
}

// A group is one outline symbol with the hunks that landed inside it. A hunk
// no symbol claims keeps a nil item and renders bare, so a file with no
// outline reads exactly as it did before the symbol layer existed.
type symGroup struct {
	item     *Symbol
	hunks    []Hunk
	add, del int
	up, down int
}

func ownerOf(items []Symbol, line int) *Symbol {
	for i := range items {
		if line >= items[i].From && line <= items[i].To {
			return &items[i]
		}
	}
	return nil
}

// Walking the hunks in order rather than the symbols keeps the patch order the
// reader already saw in the terminal, and folds consecutive hunks that share a
// symbol into one heading.
func (o Options) symGroups(f *File) []symGroup {
	items, edges := o.Symbols[f.Path], o.Edges[f.Path]
	out, cur := []symGroup{}, -1
	for _, h := range f.Hunks {
		it := ownerOf(items, h.NewAt)
		if cur < 0 || out[cur].item != it {
			out = append(out, symGroup{item: it})
			cur = len(out) - 1
			if it != nil {
				for _, e := range edges {
					switch {
					case e.Line < it.From || e.Line > it.To:
					case e.Added:
						out[cur].up++
					default:
						out[cur].down++
					}
				}
			}
		}
		out[cur].hunks = append(out[cur].hunks, h)
		for _, d := range h.Lines {
			switch d.Kind {
			case '+':
				out[cur].add++
			case '-':
				out[cur].del++
			}
		}
	}
	return out
}

// The churn says how much moved and the call count says how far the move
// reaches, so a one line edit that rewires the graph does not read the same as
// a fifty line edit that rewires nothing.
func symRow(g symGroup, width int) string {
	right := live.Render(fmt.Sprintf("+%d", g.add)) + "  " + bad.Render(fmt.Sprintf("-%d", g.del))
	if g.up > 0 {
		right += "  " + live.Render(fmt.Sprintf("+%d %s", g.up, plural(g.up, "call")))
	}
	if g.down > 0 {
		right += "  " + bad.Render(fmt.Sprintf("-%d %s", g.down, plural(g.down, "call")))
	}
	room := width - lipgloss.Width(right) - len(g.item.Kind) - 3
	name := strings.TrimRight(clip(g.item.Name, max(8, room)), " ")
	head := faint.Render(g.item.Kind+" ") + accent.Render(name)
	gap := width - lipgloss.Width(head) - lipgloss.Width(right)
	if gap < 2 {
		gap = 2
	}
	return head + strings.Repeat(" ", gap) + right
}

// The file line carries the name on the left and the churn on the right, so a
// column of files compares at a glance. The body hangs off a rail that starts
// under the name, which keeps a hunk attached to its file when the view is
// scrolled past the file line.
func (o Options) emitFile(b *strings.Builder, f *File, conn, guide string, width int) {
	churn := live.Render(fmt.Sprintf("+%d", f.Add)) + "  " + bad.Render(fmt.Sprintf("-%d", f.Del))
	name := f.Path[strings.LastIndexByte(f.Path, '/')+1:]
	head := rule.Render(conn) + plain.Render(name)
	gap := width - lipgloss.Width(head) - lipgloss.Width(churn)
	if gap < 2 {
		gap = 2
	}
	b.WriteString(head + strings.Repeat(" ", gap) + churn + "\n")

	rail := rule.Render(guide + "│ ")
	deep := rule.Render(guide + "│ ╎ ")
	body := width - lipgloss.Width(guide) - 2
	for _, g := range o.symGroups(f) {
		r, w := rail, body
		if g.item != nil {
			b.WriteString(rail + symRow(g, body) + "\n")
			r, w = deep, body-2
		}
		for _, h := range g.hunks {
			b.WriteString(r + hunkHead(name, h, w, g.item != nil) + "\n")
			if half := (w - 3) / 2; half-numWidth-1 >= sbsMinText {
				for _, row := range sbsRows(h) {
					b.WriteString(r + sbsLine(row, half) + "\n")
				}
				continue
			}
			for _, d := range unifiedRows(h) {
				b.WriteString(r + d + "\n")
			}
		}
	}
	b.WriteString(rail + "\n")
}

// The header names the file and the line. It repeats the enclosing symbol only
// when no symbol row sits above it, because the outline already said it there.
func hunkHead(name string, h Hunk, width int, named bool) string {
	at := fmt.Sprintf("%s:%d", name, h.NewAt)
	label := at
	if h.Sym != "" && !named {
		label += " · " + h.Sym
	}
	// clip pads to its width, and a padded label would eat the rule, so the
	// padding comes straight back off.
	label = strings.TrimRight(clip(label, max(4, width-6)), " ")
	pad := width - lipgloss.Width(label) - 4
	if pad < 1 {
		pad = 1
	}
	return rule.Render("── ") + accent.Render(label) + rule.Render(" "+strings.Repeat("─", pad))
}

func sbsLine(r sbsRow, half int) string {
	text := half - numWidth - 1
	left, right := plain, plain
	if !r.carried {
		left, right = bad, live
	}
	l := numCell(r.oldNo, r.oldOn || r.carried) + left.Render(fit(clip(r.oldTx, text), text))
	rt := numCell(r.newNo, r.newOn || r.carried) + right.Render(fit(clip(r.newTx, text), text))
	return l + rule.Render(" │ ") + rt
}

func numCell(n int, on bool) string {
	if !on {
		return strings.Repeat(" ", numWidth+1)
	}
	return faint.Render(fmt.Sprintf("%*d ", numWidth, n))
}

// The narrow fallback keeps the plus and the minus, because without two
// columns the marker is the only thing that says which side a line is on.
func unifiedRows(h Hunk) []string {
	out, o, n := []string{}, h.OldAt, h.NewAt
	for _, d := range h.Lines {
		style, no := plain, n
		switch d.Kind {
		case '+':
			style, n = live, n+1
		case '-':
			style, no, o = bad, o, o+1
		default:
			o, n = o+1, n+1
		}
		out = append(out, numCell(no, true)+style.Render(string(d.Kind)+" "+d.Text))
	}
	return out
}
