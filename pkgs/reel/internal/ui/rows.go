package ui

import (
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
)

// The layout reads a flat row list, and the session holds a tree. rows walks
// the tree once per redraw and derives every column the layout draws, so the
// layout never reaches back into a span.

// kindOf picks the row's kind, which decides its colour and its detail tags.
// The session package already assigned a role; the kinds below are finer than
// roles, so the span name breaks the tie the role cannot.
func kindOf(node *session.Node) kind {
	name := node.Span.Name
	switch {
	case node.Role == session.RoleTurn:
		return kindTurn
	case node.Role == session.RoleDelegate:
		if strings.Contains(strings.ToLower(node.Label), "team") {
			return kindTeam
		}
		return kindSub
	case node.Role == session.RoleModel:
		// A model call that produced no output tokens and carries thinking is
		// the reasoning step rather than the reply.
		if node.Span.Attrs["thinking"] != "" || strings.Contains(name, "think") {
			return kindThink
		}
		return kindPrompt
	case strings.Contains(name, "hook"):
		return kindHook
	case strings.HasPrefix(node.Label, "mcp__"):
		return kindMCP
	case strings.HasPrefix(node.Label, "/") || strings.Contains(name, "skill"):
		return kindSkill
	}
	// Anything left is a plain step. It was kindHook, which made every amp HTTP
	// fetch read as `@hook` in the actor column and print "configured in ``" in
	// the inspector.
	return kindTool
}

// actorOf names who ran the row. A hook and a delegated subagent are the two
// that a reader has to tell apart from the main loop at a glance.
func actorOf(node *session.Node, k kind) string {
	if who := node.Span.Attrs["agent.name"]; who != "" {
		return "@" + who
	}
	switch k {
	case kindTurn:
		return "@user"
	case kindHook:
		return "@hook"
	case kindSub:
		return "@sub"
	case kindTeam:
		return "@team"
	}
	return "@main"
}

func number(attrs map[string]string, keys ...string) int {
	for _, key := range keys {
		text := attrs[key]
		if text == "" {
			continue
		}
		if n, err := strconv.Atoi(text); err == nil {
			return n
		}
		// A token count arrives as a float when the source is Observe rather
		// than the collector, because JSON has one number type.
		if f, err := strconv.ParseFloat(text, 64); err == nil {
			return int(f)
		}
	}
	return 0
}

// rowOf derives one row. at and took are percentages of the whole run, so the
// waterfall stays comparable when the run grows.
func rowOf(node *session.Node, depth int, first time.Time, span time.Duration) row {
	k := kindOf(node)
	attrs := node.Span.Attrs

	label := node.Label
	if k == kindTurn && node.Turn > 0 {
		label = "turn " + strconv.Itoa(node.Turn)
	}

	out := row{
		node:    node,
		depth:   depth,
		kind:    k,
		actor:   actorOf(node, k),
		label:   label,
		preview: node.Note,
		in: number(attrs, "input_tokens", "gen_ai.usage.input_tokens") +
			number(attrs, "cache_read_tokens") +
			number(attrs, "cache_creation_tokens"),
		out:    number(attrs, "output_tokens", "gen_ai.usage.output_tokens"),
		ms:     int(node.Duration() / time.Millisecond),
		src:    attrs["hook.source"],
		add:    number(attrs, "lines_added", "add"),
		del:    number(attrs, "lines_removed", "del"),
		files:  number(attrs, "files_changed", "files"),
		fail:   node.Span.Failed,
		parent: len(node.Children) > 0,
	}
	// A turn's text is its prompt, which arrives as a log record. Without it a
	// turn row reads "open" and says nothing about what was asked.
	if node.Prompt != "" {
		out.preview = oneLine(node.Prompt)
	}
	if out.preview == "" {
		out.preview = preview(node)
	}
	// The span column already carries the label, so a preview that repeats it
	// spends the widest column on a second copy. Every codex row read `auth`
	// beside `auth`, and every amp row read `fetch /api/…` beside the same URL.
	if out.preview == out.label || strings.HasPrefix(out.preview, out.label) {
		out.preview = strings.TrimSpace(strings.TrimPrefix(out.preview, out.label))
	}
	if span > 0 {
		out.at = clampPct(int(node.Span.Start.Sub(first) * 100 / span))
		out.took = max(1, clampPct(int(node.Duration()*100/span)))
	}
	return out
}

func clampPct(n int) int {
	if n < 0 {
		return 0
	}
	if n > 100 {
		return 100
	}
	return n
}

// preview is the one line of text under the label. The attribute that carries
// it differs per harness, so the first one present wins; full_command is where
// Claude Code puts a tool's real argument.
func preview(node *session.Node) string {
	for _, key := range []string{
		"full_command", "command", "prompt", "user_prompt",
		"tool_input", "input", "file_path", "gen_ai.request.model", "error",
	} {
		if text := node.Span.Attrs[key]; text != "" {
			return oneLine(text)
		}
	}
	if node.Span.Error != "" {
		return oneLine(node.Span.Error)
	}
	// The label already carries what the span name says, and for a tool row it
	// says more: the tool's own name. Repeating claude_code.tool on every row
	// filled the column with one string and told the reader nothing.
	if node.Label == node.Span.Name {
		return node.Span.Name
	}
	return ""
}

func oneLine(text string) string {
	text = strings.ReplaceAll(text, "\n", "  ")
	return strings.TrimSpace(strings.Join(strings.Fields(text), " "))
}

// matches keeps a row whose own text matches, and keeps a parent whose subtree
// holds a match, so a filter never orphans a hit.
func matches(node *session.Node, query string) bool {
	if query == "" {
		return true
	}
	hay := strings.ToLower(node.Label + " " + node.Note + " " + node.Span.Name + " " + node.Prompt)
	if strings.Contains(hay, query) {
		return true
	}
	for _, kid := range node.Children {
		if matches(kid, query) {
			return true
		}
	}
	return false
}

// prompt is the whole text that opened this turn, for the inspector. The row
// itself carries a one line version of the same thing.
func (r row) prompt() string {
	if r.node == nil {
		return ""
	}
	if r.node.Prompt != "" {
		return r.node.Prompt
	}
	return r.preview
}
