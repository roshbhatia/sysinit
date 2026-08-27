// Package rollout normalizes the Codex activity stream into trace items.
package rollout

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io/fs"
	"net/url"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

const (
	Service     = "codex_cli_rs"
	EventText   = "codex.assistant"
	EventResult = "codex.tool_result"
	EventPrompt = "codex.user_prompt"
)

func Root() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".codex", "sessions")
}

// Read filters rollout files before parsing so attached views avoid old sessions.
func Read(root string, window time.Duration, session string) otlp.Batch {
	out := otlp.Batch{}
	if root == "" {
		return out
	}
	since := time.Now().Add(-window)
	_ = filepath.WalkDir(root, func(path string, entry fs.DirEntry, err error) error {
		if err != nil || entry.IsDir() || !strings.HasSuffix(entry.Name(), ".jsonl") {
			return nil
		}
		if session != "" && !fileMatchesSession(path, session) {
			return nil
		}
		info, err := entry.Info()
		if err != nil || info.ModTime().Before(since) {
			return nil
		}
		one := ReadFile(path)
		out.Spans = append(out.Spans, one.Spans...)
		out.Records = append(out.Records, one.Records...)
		return nil
	})
	return out
}

func fileMatchesSession(path, session string) bool {
	if strings.Contains(filepath.Base(path), session) {
		return true
	}
	f, err := os.Open(path)
	if err != nil {
		return false
	}
	defer func() { _ = f.Close() }()

	scan := bufio.NewScanner(f)
	scan.Buffer(make([]byte, 0, 64<<10), maxLine)
	for scan.Scan() {
		var row envelope
		if json.Unmarshal(scan.Bytes(), &row) != nil {
			continue
		}
		if row.Type != "session_meta" {
			return false
		}
		var one meta
		if json.Unmarshal(row.Payload, &one) == nil &&
			(strings.Contains(one.SessionID, session) || strings.Contains(one.ID, session)) {
			return true
		}
	}
	return false
}

type envelope struct {
	Type      string          `json:"type"`
	Timestamp string          `json:"timestamp"`
	Payload   json.RawMessage `json:"payload"`
}

type meta struct {
	ID           string `json:"id"`
	SessionID    string `json:"session_id"`
	CWD          string `json:"cwd"`
	ThreadSource string `json:"thread_source"`
	AgentPath    string `json:"agent_path"`
}

type turnContext struct {
	TurnID string `json:"turn_id"`
	CWD    string `json:"cwd"`
	Model  string `json:"model"`
}

type event struct {
	Type              string          `json:"type"`
	ThreadID          string          `json:"thread_id"`
	TurnID            string          `json:"turn_id"`
	TraceID           string          `json:"trace_id"`
	StartedAt         int64           `json:"started_at"`
	CompletedAt       int64           `json:"completed_at"`
	StartedAtMillis   int64           `json:"started_at_ms"`
	CompletedAtMillis int64           `json:"completed_at_ms"`
	Collaboration     string          `json:"collaboration_mode_kind"`
	Item              json.RawMessage `json:"item"`
}

type change struct {
	Type        string  `json:"type"`
	UnifiedDiff string  `json:"unified_diff"`
	MovePath    *string `json:"move_path"`
}

type item struct {
	Type             string            `json:"type"`
	ID               string            `json:"id"`
	Phase            string            `json:"phase"`
	Kind             string            `json:"kind"`
	Query            string            `json:"query"`
	Status           string            `json:"status"`
	CWD              string            `json:"cwd"`
	Stdout           string            `json:"stdout"`
	Stderr           string            `json:"stderr"`
	AggregatedOutput string            `json:"aggregated_output"`
	FormattedOutput  string            `json:"formatted_output"`
	ExitCode         *int              `json:"exit_code"`
	Command          []string          `json:"command"`
	Content          json.RawMessage   `json:"content"`
	SummaryText      json.RawMessage   `json:"summary_text"`
	RawContent       json.RawMessage   `json:"raw_content"`
	Action           json.RawMessage   `json:"action"`
	Results          json.RawMessage   `json:"results"`
	Changes          map[string]change `json:"changes"`
	AgentThreadID    string            `json:"agent_thread_id"`
	AgentPath        string            `json:"agent_path"`
}

type turn struct {
	id            string
	trace         string
	cwd           string
	model         string
	collaboration string
	agentPath     string
	start         time.Time
	end           time.Time
}

// Codex stores large tool results on one line, so the scanner needs a 32 MiB limit.
const maxLine = 32 << 20

func ReadFile(path string) otlp.Batch {
	f, err := os.Open(path)
	if err != nil {
		return otlp.Batch{}
	}
	defer func() { _ = f.Close() }()

	batch := otlp.Batch{}
	sessionID, sessionCWD := "", ""
	subagentThreadID, subagentPath := "", ""
	turns := map[string]*turn{}
	order := []string{}

	ensureTurn := func(id string) *turn {
		if id == "" {
			return nil
		}
		if found := turns[id]; found != nil {
			return found
		}
		found := &turn{id: id}
		turns[id] = found
		order = append(order, id)
		return found
	}

	scan := bufio.NewScanner(f)
	scan.Buffer(make([]byte, 0, 64<<10), maxLine)
	for scan.Scan() {
		var row envelope
		if json.Unmarshal(scan.Bytes(), &row) != nil {
			continue
		}
		switch row.Type {
		case "session_meta":
			var one meta
			if json.Unmarshal(row.Payload, &one) == nil {
				sessionID = first(one.SessionID, one.ID)
				sessionCWD = cleanCWD(one.CWD)
				if one.ThreadSource == "subagent" && one.AgentPath != "" {
					subagentThreadID, subagentPath = one.ID, one.AgentPath
				}
			}
		case "turn_context":
			var one turnContext
			if json.Unmarshal(row.Payload, &one) == nil {
				found := ensureTurn(one.TurnID)
				if found != nil {
					found.cwd, found.model = cleanCWD(one.CWD), one.Model
				}
			}
		case "event_msg":
			var one event
			if json.Unmarshal(row.Payload, &one) != nil {
				continue
			}
			if one.ThreadID != "" && sessionID == "" {
				sessionID = one.ThreadID
			}
			found := ensureTurn(one.TurnID)
			if found != nil && one.ThreadID == subagentThreadID {
				found.agentPath = subagentPath
			}
			switch one.Type {
			case "task_started":
				if found == nil {
					continue
				}
				found.trace = one.TraceID
				found.collaboration = one.Collaboration
				if one.StartedAt != 0 {
					found.start = time.Unix(one.StartedAt, 0)
				}
			case "task_complete":
				if found == nil {
					continue
				}
				if found.start.IsZero() && one.StartedAt != 0 {
					found.start = time.Unix(one.StartedAt, 0)
				}
				if one.CompletedAt != 0 {
					found.end = time.Unix(one.CompletedAt, 0)
				}
			case "item_completed":
				if found == nil {
					continue
				}
				start := stamp(row.Timestamp)
				if one.StartedAtMillis != 0 {
					start = time.UnixMilli(one.StartedAtMillis)
				}
				end := start
				if one.CompletedAtMillis != 0 {
					end = time.UnixMilli(one.CompletedAtMillis)
					if end.Before(start) {
						end = start
					}
				}
				if found.start.IsZero() || start.Before(found.start) {
					found.start = start
				}
				if end.After(found.end) {
					found.end = end
				}
				if found.cwd == "" {
					found.cwd = sessionCWD
				}
				addItem(&batch, sessionID, found, start, end, one.Item)
			}
		}
	}

	sort.Slice(order, func(a, b int) bool {
		return turns[order[a]].start.Before(turns[order[b]].start)
	})
	for index, id := range order {
		one := turns[id]
		if one.start.IsZero() {
			continue
		}
		if one.end.IsZero() || one.end.Before(one.start) {
			one.end = one.start
		}
		attrs := activityAttrs(one.cwd, one.agentPath)
		attrs["interaction.sequence"] = strconv.Itoa(index + 1)
		attrs["model"] = one.model
		attrs["collaboration.mode"] = one.collaboration
		batch.Spans = append(batch.Spans, otlp.Span{
			TraceID: one.trace, SpanID: one.id, Name: "agent.turn",
			Service: Service, Session: sessionID, Start: one.start, End: one.end, Attrs: attrs,
		})
	}
	return batch
}

func addItem(batch *otlp.Batch, sessionID string, parent *turn, start, end time.Time, raw json.RawMessage) {
	var one item
	if json.Unmarshal(raw, &one) != nil || one.ID == "" {
		return
	}
	attrs := activityAttrs(first(cleanCWD(one.CWD), parent.cwd), parent.agentPath)
	attrs["model"] = parent.model
	span := otlp.Span{
		TraceID: parent.trace, SpanID: one.ID, ParentID: parent.id,
		Service: Service, Session: sessionID, Start: start, End: end, Attrs: attrs,
	}

	switch one.Type {
	case "UserMessage":
		if prompt := flatten(one.Content); prompt != "" {
			batch.Records = append(batch.Records, record(EventPrompt, sessionID, parent, start, prompt, map[string]string{"prompt": prompt, "cwd": attrs["cwd"]}))
		}
		return
	case "AgentMessage":
		text := flatten(one.Content)
		if text == "" {
			return
		}
		span.Name = "agent.model"
		span.Attrs["request_id"] = one.ID
		span.Attrs["phase"] = one.Phase
		if one.Phase == "final" {
			span.Attrs["stop_reason"] = "end_turn"
		}
		batch.Records = append(batch.Records, record(EventText, sessionID, parent, end, text, map[string]string{"request_id": one.ID}))
	case "Reasoning":
		thinking := first(flatten(one.SummaryText), flatten(one.RawContent))
		if thinking == "" {
			return
		}
		span.Name = "agent.model"
		span.Attrs["request_id"] = one.ID
		span.Attrs["thinking"] = thinking
		batch.Records = append(batch.Records, record(EventText, sessionID, parent, end, "", map[string]string{"request_id": one.ID, "thinking": thinking}))
	case "CommandExecution":
		span.Name = "agent.tool"
		span.Attrs["tool_name"] = "Shell"
		span.Attrs["traces.action"] = "shell"
		span.Attrs["tool_use_id"] = one.ID
		span.Attrs["full_command"] = command(one.Command)
		if one.ExitCode != nil {
			span.Attrs["exit_code"] = strconv.Itoa(*one.ExitCode)
			span.Failed = *one.ExitCode != 0
		}
		output := first(strings.TrimSpace(one.Stdout+join(one.Stdout, one.Stderr)+one.Stderr), one.AggregatedOutput, one.FormattedOutput)
		batch.Records = append(batch.Records, result(sessionID, parent, end, one.ID, output, span.Failed))
	case "FileChange":
		span.Name = "agent.edit"
		span.Attrs["tool_name"] = "apply_patch"
		span.Attrs["traces.action"] = "edit"
		span.Attrs["tool_use_id"] = one.ID
		paths, added, removed, patch := changes(one.Changes, parent.cwd)
		span.Attrs["tool_input"] = strings.Join(paths, "\n")
		span.Attrs["files_changed"] = strconv.Itoa(len(paths))
		span.Attrs["lines_added"] = strconv.Itoa(added)
		span.Attrs["lines_removed"] = strconv.Itoa(removed)
		span.Attrs["traces.patch"] = patch
		output := first(one.Stdout, one.Stderr)
		span.Failed = one.Status == "failed" || one.Stderr != ""
		batch.Records = append(batch.Records, result(sessionID, parent, end, one.ID, output, span.Failed))
	case "Extension":
		span.Name = "agent.tool"
		span.Attrs["tool_name"] = first(one.Kind, "extension")
		span.Attrs["traces.action"] = actionOf(one.Kind)
		span.Attrs["tool_use_id"] = one.ID
		span.Attrs["tool_input"] = first(one.Query, compact(one.Action))
		batch.Records = append(batch.Records, result(sessionID, parent, end, one.ID, compact(one.Results), false))
	case "ContextCompaction":
		span.Name = "agent.compact"
	case "SubAgentActivity":
		span.Name = "agent.tool"
		span.Attrs["tool_name"] = "Agent"
		span.Attrs["traces.action"] = "delegate"
		span.Attrs["tool_use_id"] = one.ID
		span.Attrs["subagent_type"] = agentLane(one.AgentPath)
		span.Attrs["agent.thread_id"] = one.AgentThreadID
		span.Attrs["subagent.status"] = one.Kind
		span.Attrs["tool_input"] = one.AgentPath
	default:
		span.Name = "agent.event"
		span.Attrs["tool_name"] = one.Type
		span.Attrs["tool_input"] = compact(raw)
	}
	batch.Spans = append(batch.Spans, span)
}

func activityAttrs(cwd, agentPath string) map[string]string {
	out := map[string]string{"traces.view": "activity", "traces.source": "codex-rollout", "cwd": cwd}
	if lane := agentLane(agentPath); lane != "" {
		out["agent.path"] = lane
	}
	return out
}

func agentLane(path string) string {
	path = strings.Trim(path, "/")
	if path == "root" {
		return "main"
	}
	if strings.HasPrefix(path, "root/") {
		return "main/" + strings.TrimPrefix(path, "root/")
	}
	return path
}

func actionOf(name string) string {
	switch strings.ToLower(name) {
	case "web.search":
		return "search"
	case "web.open", "web.find", "web.click":
		return "browse"
	case "image.generation":
		return "image"
	default:
		return "extension"
	}
}

func record(event, sessionID string, parent *turn, at time.Time, body string, attrs map[string]string) otlp.Record {
	return otlp.Record{
		TraceID: parent.trace, SpanID: first(attrs["request_id"], attrs["tool_use_id"]),
		Event: event, Body: body, Service: Service, Session: sessionID, At: at, Attrs: attrs,
	}
}

func result(sessionID string, parent *turn, at time.Time, id, body string, failed bool) otlp.Record {
	attrs := map[string]string{"tool_use_id": id}
	if failed {
		attrs["is_error"] = "true"
	}
	return record(EventResult, sessionID, parent, at, body, attrs)
}

func command(parts []string) string {
	if len(parts) >= 3 && (parts[len(parts)-2] == "-lc" || parts[len(parts)-2] == "-c") {
		return parts[len(parts)-1]
	}
	return strings.Join(parts, " ")
}

func changes(in map[string]change, cwd string) ([]string, int, int, string) {
	paths := make([]string, 0, len(in))
	for path := range in {
		paths = append(paths, path)
	}
	sort.Strings(paths)
	added, removed := 0, 0
	parts := make([]string, 0, len(paths))
	for _, path := range paths {
		one := in[path]
		for _, line := range strings.Split(one.UnifiedDiff, "\n") {
			switch {
			case strings.HasPrefix(line, "+") && !strings.HasPrefix(line, "+++"):
				added++
			case strings.HasPrefix(line, "-") && !strings.HasPrefix(line, "---"):
				removed++
			}
		}
		oldPath, newPath := relative(cwd, path), relative(cwd, path)
		switch one.Type {
		case "add", "create":
			oldPath = "/dev/null"
		case "delete":
			newPath = "/dev/null"
		}
		if one.MovePath != nil && *one.MovePath != "" {
			newPath = relative(cwd, *one.MovePath)
		}
		body := one.UnifiedDiff
		if !strings.Contains(body, "\n+++ ") {
			body = fmt.Sprintf("--- %s\n+++ %s\n%s", oldPath, newPath, body)
		}
		parts = append(parts, body)
	}
	return paths, added, removed, strings.Join(parts, "\n")
}

func relative(cwd, path string) string {
	if rel, err := filepath.Rel(cwd, path); err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return rel
	}
	return path
}

func flatten(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var text string
	if json.Unmarshal(raw, &text) == nil {
		return text
	}
	var blocks []struct {
		Text string `json:"text"`
	}
	if json.Unmarshal(raw, &blocks) != nil {
		return ""
	}
	parts := []string{}
	for _, one := range blocks {
		if one.Text != "" {
			parts = append(parts, one.Text)
		}
	}
	return strings.Join(parts, "\n")
}

func cleanCWD(text string) string {
	if !strings.HasPrefix(text, "file:") {
		return text
	}
	parsed, err := url.Parse(text)
	if err != nil {
		return text
	}
	return parsed.Path
}

func compact(raw json.RawMessage) string {
	if len(raw) == 0 || string(raw) == "null" {
		return ""
	}
	var out bytes.Buffer
	if json.Compact(&out, raw) != nil {
		return string(raw)
	}
	return out.String()
}

func stamp(text string) time.Time {
	at, _ := time.Parse(time.RFC3339Nano, text)
	return at
}

func first(parts ...string) string {
	for _, one := range parts {
		if one != "" {
			return one
		}
	}
	return ""
}

func join(a, b string) string {
	if a != "" && b != "" {
		return "\n"
	}
	return ""
}
