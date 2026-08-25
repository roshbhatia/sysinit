// Package session groups OTLP spans the way an agent run actually reads:
// one session, a numbered turn per prompt, and the model calls and tool calls
// the agent made inside that turn.
package session

import (
	"fmt"
	"maps"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/transcript"
)

type Role string

const (
	RoleTurn     Role = "turn"
	RoleModel    Role = "model"
	RoleTool     Role = "tool"
	RoleDelegate Role = "delegate"
	RoleSystem   Role = "system"
	RoleError    Role = "error"
)

// Claude Code closes a turn's own span only when the turn ends, so its tool and
// model children reach the collector first and stay parentless for minutes. The
// parent id they carry is still a stable turn key, so traces groups on that id and
// fills in the real span later. These two spans say how a tool call went, which
// belongs on the tool row rather than under it.
var foldedInto = map[string]bool{
	"claude_code.tool.execution":       true,
	"claude_code.tool.blocked_on_user": true,
}

var delegateTools = map[string]bool{
	"Agent": true,
	"Task":  true,
}

type Node struct {
	Span  otlp.Span
	Role  Role
	Label string
	Note  string
	// Prompt is the text that opened this turn. It arrives as a log record
	// rather than as a span attribute, so only a turn carries one.
	Prompt string
	// Text, Thinking and Output are what the harness wrote to disk and never
	// exported. They come from the transcript package, joined on the request or
	// the tool use id, and stay empty when no transcript was read.
	Text     string
	Thinking string
	Output   string
	Children []*Node
	Facets   []otlp.Span
	Pending  bool
	Turn     int
}

func (n *Node) Start() time.Time {
	if n.Pending {
		return n.Span.Start
	}
	return n.Span.Start
}

func (n *Node) End() time.Time { return n.Span.End }

func (n *Node) Duration() time.Duration { return n.Span.End.Sub(n.Span.Start) }

type Session struct {
	Key     string
	Service string
	ID      string
	First   time.Time
	Last    time.Time
	Count   int
	Roots   []*Node

	spans   map[string]otlp.Span
	prompts []otlp.Record
	texts   map[string]otlp.Record
	results map[string]otlp.Record
	dirs    map[string]bool
	dirty   bool
}

func (s *Session) Title() string {
	if s.ID != "" {
		return s.ID
	}
	return s.Key
}

// Short names the run in a header. A session that carries its own id is cut to
// 8 characters of it. A trace-keyed one is cut to the last 8 of the trace: the
// first 8 are the service name repeated, which read as "amp.cli amp.cli/".
func (s *Session) Short() string {
	title := s.Title()
	if at := strings.LastIndex(title, "/"); at >= 0 {
		title = title[at+1:]
		if len(title) > 8 {
			return title[len(title)-8:]
		}
		return title
	}
	if len(title) > 8 {
		return title[:8]
	}
	return title
}

type Store struct {
	sessions      map[string]*Session
	scope         map[string]bool
	scopeDir      string
	traceSessions map[string]string
}

func NewStore() *Store {
	return &Store{sessions: map[string]*Session{}, traceSessions: map[string]string{}}
}

// Scope narrows the store to a set of session ids, which is how traces opens on
// the runs that belong to the reader's working directory rather than on
// whichever run happens to be newest across the machine. An empty set is no
// scope at all.
func (s *Store) Scope(ids []string, dir string) {
	s.scopeDir = cleanDir(dir)
	if len(ids) == 0 {
		s.scope = nil
		return
	}
	s.scope = make(map[string]bool, len(ids))
	for _, id := range ids {
		s.scope[id] = true
	}
}

// Scoped reports whether a scope is in force, so a caller can say why the view
// is empty rather than leaving the reader to guess.
func (s *Store) Scoped() bool { return len(s.scope) > 0 || s.scopeDir != "" }

func (s *Store) inScope(one *Session) bool {
	if len(s.scope) == 0 && s.scopeDir == "" {
		return true
	}
	if s.scope[one.ID] {
		return true
	}
	for dir := range one.dirs {
		if s.scopeDir == dir || strings.HasPrefix(s.scopeDir, dir+string(filepath.Separator)) {
			return true
		}
	}
	return false
}

func cleanDir(dir string) string {
	if dir == "" {
		return ""
	}
	abs, err := filepath.Abs(dir)
	if err != nil {
		abs = dir
	}
	if real, err := filepath.EvalSymlinks(abs); err == nil {
		abs = real
	}
	return filepath.Clean(abs)
}

// key puts every span of one agent run together. opencode and codex emit no
// session id, so the trace id stands in and mergeRuns folds the pieces back.
func key(span otlp.Span) string {
	if span.Session != "" {
		return span.Service + "/" + span.Session
	}
	return span.Service + "/trace/" + span.TraceID
}

// A harness with no run identity is recovered from the shape a run has: a
// burst. Measured on codex 0.149.0, one `codex exec` produced 350 spans over 14
// traces, and nothing tied them together. `thread_id` was on 2 spans of the
// 350, `turn.id` on 3, and the resource carried no service.instance.id, so no
// attribute could do it.
//
// 30s is longer than any gap inside the measured run and shorter than the time
// between two runs a reader would call separate.
const runGap = 30 * time.Second

// mergeRuns folds the trace-keyed sessions of one service into runs. A session
// that carries its own id is never touched: claude and goose both name the run
// themselves, and guessing over a stated fact would be worse than not guessing.
func mergeRuns(in []*Session) []*Session {
	loose := map[string][]*Session{}
	out := []*Session{}
	for _, one := range in {
		if one.ID != "" {
			out = append(out, one)
			continue
		}
		loose[one.Service] = append(loose[one.Service], one)
	}

	for service, list := range loose {
		sort.Slice(list, func(a, b int) bool { return list[a].First.Before(list[b].First) })
		var run *Session
		for _, one := range list {
			if run != nil && one.First.Sub(run.Last) <= runGap {
				run.absorb(one)
				continue
			}
			run = one.clone(service)
			out = append(out, run)
		}
	}
	return out
}

// clone copies a session so a merge never mutates what the store holds. The
// store is read again on the next poll, and a merged session would otherwise
// keep growing across polls.
func (s *Session) clone(service string) *Session {
	out := &Session{
		Key:     s.Key,
		Service: service,
		First:   s.First,
		Last:    s.Last,
		Count:   s.Count,
		spans:   make(map[string]otlp.Span, len(s.spans)),
		prompts: append([]otlp.Record{}, s.prompts...),
		texts:   maps.Clone(s.texts),
		results: maps.Clone(s.results),
		dirs:    maps.Clone(s.dirs),
		dirty:   true,
	}
	if out.texts == nil {
		out.texts = map[string]otlp.Record{}
	}
	if out.results == nil {
		out.results = map[string]otlp.Record{}
	}
	for id, span := range s.spans {
		out.spans[id] = span
	}
	return out
}

func (s *Session) absorb(other *Session) {
	for id, span := range other.spans {
		if _, seen := s.spans[id]; !seen {
			s.Count++
		}
		s.spans[id] = span
	}
	s.prompts = append(s.prompts, other.prompts...)
	maps.Copy(s.texts, other.texts)
	maps.Copy(s.results, other.results)
	if s.dirs == nil {
		s.dirs = map[string]bool{}
	}
	maps.Copy(s.dirs, other.dirs)
	if other.First.Before(s.First) {
		s.First = other.First
	}
	if other.Last.After(s.Last) {
		s.Last = other.Last
	}
	s.dirty = true
}

// AddBatch joins Codex's `conversation.id` logs to spans that share their trace.
func (s *Store) AddBatch(batch otlp.Batch) {
	for _, one := range batch.Spans {
		if one.TraceID != "" && one.Session != "" {
			s.traceSessions[one.TraceID] = one.Session
		}
	}
	for _, one := range batch.Records {
		if one.TraceID != "" && one.Session != "" {
			s.traceSessions[one.TraceID] = one.Session
		}
	}
	for i := range batch.Spans {
		if batch.Spans[i].Session == "" {
			batch.Spans[i].Session = s.traceSessions[batch.Spans[i].TraceID]
		}
	}
	for i := range batch.Records {
		if batch.Records[i].Session == "" {
			batch.Records[i].Session = s.traceSessions[batch.Records[i].TraceID]
		}
	}
	s.Add(batch.Spans)
	s.AddRecords(batch.Records)
}

func (s *Store) Add(spans []otlp.Span) {
	for _, span := range spans {
		if span.SpanID == "" {
			continue
		}
		id := key(span)
		found, ok := s.sessions[id]
		if !ok {
			found = &Session{
				Key:     id,
				Service: span.Service,
				ID:      span.Session,
				First:   span.Start,
				spans:   map[string]otlp.Span{},
				dirs:    map[string]bool{},
			}
			s.sessions[id] = found
		}
		if _, seen := found.spans[span.SpanID]; !seen {
			found.Count++
		}
		found.spans[span.SpanID] = span
		if dir := cleanDir(span.Attrs["cwd"]); dir != "" {
			found.dirs[dir] = true
		}
		found.dirty = true
		if span.Start.Before(found.First) {
			found.First = span.Start
		}
		if span.End.After(found.Last) {
			found.Last = span.End
		}
	}
}

// Sessions returns every run, newest activity first.
func (s *Store) Sessions() []*Session {
	out := make([]*Session, 0, len(s.sessions))
	for _, one := range s.sessions {
		one.rebuild()
		if !s.inScope(one) {
			continue
		}
		out = append(out, one)
	}
	out = mergeRuns(out)
	for _, one := range out {
		one.rebuild()
	}
	// A harness without a session.id gets one fallback session per trace, and
	// opencode emits dozens of 1-span traces per run. Rank those below the real
	// runs so the picker opens on something worth attaching to.
	sort.Slice(out, func(a, b int) bool {
		if notable(out[a]) != notable(out[b]) {
			return notable(out[a])
		}
		return out[a].Last.After(out[b].Last)
	})
	return out
}

func notable(one *Session) bool { return one.ID != "" || one.Count >= 3 }

// Session selects out of Sessions rather than out of the raw map, because the
// raw map holds one entry per trace and mergeRuns is what joins the traces of a
// harness that emits no run id. Reading the map returned one fragment: --list
// advertised an opencode run of 734 spans and --session opened 1 of them.
//
// The suffix arm is what makes the name --list prints a usable selector: a
// trace-keyed run is named by the last 8 of its trace, which prefix-matches
// nothing. Without it, half the listed runs could not be opened by their name.
func (s *Store) Session(id string) *Session {
	if id == "" {
		return nil
	}
	for _, one := range s.Sessions() {
		switch {
		case one.ID == id, one.Key == id,
			one.ID != "" && strings.HasPrefix(one.ID, id),
			strings.HasSuffix(one.Key, id):
			return one
		}
	}
	return nil
}

// AddRecords keeps the log records a row can carry: the prompt that opened a
// turn, and the reply and tool output the transcript holds. Every other event a
// harness logs is already a span, and a second copy of it would double the row.
func (s *Store) AddRecords(records []otlp.Record) {
	for _, one := range records {
		switch {
		case strings.HasSuffix(one.Event, "user_prompt"):
			if one.Attrs["prompt"] == "" {
				continue
			}
			found := s.hold(one)
			found.prompts = append(found.prompts, one)
			found.dirty = true
		case one.Event == transcript.EventText:
			id := one.Attrs["request_id"]
			if id == "" {
				continue
			}
			found := s.hold(one)
			found.texts[id] = one
			found.dirty = true
		case one.Event == transcript.EventResult:
			id := one.Attrs["tool_use_id"]
			if id == "" {
				continue
			}
			found := s.hold(one)
			found.results[id] = one
			found.dirty = true
		}
	}
}

// hold finds the session a record belongs to, opening one when the record
// arrived first. A prompt reaches the collector before the turn span closes, so
// a session can be prompt first, and holding it saves the first turn from
// reading as untitled.
func (s *Store) hold(one otlp.Record) *Session {
	id := recordKey(one)
	found, ok := s.sessions[id]
	if !ok {
		found = &Session{
			Key: id, Service: one.Service, ID: one.Session, First: one.At,
			spans: map[string]otlp.Span{}, dirs: map[string]bool{},
		}
		s.sessions[id] = found
	}
	if dir := cleanDir(one.Attrs["cwd"]); dir != "" {
		found.dirs[dir] = true
	}
	if found.texts == nil {
		found.texts = map[string]otlp.Record{}
	}
	if found.results == nil {
		found.results = map[string]otlp.Record{}
	}
	return found
}

// attachText joins the transcript back to the spans. A model span carries the
// request id the reply was written under, and a tool span the tool use id its
// result was written under, so both are a map lookup rather than a time match.
func (s *Session) attachText(nodes map[string]*Node) {
	for _, node := range nodes {
		if found, ok := s.texts[node.Span.Attrs["request_id"]]; ok {
			node.Text, node.Thinking = found.Body, found.Attrs["thinking"]
		}
		if found, ok := s.results[node.Span.Attrs["tool_use_id"]]; ok {
			node.Output = found.Body
		}
	}
}

// recordKey matches key(), so a log record and a span of the same run land in
// the same session.
func recordKey(one otlp.Record) string {
	if one.Session != "" {
		return one.Service + "/" + one.Session
	}
	if one.TraceID != "" {
		return one.Service + "/trace/" + one.TraceID
	}
	return one.Service + "/log"
}

// A prompt is logged when it is submitted and the turn span starts a moment
// later, so the turn takes the newest prompt at or before its own start. The
// slack covers the other order, which a clock that is not monotonic across two
// exporters can produce.
const promptSlack = 2 * time.Second

func (s *Session) attachPrompts() {
	if len(s.prompts) == 0 {
		return
	}
	sort.Slice(s.prompts, func(a, b int) bool { return s.prompts[a].At.Before(s.prompts[b].At) })
	// One prompt belongs to one turn. Taking the newest prompt before each turn
	// instead gave three turns the same text, because a run holds more turn
	// spans than prompts: a parentless child stands in for its own turn.
	next := 0
	for _, root := range s.Roots {
		for next < len(s.prompts) && s.prompts[next].At.After(root.Span.Start.Add(promptSlack)) {
			break
		}
		if next < len(s.prompts) && !s.prompts[next].At.After(root.Span.Start.Add(promptSlack)) {
			root.Prompt = s.prompts[next].Attrs["prompt"]
			next++
		}
	}
}

func (s *Session) rebuild() {
	if !s.dirty {
		return
	}
	s.dirty = false

	nodes := make(map[string]*Node, len(s.spans))
	for id, span := range s.spans {
		if foldedInto[span.Name] {
			continue
		}
		nodes[id] = describe(span)
	}

	for _, span := range s.spans {
		if !foldedInto[span.Name] {
			continue
		}
		if parent, ok := nodes[span.ParentID]; ok {
			parent.Facets = append(parent.Facets, span)
			if span.Failed {
				parent.Role = RoleError
				parent.Span.Failed = true
			}
			if decision := span.Attrs["decision"]; decision != "" && decision != "accept" {
				parent.Note = decision
			}
		}
	}

	pending := map[string]*Node{}
	var roots []*Node
	for _, node := range nodes {
		if node.Span.ParentID == "" {
			roots = append(roots, node)
			continue
		}
		if parent, ok := nodes[node.Span.ParentID]; ok {
			parent.Children = append(parent.Children, node)
			continue
		}
		stand, ok := pending[node.Span.ParentID]
		if !ok {
			stand = &Node{
				Span:    otlp.Span{SpanID: node.Span.ParentID, Name: "turn", Start: node.Span.Start, End: node.Span.End},
				Role:    RoleTurn,
				Label:   "turn",
				Note:    "open",
				Pending: true,
			}
			pending[node.Span.ParentID] = stand
			roots = append(roots, stand)
		}
		if node.Span.Start.Before(stand.Span.Start) {
			stand.Span.Start = node.Span.Start
		}
		if node.Span.End.After(stand.Span.End) {
			stand.Span.End = node.Span.End
		}
		stand.Children = append(stand.Children, node)
	}

	s.attachText(nodes)

	for _, node := range nodes {
		sortKids(node)
	}
	for _, node := range pending {
		sortKids(node)
	}
	sort.Slice(roots, func(a, b int) bool { return roots[a].Span.Start.Before(roots[b].Span.Start) })
	for at, root := range roots {
		root.Turn = at + 1
		if sequence := root.Span.Attrs["interaction.sequence"]; sequence != "" {
			root.Note = "seq " + sequence
		}
	}
	s.Roots = roots
	s.attachPrompts()
}

func sortKids(node *Node) {
	sort.Slice(node.Children, func(a, b int) bool {
		return node.Children[a].Span.Start.Before(node.Children[b].Span.Start)
	})
	sort.Slice(node.Facets, func(a, b int) bool {
		return node.Facets[a].Start.Before(node.Facets[b].Start)
	})
}

// describe assigns the role that picks the row color and the short label that
// stands in for the span name. A span name reads as <subject>.<operation>, so
// the operation carries the meaning and the subject rarely does.
func describe(span otlp.Span) *Node {
	node := &Node{Span: span, Role: RoleSystem, Label: span.Name}

	switch span.Name {
	case "claude_code.interaction":
		node.Role, node.Label = RoleTurn, "turn"
	case "claude_code.llm_request":
		node.Role, node.Label = RoleModel, model(span.Attrs)
		node.Note = produced(span.Attrs)
	case "claude_code.tool":
		node.Label = span.Attrs["tool_name"]
		if node.Label == "" {
			node.Label = "tool"
		}
		node.Role = RoleTool
		if delegateTools[node.Label] {
			node.Role = RoleDelegate
		}
	default:
		parts := strings.Split(span.Name, ".")
		node.Label = parts[len(parts)-1]
		if len(parts) > 1 {
			node.Note = strings.Join(parts[:len(parts)-1], ".")
		}
	}

	if span.Failed {
		node.Role = RoleError
		if span.Error != "" {
			node.Note = span.Error
		}
	}
	return node
}

func model(attrs map[string]string) string {
	name := attrs["gen_ai.request.model"]
	if name == "" {
		name = attrs["model"]
	}
	if name == "" {
		return "model"
	}
	// claude-opus-5-20260101 reads as claude-opus-5 in a 12 column label.
	parts := strings.Split(name, "-")
	if len(parts) > 1 && len(parts[len(parts)-1]) == 8 {
		parts = parts[:len(parts)-1]
	}
	return strings.Join(parts, "-")
}

// produced says what the call did, because no harness exports the reply text
// and a token pair does not answer the reader's question. The stop reason does:
// it separates the call that answered the reader from the call that went off to
// run a tool. ttft is the wait the reader actually felt; duration_ms is already
// its own column.
func produced(attrs map[string]string) string {
	stop := attrs["stop_reason"]
	if stop == "" {
		stop = attrs["gen_ai.response.finish_reasons"]
	}
	parts := []string{}
	switch stop {
	case "tool_use":
		parts = append(parts, "called a tool")
	case "end_turn":
		parts = append(parts, "replied")
	case "max_tokens":
		parts = append(parts, "hit the output cap")
	case "stop_sequence":
		parts = append(parts, "hit a stop sequence")
	case "refusal":
		parts = append(parts, "refused")
	case "":
	default:
		parts = append(parts, stop)
	}
	if ms := count(attrs["ttft_ms"]); ms > 0 {
		parts = append(parts, fmt.Sprintf("first token %s", brief(time.Duration(ms)*time.Millisecond)))
	}
	// An attempt above the first means the call was retried, which shows up
	// nowhere else: the retry and the original share a span name and a model.
	if n := count(attrs["attempt"]); n > 1 {
		parts = append(parts, fmt.Sprintf("attempt %d", n))
	}
	return strings.Join(parts, " \u00b7 ")
}

// brief is the duration format the note uses. The row's own time column has a
// wider one; here the string shares a cell with two other facts.
func brief(d time.Duration) string {
	switch {
	case d >= time.Minute:
		return fmt.Sprintf("%dm%ds", int(d.Minutes()), int(d.Seconds())%60)
	case d >= time.Second:
		return fmt.Sprintf("%.1fs", d.Seconds())
	default:
		return fmt.Sprintf("%dms", d.Milliseconds())
	}
}

// Claude Code reports input_tokens as 2 on a model call and puts the real read
// in the cache counters: one measured call read 914181 cached tokens against an
// input_tokens of 2. Reporting the bare field said the turn read 2 tokens.
func tokens(attrs map[string]string) string {
	in := count(attrs["input_tokens"]) + count(attrs["cache_read_tokens"]) + count(attrs["cache_creation_tokens"])
	out := count(attrs["output_tokens"])
	if in == 0 && out == 0 {
		return ""
	}
	return fmt.Sprintf("%d in / %d out", in, out)
}

func count(text string) int {
	if text == "" {
		return 0
	}
	if n, err := strconv.Atoi(text); err == nil {
		return n
	}
	// A count arrives as a float when the source is Observe, because JSON has
	// one number type.
	if f, err := strconv.ParseFloat(text, 64); err == nil {
		return int(f)
	}
	return 0
}
