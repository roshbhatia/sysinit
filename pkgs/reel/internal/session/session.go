// Package session groups OTLP spans the way an agent run actually reads:
// one session, a numbered turn per prompt, and the model calls and tool calls
// the agent made inside that turn.
package session

import (
	"sort"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
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
// parent id they carry is still a stable turn key, so reel groups on that id and
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

func (s *Session) Short() string {
	title := s.Title()
	if len(title) > 8 {
		return title[:8]
	}
	return title
}

type Store struct {
	sessions map[string]*Session
}

func NewStore() *Store { return &Store{sessions: map[string]*Session{}} }

// key puts every span of one agent run together. opencode emits no session id,
// so its trace id stands in and each trace reads as its own run.
func key(span otlp.Span) string {
	if span.Session != "" {
		return span.Service + "/" + span.Session
	}
	return span.Service + "/trace/" + span.TraceID
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
		out = append(out, one)
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

func tokens(attrs map[string]string) string {
	in, out := attrs["input_tokens"], attrs["output_tokens"]
	if in == "" && out == "" {
		return ""
	}
	if in == "" {
		in = "0"
	}
	if out == "" {
		out = "0"
	}
	return in + " in / " + out + " out"
}
