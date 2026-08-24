// Package session groups OTLP spans the way an agent run actually reads:
// one session, a numbered turn per prompt, and the model calls and tool calls
// the agent made inside that turn.
package session

import (
	"fmt"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
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
	Prompt   string
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
	sessions map[string]*Session
	scope    map[string]bool
}

func NewStore() *Store { return &Store{sessions: map[string]*Session{}} }

// Scope narrows the store to a set of session ids, which is how traces opens on
// the runs that belong to the reader's working directory rather than on
// whichever run happens to be newest across the machine. An empty set is no
// scope at all.
func (s *Store) Scope(ids []string) {
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
func (s *Store) Scoped() bool { return len(s.scope) > 0 }

func (s *Store) inScope(one *Session) bool {
	if len(s.scope) == 0 {
		return true
	}
	return s.scope[one.ID]
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
		dirty:   true,
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
	if other.First.Before(s.First) {
		s.First = other.First
	}
	if other.Last.After(s.Last) {
		s.Last = other.Last
	}
	s.dirty = true
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
			}
			s.sessions[id] = found
		}
		if _, seen := found.spans[span.SpanID]; !seen {
			found.Count++
		}
		found.spans[span.SpanID] = span
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

func (s *Store) Session(id string) *Session {
	for _, one := range s.sessions {
		if one.ID == id || one.Key == id || strings.HasPrefix(one.ID, id) {
			one.rebuild()
			return one
		}
	}
	return nil
}

// AddRecords keeps the log records a row can carry. Only the prompt is kept:
// every other event this harness logs is already a span, and a second copy of
// it would double every row.
func (s *Store) AddRecords(records []otlp.Record) {
	for _, one := range records {
		if !strings.HasSuffix(one.Event, "user_prompt") {
			continue
		}
		text := one.Attrs["prompt"]
		if text == "" {
			continue
		}
		id := recordKey(one)
		found, ok := s.sessions[id]
		if !ok {
			// The prompt reaches the collector before the turn span closes, so
			// a session can be prompt first. Holding it costs one string and
			// saves the first turn from reading as untitled.
			found = &Session{Key: id, Service: one.Service, ID: one.Session, First: one.At, spans: map[string]otlp.Span{}}
			s.sessions[id] = found
		}
		found.prompts = append(found.prompts, one)
		found.dirty = true
	}
}

// recordKey matches key(), so a log record and a span of the same run land in
// the same session.
func recordKey(one otlp.Record) string {
	if one.Session != "" {
		return one.Service + "/" + one.Session
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
		node.Note = tokens(span.Attrs)
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
