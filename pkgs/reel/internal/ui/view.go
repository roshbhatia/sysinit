package ui

import (
	"fmt"
	"io"
	"sort"
	"strings"

	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

const detailAt = 96

func (m Model) bodyHeight() int { return max(1, m.height-4) }

func (m Model) detailWidth() int {
	if !m.onDetail || m.width < detailAt {
		return 0
	}
	return min(48, m.width/3)
}

func (m Model) View() string {
	if m.quitted {
		return ""
	}
	switch m.mode {
	case modePick:
		return m.viewPick()
	case modeHelp:
		return m.viewHelp()
	}

	body := m.bodyHeight()
	tree := m.viewTree(m.width-m.detailWidth(), body)
	if m.detailWidth() > 0 {
		tree = lipgloss.JoinHorizontal(lipgloss.Top, tree, m.viewDetail(m.detailWidth(), body))
	}
	return strings.Join([]string{m.header(), tree, m.footer()}, "\n")
}

func (m Model) header() string {
	name, service, count := "no session", "", 0
	if m.current != nil {
		name, service, count = m.current.Title(), m.current.Service, m.current.Count
	}

	state := dim.Render("paused")
	if m.follow {
		state = live.Render("live")
	}
	left := title.Render("reel") + " " + accent.Render(service) + dim.Render(" · ") + plain.Render(name)
	right := fmt.Sprintf("%s %s", dim.Render(fmt.Sprintf("%d %s", count, plural(count, "span"))), state)

	gap := m.width - lipgloss.Width(left) - lipgloss.Width(right)
	if gap < 1 {
		gap = 1
	}
	return left + span(gap, " ") + right + "\n" + rule.Render(span(m.width, "─"))
}

func (m Model) footer() string {
	if m.filtering {
		return rule.Render(span(m.width, "─")) + "\n" + m.input.View()
	}
	line := m.help.ShortHelpView(keys.ShortHelp())
	if m.flash != "" {
		line = live.Render(m.flash)
	}
	// clip() counts runes, and a styled line is mostly escape bytes, so it
	// would cut the help after two entries. MaxWidth measures cells instead.
	return rule.Render(span(m.width, "─")) + "\n" + lipgloss.NewStyle().MaxWidth(m.width).Render(line)
}

// viewTree draws the visible window of rows. The cursor stays inside the window
// with 2 rows of margin, so a step near the edge scrolls rather than jumps.
func (m Model) viewTree(width, height int) string {
	if len(m.rows) == 0 {
		empty := "waiting for spans in " + m.source
		if m.query != "" {
			empty = "nothing matches " + m.query
		}
		return lipgloss.NewStyle().Width(width).Height(height).Render(dim.Render(empty))
	}

	offset := m.offset
	if m.at < offset+2 {
		offset = m.at - 2
	}
	if m.at > offset+height-3 {
		offset = m.at - height + 3
	}
	offset = min(max(0, offset), max(0, len(m.rows)-height))

	lines := make([]string, 0, height)
	for at := offset; at < len(m.rows) && len(lines) < height; at++ {
		lines = append(lines, m.line(m.rows[at], at == m.at, width))
	}
	for len(lines) < height {
		lines = append(lines, span(width, " "))
	}
	return strings.Join(lines, "\n")
}

func (m Model) line(one row, here bool, width int) string {
	style := roleStyle(one.node.Role)
	mark := "  "
	if here {
		mark = cursor.Render("❯ ")
	}

	labelWidth := min(38, max(16, width/2-10))
	label := one.prefix + one.node.Label
	if one.node.Pending {
		label = one.prefix + one.node.Label + " " + faint.Render("…")
	}
	if one.depth == 0 && one.node.Turn > 0 {
		label = fmt.Sprintf("%d. %s", one.node.Turn, one.node.Label)
	}
	if len(one.node.Children) > 0 {
		open := "▾ "
		if m.folded[one.node.Span.SpanID] {
			open = "▸ "
		}
		label = one.prefix + open + strings.TrimPrefix(label, one.prefix)
	}

	stamp := duration(one.node.Duration())
	barWidth := width - 2 - labelWidth - 9 - 1
	cells := []string{
		mark,
		style.Render(clip(label, labelWidth)),
		rule.Render("▏"),
		m.bar(one, barWidth),
		dim.Render(fmt.Sprintf("%8s ", stamp)),
	}

	line := strings.Join(cells, "")
	if here {
		return lipgloss.NewStyle().Reverse(true).Render(line)
	}
	return line
}

// bar places the row inside its own turn's window, so a child reads as a
// position and a length within the turn rather than against the whole run.
func (m Model) bar(one row, width int) string {
	if width < 4 {
		return span(max(0, width), " ")
	}
	start, end := one.root.Span.Start, one.root.Span.End
	window := end.Sub(start)
	if window <= 0 || one.node.Span.Start.IsZero() {
		return span(width, " ")
	}

	left := int(float64(one.node.Span.Start.Sub(start)) / float64(window) * float64(width))
	size := int(float64(one.node.Duration()) / float64(window) * float64(width))
	left = min(max(0, left), width-1)
	size = min(max(1, size), width-left)

	return faint.Render(span(left, "·")) +
		roleStyle(one.node.Role).Render(span(size, "█")) +
		faint.Render(span(width-left-size, "·"))
}

func (m Model) viewDetail(width, height int) string {
	node := m.node()
	if node == nil {
		return lipgloss.NewStyle().Width(width).Height(height).Render("")
	}

	inner := width - 3
	lines := []string{title.Render(clip(node.Label, inner))}
	if node.Span.Name != node.Label {
		lines = append(lines, dim.Render(clip(node.Span.Name, inner)))
	}
	lines = append(lines,
		"",
		field("role", string(node.Role), inner),
		field("span", node.Span.SpanID, inner),
		field("trace", node.Span.TraceID, inner),
		field("start", node.Span.Start.Format("15:04:05.000"), inner),
		field("took", duration(node.Duration()), inner),
	)
	if node.Note != "" {
		lines = append(lines, field("note", node.Note, inner))
	}
	if node.Span.Failed {
		lines = append(lines, bad.Render(clip("failed: "+node.Span.Error, inner)))
	}

	if len(node.Facets) > 0 {
		lines = append(lines, "", dim.Render("phases"))
		for _, facet := range node.Facets {
			short := facet.Name[strings.LastIndex(facet.Name, ".")+1:]
			lines = append(lines, field(short, duration(facet.Duration()), inner))
		}
	}

	if attrs := sorted(node.Span.Attrs); len(attrs) > 0 {
		lines = append(lines, "", dim.Render("attributes"))
		for _, key := range attrs {
			lines = append(lines, field(key, node.Span.Attrs[key], inner))
		}
	}

	if len(lines) > height {
		lines = lines[:height]
	}
	for len(lines) < height {
		lines = append(lines, "")
	}
	body := lipgloss.NewStyle().Width(width - 2).MaxWidth(width - 2).Render(strings.Join(lines, "\n"))
	return lipgloss.JoinHorizontal(lipgloss.Top, rule.Render(column("│", height)), " "+body)
}

func field(name, value string, width int) string {
	if value == "" {
		return ""
	}
	head := min(12, width/3)
	return tagKey.Render(clip(name, head)) + " " + tagText.Render(clip(value, max(0, width-head-1)))
}

func sorted(attrs map[string]string) []string {
	skip := map[string]bool{"service.name": true, "session.id": true}
	out := make([]string, 0, len(attrs))
	for key := range attrs {
		if !skip[key] {
			out = append(out, key)
		}
	}
	sort.Strings(out)
	return out
}

func column(ch string, height int) string {
	lines := make([]string, height)
	for at := range lines {
		lines[at] = ch
	}
	return strings.Join(lines, "\n")
}

func (m Model) viewPick() string {
	lines := []string{title.Render("sessions"), rule.Render(span(m.width, "─"))}
	for at, one := range m.list {
		mark := "  "
		if at == m.pickAt {
			mark = cursor.Render("❯ ")
		}
		index := dim.Render(fmt.Sprintf("%d.", at+1))
		if at >= 9 {
			index = dim.Render("  ")
		}
		line := fmt.Sprintf("%s%s %s %s %s %s",
			mark, index,
			accent.Render(clip(one.Service, 12)),
			plain.Render(clip(one.Title(), 38)),
			dim.Render(fmt.Sprintf("%4d %-5s", one.Count, plural(one.Count, "span"))),
			dim.Render(ago(one.Last, m.now)),
		)
		lines = append(lines, line)
	}
	if len(m.list) == 0 {
		lines = append(lines, dim.Render("  no sessions in "+m.source))
	}
	lines = append(lines, "", dim.Render("  enter attach · esc back · 1-9 jump"))
	return strings.Join(lines, "\n")
}

func (m Model) viewHelp() string {
	return strings.Join([]string{
		title.Render("reel keys"),
		rule.Render(span(m.width, "─")),
		m.help.FullHelpView(keys.FullHelp()),
		"",
		dim.Render("any key returns"),
	}, "\n")
}

// Print writes one session as plain lines, for the non-interactive paths.
func Print(out io.Writer, one *session.Session) {
	fmt.Fprintf(out, "%s %s  %d spans\n", one.Service, one.Title(), one.Count)
	for _, root := range one.Roots {
		fmt.Fprintf(out, "%d. %s  %s\n", root.Turn, root.Label, duration(root.Duration()))
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
