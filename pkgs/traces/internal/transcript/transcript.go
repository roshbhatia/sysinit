// Package transcript reads what Claude Code writes to disk, which is the half
// of a run its OTLP export leaves out.
//
// A span says a model call happened, how long it took and what it cost. It does
// not say what the model wrote, and no attribute on claude_code.llm_request
// carries it: 346 spans were checked for one. The transcript under
// ~/.claude/projects does carry it, along with every tool's real output, and it
// carries the two ids that join it back to the spans: requestId matches a model
// span's request_id, and a tool_result's tool_use_id matches a tool span's.
//
// The reader emits log records rather than spans, because the transcript adds
// text to a run the collector already described. A record with no span to land
// on is dropped, so reading a session traces never saw costs nothing.
package transcript

import (
	"bufio"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

// The two events this package emits. session.AddRecords matches on them.
const (
	EventText   = "transcript.assistant"
	EventResult = "transcript.tool_result"
)

// Service names the records so they key into the same session the spans did.
// Claude Code's own service.name is claude-code, and a record that named itself
// anything else would open a second session beside the real one.
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

// Read walks every transcript touched inside the window and returns the records
// its entries carry. A file is opened only when its own mtime is inside the
// window, because a project directory holds every session ever run and the
// current one is a few of them.
func Read(root string, window time.Duration) []otlp.Record {
	if root == "" {
		return nil
	}
	since := time.Now().Add(-window)
	out := []otlp.Record{}
	dirs, err := os.ReadDir(root)
	if err != nil {
		return nil
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
			info, err := f.Info()
			if err != nil || info.ModTime().Before(since) {
				continue
			}
			out = append(out, ReadFile(filepath.Join(root, dir.Name(), f.Name()))...)
		}
	}
	return out
}

// entry is the subset of a transcript line this package reads. Claude Code
// writes a dozen record types and adds more between versions, so an unknown
// type decodes to a zero entry and is skipped rather than failing the file.
type entry struct {
	Type      string `json:"type"`
	SessionID string `json:"sessionId"`
	RequestID string `json:"requestId"`
	Timestamp string `json:"timestamp"`
	Message   struct {
		Content json.RawMessage `json:"content"`
	} `json:"message"`
}

type block struct {
	Type      string          `json:"type"`
	Text      string          `json:"text"`
	Thinking  string          `json:"thinking"`
	ToolUseID string          `json:"tool_use_id"`
	Content   json.RawMessage `json:"content"`
	IsError   bool            `json:"is_error"`
}

// A transcript line can reach a megabyte, because a tool result is stored whole.
// bufio.Scanner's default 64k limit silently ended the file at the first one.
const maxLine = 8 << 20

func ReadFile(path string) []otlp.Record {
	f, err := os.Open(path)
	if err != nil {
		return nil
	}
	defer f.Close()

	out := []otlp.Record{}
	scan := bufio.NewScanner(f)
	scan.Buffer(make([]byte, 0, 64<<10), maxLine)
	for scan.Scan() {
		var e entry
		if err := json.Unmarshal(scan.Bytes(), &e); err != nil {
			continue
		}
		if e.Type != "assistant" && e.Type != "user" {
			continue
		}
		var blocks []block
		if json.Unmarshal(e.Message.Content, &blocks) != nil {
			continue
		}
		at, _ := time.Parse(time.RFC3339Nano, e.Timestamp)
		out = append(out, e.records(blocks, at)...)
	}
	return out
}

func (e entry) records(blocks []block, at time.Time) []otlp.Record {
	out := []otlp.Record{}
	text, thinking := []string{}, []string{}
	for _, b := range blocks {
		switch b.Type {
		case "text":
			text = append(text, b.Text)
		case "thinking":
			thinking = append(thinking, b.Thinking)
		case "tool_result":
			if b.ToolUseID == "" {
				continue
			}
			out = append(out, otlp.Record{
				Event:   EventResult,
				Service: Service,
				Session: e.SessionID,
				At:      at,
				Body:    flatten(b.Content),
				Attrs: map[string]string{
					"tool_use_id": b.ToolUseID,
					"is_error":    boolText(b.IsError),
				},
			})
		}
	}
	// The join key is the request, so an assistant entry with no requestId has
	// no span to reach and is dropped here rather than carried and dropped later.
	if e.RequestID == "" || (len(text) == 0 && len(thinking) == 0) {
		return out
	}
	return append(out, otlp.Record{
		Event:   EventText,
		Service: Service,
		Session: e.SessionID,
		At:      at,
		Body:    strings.Join(text, "\n\n"),
		Attrs: map[string]string{
			"request_id": e.RequestID,
			"thinking":   strings.Join(thinking, "\n\n"),
		},
	})
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
	if json.Unmarshal(raw, &blocks) != nil {
		return ""
	}
	parts := []string{}
	for _, b := range blocks {
		if b.Text != "" {
			parts = append(parts, b.Text)
		}
	}
	return strings.Join(parts, "\n")
}

func boolText(b bool) string {
	if b {
		return "true"
	}
	return ""
}
