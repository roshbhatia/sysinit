// Package transcript reads what Claude Code writes to disk and builds the whole
// run from it: the turns, the model calls, the tool calls under the call that
// asked for them, and the text of all three.
//
// It used to emit records only. A record decorates a span, so a session with no
// OTLP span had nothing to decorate and `traces --session <id>` printed "0
// items" over a 9.8MB transcript. The spans are here now, which is what the
// codex reader already did, so the tree stands up from disk alone and OTLP adds
// timing to it rather than being required for it.
//
// The shape on disk is a linked list, not a tree: every entry carries
// parentUuid. The tree a reader wants is coarser than that list, because one
// assistant message is written as several entries sharing a requestId, one per
// content block. Grouping by requestId is what turns the list back into
//
//	turn        the prompt
//	└─ model    the reasoning and the reply
//	   └─ tool  what the reply asked to run, and what came back
//
// which is the shape the tool calls actually have: they belong to the model call
// that requested them, not to the turn as siblings of it.
package transcript

import (
	"bufio"
	"encoding/json"
	"fmt"
	"maps"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

// The events this package emits. session.AddRecords matches on the suffix, so
// every harness reader shares one vocabulary.
const (
	EventText   = "transcript.assistant"
	EventResult = "transcript.tool_result"
	EventPrompt = "transcript.user_prompt"
)

// Service names the records and spans so they key into the same session Claude
// Code's own OTLP export does. Its service.name is claude-code, and anything
// else would open a second session beside the real one.
const Service = "claude-code"

// Root is where Claude Code keeps one directory per project and one file per
// session inside it.
func Root() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".claude", "projects")
}

// Read walks every transcript touched inside the window. A file is opened only
// when its own mtime is inside it, because a project directory holds every
// session ever run and the current one is a few of them.
func Read(root string, window time.Duration, session string) otlp.Batch {
	out := otlp.Batch{}
	if root == "" {
		return out
	}
	since := time.Now().Add(-window)
	dirs, err := os.ReadDir(root)
	if err != nil {
		return out
	}
	for _, dir := range dirs {
		if !dir.IsDir() {
			continue
		}
		files, err := os.ReadDir(filepath.Join(root, dir.Name()))
		if err != nil {
			continue
		}
		for _, f := range files {
			if !strings.HasSuffix(f.Name(), ".jsonl") {
				continue
			}
			if session != "" && !strings.Contains(f.Name(), session) {
				continue
			}
			info, err := f.Info()
			if err != nil || info.ModTime().Before(since) {
				continue
			}
			one := ReadFile(filepath.Join(root, dir.Name(), f.Name()))
			out.Spans = append(out.Spans, one.Spans...)
			out.Records = append(out.Records, one.Records...)
		}
	}
	return out
}

// entry is the subset of a transcript line this package reads. Claude Code
// writes a dozen record types and adds more between versions, so an unknown
// type decodes to a zero entry and is skipped rather than failing the file.
type entry struct {
	Type       string          `json:"type"`
	UUID       string          `json:"uuid"`
	ParentUUID string          `json:"parentUuid"`
	SessionID  string          `json:"sessionId"`
	RequestID  string          `json:"requestId"`
	Timestamp  string          `json:"timestamp"`
	CWD        string          `json:"cwd"`
	GitBranch  string          `json:"gitBranch"`
	AITitle    string          `json:"aiTitle"`
	Sidechain  bool            `json:"isSidechain"`
	Meta       bool            `json:"isMeta"`
	AgentID    string          `json:"agentId"`
	Subtype    string          `json:"subtype"`
	Level      string          `json:"level"`
	Content    json.RawMessage `json:"content"`
	ToolResult json.RawMessage `json:"toolUseResult"`
	Message    struct {
		Model      string          `json:"model"`
		StopReason string          `json:"stop_reason"`
		Content    json.RawMessage `json:"content"`
		Usage      usage           `json:"usage"`
	} `json:"message"`

	at     time.Time
	blocks []block
	text   string
}

type usage struct {
	Input      int `json:"input_tokens"`
	Output     int `json:"output_tokens"`
	CacheRead  int `json:"cache_read_input_tokens"`
	CacheWrite int `json:"cache_creation_input_tokens"`
}

type block struct {
	Type      string          `json:"type"`
	Text      string          `json:"text"`
	Thinking  string          `json:"thinking"`
	ID        string          `json:"id"`
	Name      string          `json:"name"`
	Input     json.RawMessage `json:"input"`
	ToolUseID string          `json:"tool_use_id"`
	Content   json.RawMessage `json:"content"`
	IsError   bool            `json:"is_error"`
}

// A transcript line can reach a megabyte, because a tool result is stored whole.
// bufio.Scanner's default 64k limit silently ended the file at the first one.
const maxLine = 8 << 20

// A turn holds every model call made while answering one prompt, and a model
// call holds every tool it asked for. Both need an end time, and both learn it
// only from their last child, so the file is read whole before any span is
// emitted.
type node struct {
	id         string
	parent     string
	start, end time.Time
	attrs      map[string]string
	name       string
}

func ReadFile(path string) otlp.Batch {
	entries, session, title := parse(path)
	if len(entries) == 0 {
		return otlp.Batch{}
	}
	return build(entries, session, title)
}

func parse(path string) ([]entry, string, string) {
	f, err := os.Open(path)
	if err != nil {
		return nil, "", ""
	}
	defer func() { _ = f.Close() }()

	out := []entry{}
	sessionID, title := "", ""
	scan := bufio.NewScanner(f)
	scan.Buffer(make([]byte, 0, 64<<10), maxLine)
	for scan.Scan() {
		var e entry
		if json.Unmarshal(scan.Bytes(), &e) != nil {
			continue
		}
		if e.SessionID != "" {
			sessionID = e.SessionID
		}
		// The harness writes a human title for the run and traces named every
		// session by 8 characters of a uuid instead.
		if e.Type == "ai-title" && e.AITitle != "" {
			title = e.AITitle
		}
		if e.Type != "assistant" && e.Type != "user" && e.Type != "system" {
			continue
		}
		e.at, _ = time.Parse(time.RFC3339Nano, e.Timestamp)
		// A message's content is a string on a typed prompt and a block list
		// everywhere else, and both carry text a reader wants.
		if json.Unmarshal(e.Message.Content, &e.blocks) != nil {
			_ = json.Unmarshal(e.Message.Content, &e.text)
		}
		out = append(out, e)
	}
	if err := scan.Err(); err != nil {
		// A read error mid file leaves a partial run rather than none: the
		// entries already parsed are still the truth about what ran.
		return out, sessionID, title
	}
	return out, sessionID, title
}

// build walks the entries in order, opening a turn on each prompt and a model
// call on each new requestId. Order is the tree here: the harness appends, so an
// entry always belongs to the most recent open parent of its kind.
func build(entries []entry, sessionID, title string) otlp.Batch {
	batch := otlp.Batch{}
	base := attrsOf(entries, title)

	turns := []*node{}
	models := map[string]*node{}
	tools := map[string]*node{}
	order := []*node{}
	var turn *node
	seq := 0

	for _, e := range entries {
		switch {
		case e.isPrompt():
			seq++
			turn = &node{
				id:    e.UUID,
				start: e.at,
				end:   e.at,
				name:  "agent.turn",
				attrs: with(base, map[string]string{
					"interaction.sequence": strconv.Itoa(seq),
					"user_prompt":          e.prompt(),
					"user_prompt_length":   strconv.Itoa(len(e.prompt())),
				}),
			}
			turns = append(turns, turn)
			order = append(order, turn)
			batch.Records = append(batch.Records, otlp.Record{
				Event: EventPrompt, Service: Service, Session: sessionID, At: e.at,
				Body: e.prompt(), Attrs: map[string]string{"prompt": e.prompt()},
			})

		case e.Type == "assistant":
			// Every content block of one reply is its own line, all sharing the
			// request id, so the id is what groups them back into one call.
			if turn == nil {
				turn = openTurn(&turns, &order, base, e, &seq)
			}
			id := e.RequestID
			if id == "" {
				id = e.UUID
			}
			stretch(turn, e.at)
			batch.Records = append(batch.Records, e.reply(sessionID, id)...)

			// A model call is a row only when it said something. A call that
			// only asked for a tool carried no text and no reasoning, so the
			// tree read "claude-opus-5 → Shell" above "Shell <command>": two
			// rows for one fact, on half the rows in the run. Its tools hang
			// off the turn instead, and its numbers ride the tool they asked
			// for, so nothing is lost and the tree reads as a conversation.
			found := models[id]
			if found == nil && e.said() {
				found = &node{
					id: id, parent: turn.id, start: e.at, end: e.at, name: "agent.model",
					attrs: with(base, map[string]string{"request_id": id}),
				}
				models[id] = found
				order = append(order, found)
			}
			// The request's counts ride the tool only when the model call was
			// collapsed and has no row of its own. Putting them on both put one
			// request's tokens on two spans, and a turn that summed its subtree
			// then reported more context than the model can hold: 317 of 1237
			// requests in one session were counted twice.
			under, usage := turn, e.usageAttrs()
			if found != nil {
				found.attrs["request_id"] = id
				e.foldInto(found)
				under = found
				usage = map[string]string{"request_id": id}
			}
			for _, one := range e.calls(under, usage) {
				tools[one.id] = one
				order = append(order, one)
			}

		case e.Type == "system":
			if turn == nil || quietNotes[e.Subtype] {
				continue
			}
			// A compaction is not a note. It is where the run lost its own
			// history, which is the single most useful landmark in a long one,
			// and traces already draws it as its own kind.
			name := "agent.note"
			if strings.Contains(e.Subtype, "compact") {
				name = "agent.compact"
			}
			note := &node{
				id: e.UUID, parent: turn.id, start: e.at, end: e.at, name: name,
				attrs: with(base, map[string]string{
					"note.kind": orDash(e.Subtype), "note.level": orDash(e.Level),
					"note.text": flatten(e.Content),
				}),
			}
			order = append(order, note)
			stretch(turn, e.at)

		default:
			// A user entry that is not a prompt carries the results of the
			// tools the last reply asked for.
			for _, b := range e.blocks {
				if b.Type != "tool_result" || b.ToolUseID == "" {
					continue
				}
				batch.Records = append(batch.Records, otlp.Record{
					Event: EventResult, Service: Service, Session: sessionID, At: e.at,
					Body: first(flatten(b.Content), flatten(e.ToolResult)),
					Attrs: map[string]string{
						"tool_use_id": b.ToolUseID,
						"is_error":    boolText(b.IsError),
					},
				})
				found, ok := tools[b.ToolUseID]
				if !ok {
					continue
				}
				found.end = e.at
				if b.IsError {
					found.attrs["success"] = "false"
				}
				// Only the call that owns this tool grows. Stretching whichever
				// model call was last seen gave a 2 second reply a duration of
				// 2m42s, which was the whole turn it opened.
				if owner := models[found.attrs["request_id"]]; owner != nil {
					stretch(owner, e.at)
				}
				stretch(turn, e.at)
			}
		}
	}

	for _, one := range order {
		if one.end.Before(one.start) {
			one.end = one.start
		}
		batch.Spans = append(batch.Spans, otlp.Span{
			TraceID: sessionID, SpanID: one.id, ParentID: one.parent, Name: one.name,
			Service: Service, Session: sessionID,
			Start: one.start, End: one.end, Attrs: one.attrs,
			Failed: one.attrs["success"] == "false",
		})
	}
	sort.SliceStable(batch.Spans, func(a, b int) bool {
		return batch.Spans[a].Start.Before(batch.Spans[b].Start)
	})
	return batch
}

// A reply can arrive before any prompt: a resumed session opens mid turn, and a
// compaction writes one with no prompt of its own. A stand-in turn keeps those
// replies in the tree instead of dropping them.
func openTurn(turns *[]*node, order *[]*node, base map[string]string, e entry, seq *int) *node {
	*seq++
	one := &node{
		id: "turn-" + e.UUID, start: e.at, end: e.at, name: "agent.turn",
		attrs: with(base, map[string]string{
			"interaction.sequence": strconv.Itoa(*seq),
			"user_prompt":          "",
		}),
	}
	*turns = append(*turns, one)
	*order = append(*order, one)
	return one
}

func (e entry) isPrompt() bool {
	// A meta entry is a system reminder the harness injected, not something the
	// reader typed, and counting one as a turn split the run at every hook.
	if e.Type != "user" || e.Meta {
		return false
	}
	for _, b := range e.blocks {
		if b.Type == "tool_result" {
			return false
		}
	}
	return e.prompt() != ""
}

func (e entry) prompt() string {
	if e.text != "" {
		return e.text
	}
	parts := []string{}
	for _, b := range e.blocks {
		if b.Type == "text" && b.Text != "" {
			parts = append(parts, b.Text)
		}
	}
	return strings.Join(parts, "\n\n")
}

// foldInto adds one entry's facts to the model call it belongs to. The token
// counts are on the entry that carries the reply, and the stop reason on the one
// that ends it, so both arrive later than the call's own first line.
func (e entry) foldInto(one *node) {
	stretch(one, e.at)
	if e.Message.Model != "" {
		one.attrs["gen_ai.request.model"] = e.Message.Model
		one.attrs["model"] = e.Message.Model
	}
	if e.Message.StopReason != "" {
		one.attrs["stop_reason"] = e.Message.StopReason
	}
	u := e.Message.Usage
	if u.Output > 0 {
		one.attrs["output_tokens"] = strconv.Itoa(u.Output)
	}
	if u.Input > 0 {
		one.attrs["input_tokens"] = strconv.Itoa(u.Input)
	}
	if u.CacheRead > 0 {
		one.attrs["cache_read_tokens"] = strconv.Itoa(u.CacheRead)
	}
	if u.CacheWrite > 0 {
		one.attrs["cache_creation_tokens"] = strconv.Itoa(u.CacheWrite)
	}
}

func (e entry) reply(sessionID, requestID string) []otlp.Record {
	text, thinking := []string{}, []string{}
	for _, b := range e.blocks {
		switch b.Type {
		case "text":
			text = append(text, b.Text)
		case "thinking":
			thinking = append(thinking, b.Thinking)
		}
	}
	if len(text) == 0 && len(thinking) == 0 {
		return nil
	}
	return []otlp.Record{{
		Event: EventText, Service: Service, Session: sessionID, At: e.at,
		Body: strings.Join(text, "\n\n"),
		Attrs: map[string]string{
			"request_id": requestID,
			"thinking":   strings.Join(thinking, "\n\n"),
		},
	}}
}

// calls turns the reply's tool_use blocks into spans under it. The name and the
// arguments live only here: no OTLP attribute carries a tool's input, so a run
// read from spans alone shows a tool row with nothing in it.
// said reports whether this line carried anything a reader would read. A line
// holding only tool_use blocks is the API's half of a tool call, not a message.
func (e entry) said() bool {
	for _, b := range e.blocks {
		if (b.Type == "text" && strings.TrimSpace(b.Text) != "") ||
			(b.Type == "thinking" && strings.TrimSpace(b.Thinking) != "") {
			return true
		}
	}
	return false
}

// usageAttrs is what the collapsed model call was carrying. It rides the tool
// span so the tokens a request cost stay attached to the work it did.
func (e entry) usageAttrs() map[string]string {
	out := map[string]string{}
	u := e.Message.Usage
	for key, n := range map[string]int{
		"output_tokens":         u.Output,
		"input_tokens":          u.Input,
		"cache_read_tokens":     u.CacheRead,
		"cache_creation_tokens": u.CacheWrite,
	} {
		if n > 0 {
			out[key] = strconv.Itoa(n)
		}
	}
	if e.Message.Model != "" {
		out["gen_ai.request.model"] = e.Message.Model
	}
	if e.RequestID != "" {
		out["request_id"] = e.RequestID
	}
	return out
}

func (e entry) calls(parent *node, extra map[string]string) []*node {
	out := []*node{}
	for _, b := range e.blocks {
		if b.Type != "tool_use" || b.ID == "" {
			continue
		}
		name := "agent.tool"
		if editors[b.Name] {
			name = "agent.edit"
		}
		attrs := with(parent.attrs, map[string]string{
			"tool_name":   b.Name,
			"tool_use_id": b.ID,
		})
		delete(attrs, "stop_reason")
		delete(attrs, "user_prompt")
		delete(attrs, "user_prompt_length")
		delete(attrs, "interaction.sequence")
		maps.Copy(attrs, extra)
		maps.Copy(attrs, argsOf(b.Name, b.Input, attrs["cwd"]))
		// The call is requested when the reply ends, and the result stamps the
		// end. Until it arrives the span is a point, which is what an open tool
		// call is.
		out = append(out, &node{
			id: b.ID, parent: parent.id, start: e.at, end: e.at,
			name: name, attrs: attrs,
		})
	}
	return out
}

// The harness writes its own bookkeeping as system entries. A row saying
// "turn_duration -" tells a reader nothing they cannot read in the time column,
// and there is one per turn.
var quietNotes = map[string]bool{
	"turn_duration": true,
	"token_usage":   true,
	"atis_latch":    true,
}

// A write is drawn as a diff rather than as a blob of arguments, so it is named
// apart from the tools that only read.
var editors = map[string]bool{"Edit": true, "Write": true, "NotebookEdit": true}

// argsOf lifts the arguments a reader actually reads onto the span. full_command
// and file_path are the two keys the rest of traces already looks for, so a
// transcript-built row reads the same as an OTLP-built one.
func argsOf(tool string, raw json.RawMessage, cwd string) map[string]string {
	out := map[string]string{}
	if len(raw) == 0 {
		return out
	}
	var args map[string]json.RawMessage
	if json.Unmarshal(raw, &args) != nil {
		return out
	}
	text := func(key string) string {
		var s string
		if raw, ok := args[key]; ok && json.Unmarshal(raw, &s) == nil {
			return s
		}
		return ""
	}
	for _, key := range []string{"command", "pattern", "prompt", "query", "url", "description"} {
		if v := text(key); v != "" {
			out["full_command"] = v
			break
		}
	}
	// A delegate names the lane its work runs in, and the name is only in the
	// call's own arguments. Without it a subagent's rows read "+main/Agent",
	// which is the tool's name and not the agent's.
	for _, key := range []string{"subagent_type", "agent_type", "agent", "name"} {
		if v := text(key); v != "" {
			out["subagent_type"] = v
			break
		}
	}
	if v := text("file_path"); v != "" {
		// The repository relative path is what a reader recognises. The absolute
		// one spent 45 of the preview's columns on a prefix every row shared.
		out["file_path"] = relative(cwd, v)
		if out["full_command"] == "" {
			out["full_command"] = out["file_path"]
		}
	}
	// An edit is drawn as a diff, and Claude Code records a replacement rather
	// than a diff, so the diff is built here. Codex hands over a unified diff
	// already; without this a Claude edit rendered as a wall of arguments.
	before, after := text("old_string"), text("new_string")
	if before == "" && after == "" {
		after = text("content")
	}
	if before != "" || after != "" {
		patch, added, removed := unified(out["file_path"], before, after)
		out["traces.patch"] = patch
		out["lines_added"] = strconv.Itoa(added)
		out["lines_removed"] = strconv.Itoa(removed)
		out["files_changed"] = "1"
	}
	// Whatever is left is still worth keeping: a reader who opens the attrs tab
	// on a tool they do not recognise should see what it was handed.
	if out["full_command"] == "" {
		out["full_command"] = compact(raw)
	}
	out["tool_input_size_bytes"] = strconv.Itoa(len(raw))
	_ = tool
	return out
}

// unified turns one replacement into one hunk. An Edit swaps a contiguous block,
// so every old line is a deletion and every new line an addition: no line
// matching is needed, and inventing a smarter diff here would only disagree with
// the editor about what actually changed.
func unified(path, before, after string) (string, int, int) {
	if path == "" {
		path = "edit"
	}
	oldPath, newPath := path, path
	if before == "" {
		oldPath = "/dev/null"
	}
	if after == "" {
		newPath = "/dev/null"
	}
	del := lines(before)
	add := lines(after)
	b := &strings.Builder{}
	fmt.Fprintf(b, "--- %s\n+++ %s\n", oldPath, newPath)
	fmt.Fprintf(b, "@@ -1,%d +1,%d @@\n", len(del), len(add))
	for _, one := range del {
		fmt.Fprintf(b, "-%s\n", one)
	}
	for _, one := range add {
		fmt.Fprintf(b, "+%s\n", one)
	}
	return b.String(), len(add), len(del)
}

// relative trims the working directory off a path inside it. A path elsewhere is
// left absolute, because that is the fact worth seeing about it.
func relative(cwd, path string) string {
	if cwd == "" || !strings.HasPrefix(path, cwd) {
		return path
	}
	return strings.TrimPrefix(strings.TrimPrefix(path, cwd), "/")
}

func lines(text string) []string {
	if text == "" {
		return nil
	}
	return strings.Split(strings.TrimRight(text, "\n"), "\n")
}

func attrsOf(entries []entry, title string) map[string]string {
	// The activity marker is what tells the session builder that this tree is
	// the authoritative one. Without it the Claude Code OTLP spans for the same
	// run stood beside these, so one model call was two rows: 731 request ids
	// carried two spans each in one measured session.
	out := map[string]string{
		"service.name":  Service,
		"traces.view":   "activity",
		"traces.source": "claude-transcript",
	}
	if title != "" {
		out["session.title"] = title
	}
	for _, e := range entries {
		if e.CWD != "" {
			out["cwd"] = e.CWD
		}
		if e.GitBranch != "" {
			out["git.branch"] = e.GitBranch
		}
		if out["cwd"] != "" && out["git.branch"] != "" {
			break
		}
	}
	return out
}

func with(base, extra map[string]string) map[string]string {
	out := make(map[string]string, len(base)+len(extra))
	maps.Copy(out, base)
	maps.Copy(out, extra)
	return out
}

func stretch(one *node, at time.Time) {
	if one == nil || at.IsZero() {
		return
	}
	if one.start.IsZero() || at.Before(one.start) {
		one.start = at
	}
	if at.After(one.end) {
		one.end = at
	}
}

// A tool result is a string on the cheap tools and a content block list on the
// ones that return an image or a document, so both shapes reduce to text here.
func flatten(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var text string
	if json.Unmarshal(raw, &text) == nil {
		return text
	}
	var blocks []block
	if json.Unmarshal(raw, &blocks) == nil {
		parts := []string{}
		for _, b := range blocks {
			if b.Text != "" {
				parts = append(parts, b.Text)
			}
		}
		return strings.Join(parts, "\n")
	}
	// A structured result, which is what a file tool returns. stdout is the
	// field a reader wants; the rest is metadata traces already has.
	var fields struct {
		Stdout string `json:"stdout"`
		Stderr string `json:"stderr"`
	}
	if json.Unmarshal(raw, &fields) == nil && (fields.Stdout != "" || fields.Stderr != "") {
		return strings.TrimRight(fields.Stdout+"\n"+fields.Stderr, "\n")
	}
	return compact(raw)
}

func compact(raw json.RawMessage) string {
	var value any
	if json.Unmarshal(raw, &value) != nil {
		return ""
	}
	out, err := json.Marshal(value)
	if err != nil {
		return ""
	}
	return string(out)
}

func first(values ...string) string {
	for _, one := range values {
		if one != "" {
			return one
		}
	}
	return ""
}

func orDash(s string) string {
	if s == "" {
		return "-"
	}
	return s
}

func boolText(b bool) string {
	if b {
		return "true"
	}
	return ""
}
