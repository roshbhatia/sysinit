package ui

import (
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
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
// actorOf names the lane a row ran in. @ is the person and + is an agent, so a
// glance down the column separates what was asked from what was done:
//
//	@user            the person, on a turn
//	+main            the main thread
//	+reviewer        a teammate
//	+main/Explore    a subagent the main thread spawned
//	+reviewer/oracle a subagent a teammate spawned
//
// It read @main, @sub and @team before, which said the kind of thing that ran
// and not which one, so two subagents in one turn were one name.
//
// lane is the path the caller walked to reach this node. A row keeps its
// caller's lane: the Agent call itself was made by whoever called it, and its
// work is what belongs to the new lane.
func actorOf(node *session.Node, k kind, lane string) string {
	if k == kindTurn {
		return "@user"
	}
	if lane == "" {
		lane = "main"
	}
	return "+" + lane
}

// laneUnder is the lane a delegate's children run in. A teammate is a named
// agent and replaces the lane; a subagent extends it, because it was spawned
// from inside the lane above it.
func laneUnder(node *session.Node, k kind, lane string) string {
	if k != kindSub && k != kindTeam {
		return lane
	}
	if who := node.Span.Attrs["agent.name"]; who != "" {
		return who
	}
	name := firstOf(node.Span.Attrs["subagent_type"], node.Span.Attrs["agent_id"], node.Label)
	if name == "" {
		return lane
	}
	if lane == "" {
		lane = "main"
	}
	return lane + "/" + name
}

func firstOf(values ...string) string {
	for _, one := range values {
		if one != "" {
			return one
		}
	}
	return ""
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

// rowOf derives one row.
func rowOf(node *session.Node, depth int, lane string) row {
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
		actor:   actorOf(node, k, lane),
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
	out.preview = Line(node)
	// The span column already carries the label, so a preview that repeats it
	// spends the widest column on a second copy. Every codex row read `auth`
	// beside `auth`, and every amp row read `fetch /api/…` beside the same URL.
	if out.preview == out.label || strings.HasPrefix(out.preview, out.label) {
		out.preview = strings.TrimSpace(strings.TrimPrefix(out.preview, out.label))
	}
	return out
}

// Line is the one line of text under a row's label. Both the pane and the
// printed tree call it, because they disagreed for a release: the printed tree
// read Note alone, so every Bash row said "Bash" while the pane showed the
// command.
//
// The order is what the reader most wants to know first. A reply the transcript
// carries beats a stop reason derived from the span, and a turn's prompt beats
// both, because a turn row with no prompt says only "open".
func Line(node *session.Node) string {
	switch {
	case node.Prompt != "":
		return oneLine(node.Prompt)
	case node.Text != "":
		return oneLine(node.Text)
	case node.Thinking != "":
		return oneLine(node.Thinking)
	// A model call whose tools are its own children said "called a tool" beside
	// the tool it called, one row below. Naming them is the same width spent on
	// something the reader cannot already see, and it survives folding.
	case len(node.Children) > 0 && node.Role == session.RoleModel:
		return "\u2192 " + kidNames(node)
	case node.Note != "":
		if arg := preview(node); arg != "" && arg != node.Label {
			return arg
		}
		return oneLine(node.Note)
	}
	return preview(node)
}

func kidNames(node *session.Node) string {
	seen, names := map[string]bool{}, []string{}
	for _, kid := range node.Children {
		if kid.Label == "" || seen[kid.Label] {
			continue
		}
		seen[kid.Label] = true
		names = append(names, kid.Label)
		if len(names) == 4 {
			break
		}
	}
	out := strings.Join(names, ", ")
	if len(node.Children) > len(names) {
		out += ", \u2026"
	}
	return out
}

// preview is the one line of text under the label. The attribute that carries
// it differs per harness, so the first one present wins; full_command is where
// Claude Code puts a tool's real argument.
func preview(node *session.Node) string {
	if text := node.Span.Attrs["full_command"]; text != "" {
		return oneLine(trimLead(text))
	}
	for _, key := range []string{
		"note.text", "command", "prompt", "user_prompt",
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

// lead is the run of a command that says nothing about what it does: a variable
// assignment, and a cd into the directory every command in the run shares. Eight
// rows read "R=/Users/roshan/github/persona…" and the eight commands under that
// prefix were invisible.
//
// The whole command is still on the row's own body, so nothing is lost here.
func trimLead(text string) string {
	for {
		trimmed := strings.TrimLeft(text, " \t;&")
		rest, cut := dropOne(trimmed)
		if !cut {
			return trimmed
		}
		text = rest
	}
}

func dropOne(text string) (string, bool) {
	// A cd is dropped only when something follows it, or the row would go blank
	// on the command whose whole point was the directory.
	if rest, ok := strings.CutPrefix(text, "cd "); ok {
		if at := strings.IndexAny(rest, ";&|\n"); at >= 0 {
			return rest[at:], true
		}
		return text, false
	}
	// VAR=value, with the value quoted or bare. An assignment is a prefix only
	// while it is the first word, which is what the space check enforces.
	head, rest, ok := strings.Cut(text, " ")
	if !ok {
		return text, false
	}
	name, _, isAssign := strings.Cut(head, "=")
	if !isAssign || name == "" {
		return text, false
	}
	for _, r := range name {
		if !(r == '_' || r >= 'A' && r <= 'Z' || r >= 'a' && r <= 'z' || r >= '0' && r <= '9') {
			return text, false
		}
	}
	return rest, true
}

// matches keeps a row whose own text matches, and keeps a parent whose subtree
// holds a match, so a filter never orphans a hit.
func matches(node *session.Node, query string) bool {
	if query == "" {
		return true
	}
	// The filter searched the label and the note only, so /goroutine matched
	// nothing in a run that discussed goroutines for an hour: the words are in
	// the reply and in the tool output, which is what the transcript carries.
	hay := strings.ToLower(strings.Join([]string{
		node.Label, node.Note, node.Span.Name, node.Prompt,
		node.Text, node.Thinking, node.Output,
	}, " "))
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

// output is what the tool actually printed. It comes from the transcript, so it
// is empty on a run traces read from spans alone.
func (r row) output() string {
	if r.node == nil {
		return ""
	}
	return r.node.Output
}

// raw is everything behind the row, unreflowed: the prompt, the reply and the
// reasoning, or the tool's input and its output. The pane wraps and colours all
// of it, and yank and $EDITOR are what recover the bytes.
func (r row) raw() string {
	if r.node == nil {
		return r.preview
	}
	parts := []string{}
	add := func(head, body string) {
		if body != "" {
			parts = append(parts, "## "+head+"\n\n"+body)
		}
	}
	add("Prompt", r.node.Prompt)
	add("Reasoning", r.node.Thinking)
	add("Response", r.node.Text)
	add("Changes", r.node.Patch)
	if r.node.Prompt == "" && r.node.Text == "" && r.node.Thinking == "" {
		add("Input", r.preview)
	}
	add("Output", r.node.Output)
	if len(parts) == 0 {
		return r.preview
	}
	return strings.Join(parts, "\n\n")
}

// command is the row's argument as it was written, newlines and all. The row's
// preview is one line by necessity and the body was reading that, so a heredoc
// arrived in the pane as one unreadable paragraph.
func (r row) command() string {
	if r.node == nil {
		return r.preview
	}
	for _, key := range []string{"full_command", "command", "tool_input", "note.text", "file_path"} {
		if text := r.node.Span.Attrs[key]; text != "" {
			return text
		}
	}
	return r.preview
}

// request names the model call this row belongs to. A tool row carries the id of
// the call that asked for it, which is what lets a rollup count one request's
// tokens once rather than once per row it touched.
func (r row) request() string {
	if r.node == nil {
		return ""
	}
	return r.node.Span.Attrs["request_id"]
}
