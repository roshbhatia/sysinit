// Package opencode normalizes exported OpenCode sessions into trace items.
package opencode

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

const (
	Service     = "opencode"
	EventText   = "opencode.assistant"
	EventResult = "opencode.tool_result"
	EventPrompt = "opencode.user_prompt"
)

type databaseSession struct {
	ID string `json:"id"`
}

type sessionExport struct {
	Info     sessionInfo `json:"info"`
	Messages []message   `json:"messages"`
}

type sessionInfo struct {
	ID        string `json:"id"`
	ParentID  string `json:"parentID"`
	Directory string `json:"directory"`
	Agent     string `json:"agent"`
	Model     struct {
		ID         string `json:"id"`
		ProviderID string `json:"providerID"`
	} `json:"model"`
	Time stamp `json:"time"`
}

type stamp struct {
	Created   int64 `json:"created"`
	Updated   int64 `json:"updated"`
	Completed int64 `json:"completed"`
	Start     int64 `json:"start"`
	End       int64 `json:"end"`
}

type tokenCount struct {
	Input     int `json:"input"`
	Output    int `json:"output"`
	Reasoning int `json:"reasoning"`
	Cache     struct {
		Read  int `json:"read"`
		Write int `json:"write"`
	} `json:"cache"`
}

type message struct {
	Info  messageInfo `json:"info"`
	Parts []part      `json:"parts"`
}

type messageInfo struct {
	ID         string     `json:"id"`
	Role       string     `json:"role"`
	Agent      string     `json:"agent"`
	ModelID    string     `json:"modelID"`
	ProviderID string     `json:"providerID"`
	Finish     string     `json:"finish"`
	Cost       float64    `json:"cost"`
	Tokens     tokenCount `json:"tokens"`
	Time       stamp      `json:"time"`
	Path       struct {
		CWD string `json:"cwd"`
	} `json:"path"`
}

type editFile struct {
	FilePath     string `json:"filePath"`
	RelativePath string `json:"relativePath"`
	Patch        string `json:"patch"`
	Additions    int    `json:"additions"`
	Deletions    int    `json:"deletions"`
}

type part struct {
	ID     string `json:"id"`
	Type   string `json:"type"`
	Text   string `json:"text"`
	Tool   string `json:"tool"`
	CallID string `json:"callID"`
	Time   stamp  `json:"time"`
	State  struct {
		Status   string          `json:"status"`
		Input    json.RawMessage `json:"input"`
		Output   string          `json:"output"`
		Error    string          `json:"error"`
		Title    string          `json:"title"`
		Time     stamp           `json:"time"`
		Metadata struct {
			Diff  string     `json:"diff"`
			Files []editFile `json:"files"`
		} `json:"metadata"`
	} `json:"state"`
}

type turn struct {
	id     string
	start  time.Time
	end    time.Time
	prompt string
}

func Read(ctx context.Context, binary string, window time.Duration, selector, directory string) (otlp.Batch, error) {
	ids, err := sessionIDs(ctx, binary, window, selector, directory)
	if err != nil {
		return otlp.Batch{}, err
	}
	out := otlp.Batch{}
	for _, id := range ids {
		blob, err := command(ctx, binary, directory, "export", id, "--pure")
		if err != nil {
			return otlp.Batch{}, err
		}
		one, err := Decode(blob)
		if err != nil {
			return otlp.Batch{}, fmt.Errorf("export %s: %w", id, err)
		}
		out.Spans = append(out.Spans, one.Spans...)
		out.Records = append(out.Records, one.Records...)
	}
	return out, nil
}

func sessionIDs(ctx context.Context, binary string, window time.Duration, selector, directory string) ([]string, error) {
	query := "select id from session where time_updated >= " + strconv.FormatInt(time.Now().Add(-window).UnixMilli(), 10)
	if selector != "" {
		query += " and id like '" + strings.ReplaceAll(selector, "'", "''") + "%'"
	}
	query += " order by time_updated desc"
	blob, err := command(ctx, binary, directory, "db", "--pure", "--format", "json", query)
	if err != nil {
		return nil, err
	}
	var rows []databaseSession
	if err := json.Unmarshal(blob, &rows); err != nil {
		return nil, fmt.Errorf("session list: %w", err)
	}
	ids := make([]string, 0, len(rows))
	for _, row := range rows {
		if row.ID != "" {
			ids = append(ids, row.ID)
		}
	}
	return ids, nil
}

func command(ctx context.Context, binary, directory string, args ...string) ([]byte, error) {
	cmd := exec.CommandContext(ctx, binary, args...)
	if directory != "" {
		cmd.Dir = directory
	}
	stderr := &strings.Builder{}
	cmd.Stderr = stderr
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("opencode %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderr.String()))
	}
	return out, nil
}

func Decode(blob []byte) (otlp.Batch, error) {
	var exported sessionExport
	if err := json.Unmarshal(blob, &exported); err != nil {
		return otlp.Batch{}, err
	}
	if exported.Info.ID == "" {
		return otlp.Batch{}, fmt.Errorf("session has no id")
	}
	sort.SliceStable(exported.Messages, func(a, b int) bool {
		return exported.Messages[a].Info.Time.Created < exported.Messages[b].Info.Time.Created
	})

	batch := otlp.Batch{}
	var current *turn
	flush := func() {
		if current == nil || current.start.IsZero() {
			return
		}
		if current.end.Before(current.start) {
			current.end = current.start
		}
		batch.Spans = append(batch.Spans, otlp.Span{
			TraceID: exported.Info.ID, SpanID: current.id, Name: "agent.turn",
			Service: Service, Session: exported.Info.ID, Start: current.start, End: current.end,
			Attrs: activityAttrs(exported.Info.Directory, exported.Info.Agent),
		})
	}

	for _, one := range exported.Messages {
		at := millis(one.Info.Time.Created)
		switch one.Info.Role {
		case "user":
			flush()
			prompt := textParts(one.Parts)
			current = &turn{id: "turn:" + one.Info.ID, start: at, end: at, prompt: prompt}
			if prompt != "" {
				batch.Records = append(batch.Records, otlp.Record{
					TraceID: exported.Info.ID, SpanID: one.Info.ID, Event: EventPrompt,
					Body: prompt, Service: Service, Session: exported.Info.ID, At: at,
					Attrs: map[string]string{"prompt": prompt, "cwd": exported.Info.Directory},
				})
			}
		case "assistant":
			if current == nil {
				current = &turn{id: "turn:" + one.Info.ID, start: at, end: at}
			}
			addAssistant(&batch, exported.Info, current, one)
			if ended := millis(firstInt(one.Info.Time.Completed, one.Info.Time.Updated)); ended.After(current.end) {
				current.end = ended
			}
		}
	}
	flush()
	return batch, nil
}

func addAssistant(batch *otlp.Batch, info sessionInfo, parent *turn, one message) {
	start := millis(one.Info.Time.Created)
	end := millis(firstInt(one.Info.Time.Completed, one.Info.Time.Updated))
	if end.Before(start) {
		end = start
	}
	attrs := activityAttrs(first(one.Info.Path.CWD, info.Directory), first(one.Info.Agent, info.Agent))
	attrs["request_id"] = one.Info.ID
	attrs["model"] = first(one.Info.ModelID, info.Model.ID)
	attrs["gen_ai.provider.name"] = first(one.Info.ProviderID, info.Model.ProviderID)
	attrs["input_tokens"] = strconv.Itoa(one.Info.Tokens.Input)
	attrs["output_tokens"] = strconv.Itoa(one.Info.Tokens.Output)
	attrs["reasoning_tokens"] = strconv.Itoa(one.Info.Tokens.Reasoning)
	attrs["cache_read_tokens"] = strconv.Itoa(one.Info.Tokens.Cache.Read)
	attrs["cache_creation_tokens"] = strconv.Itoa(one.Info.Tokens.Cache.Write)
	attrs["cost_usd"] = strconv.FormatFloat(one.Info.Cost, 'f', -1, 64)
	attrs["stop_reason"] = finish(one.Info.Finish)
	batch.Spans = append(batch.Spans, otlp.Span{
		TraceID: info.ID, SpanID: one.Info.ID, ParentID: parent.id, Name: "agent.model",
		Service: Service, Session: info.ID, Start: start, End: end, Attrs: attrs,
	})

	text, thinking := "", ""
	for _, item := range one.Parts {
		switch item.Type {
		case "text":
			text = joinText(text, item.Text)
		case "reasoning":
			thinking = joinText(thinking, item.Text)
		case "tool":
			addTool(batch, info, parent, one.Info, item)
		}
	}
	if text != "" || thinking != "" {
		batch.Records = append(batch.Records, otlp.Record{
			TraceID: info.ID, SpanID: one.Info.ID, Event: EventText, Body: text,
			Service: Service, Session: info.ID, At: end,
			Attrs: map[string]string{"request_id": one.Info.ID, "thinking": thinking},
		})
	}
}

func addTool(batch *otlp.Batch, info sessionInfo, parent *turn, message messageInfo, item part) {
	id := first(item.ID, item.CallID)
	if id == "" {
		return
	}
	start := millis(firstInt(item.State.Time.Start, item.Time.Start, item.Time.Created))
	end := millis(firstInt(item.State.Time.End, item.Time.End, item.Time.Updated))
	if start.IsZero() {
		start = millis(message.Time.Created)
	}
	if end.Before(start) {
		end = start
	}
	cwd := first(message.Path.CWD, info.Directory)
	attrs := activityAttrs(cwd, first(message.Agent, info.Agent))
	attrs["tool_name"] = first(item.Tool, "tool")
	attrs["tool_use_id"] = id
	attrs["tool_input"] = toolInput(item, cwd)
	name := "agent.tool"
	if editAction(item.Tool) {
		name = "agent.edit"
		attrs["traces.action"] = "edit"
		patch, files, added, removed := editPatch(item.State.Metadata.Files, item.State.Metadata.Diff, cwd)
		attrs["traces.patch"] = patch
		attrs["files_changed"] = strconv.Itoa(files)
		attrs["lines_added"] = strconv.Itoa(added)
		attrs["lines_removed"] = strconv.Itoa(removed)
	}
	failed := item.State.Status == "error" || item.State.Status == "failed" || item.State.Error != ""
	span := otlp.Span{
		TraceID: info.ID, SpanID: id, ParentID: message.ID, Name: name,
		Service: Service, Session: info.ID, Start: start, End: end, Attrs: attrs,
		Failed: failed, Error: item.State.Error,
	}
	batch.Spans = append(batch.Spans, span)
	resultAttrs := map[string]string{"tool_use_id": id}
	if failed {
		resultAttrs["is_error"] = "true"
	}
	batch.Records = append(batch.Records, otlp.Record{
		TraceID: info.ID, SpanID: id, Event: EventResult,
		Body:    first(item.State.Output, item.State.Error, item.State.Title),
		Service: Service, Session: info.ID, At: end, Attrs: resultAttrs,
	})
	if end.After(parent.end) {
		parent.end = end
	}
}

func activityAttrs(cwd, agent string) map[string]string {
	return map[string]string{
		"traces.view": "activity", "traces.source": "opencode-export",
		"cwd": cwd, "agent.name": agent,
	}
}

func editAction(tool string) bool {
	switch strings.ToLower(tool) {
	case "apply_patch", "edit", "write":
		return true
	}
	return false
}

func editPatch(files []editFile, fallback, cwd string) (string, int, int, int) {
	if len(files) == 0 {
		added, removed := churn(fallback)
		return fallback, boolInt(fallback != ""), added, removed
	}
	parts, added, removed := make([]string, 0, len(files)), 0, 0
	for _, file := range files {
		path := first(file.RelativePath, relative(cwd, file.FilePath), file.FilePath)
		body := file.Patch
		if at := strings.Index(body, "@@"); at >= 0 {
			body = body[at:]
		}
		parts = append(parts, "--- "+path+"\n+++ "+path+"\n"+body)
		added += file.Additions
		removed += file.Deletions
	}
	return strings.Join(parts, "\n"), len(files), added, removed
}

func toolInput(item part, cwd string) string {
	if len(item.State.Metadata.Files) > 0 {
		paths := make([]string, 0, len(item.State.Metadata.Files))
		for _, file := range item.State.Metadata.Files {
			paths = append(paths, first(file.RelativePath, relative(cwd, file.FilePath), file.FilePath))
		}
		return strings.Join(paths, "\n")
	}
	var values map[string]json.RawMessage
	if json.Unmarshal(item.State.Input, &values) == nil {
		for _, key := range []string{"command", "path", "filePath", "query", "pattern", "description"} {
			var text string
			if json.Unmarshal(values[key], &text) == nil && text != "" {
				return text
			}
		}
	}
	return compact(item.State.Input)
}

func textParts(parts []part) string {
	out := ""
	for _, item := range parts {
		if item.Type == "text" {
			out = joinText(out, item.Text)
		}
	}
	return out
}

func finish(value string) string {
	switch value {
	case "tool-calls":
		return "tool_use"
	case "stop":
		return "end_turn"
	}
	return value
}

func churn(patch string) (int, int) {
	added, removed := 0, 0
	for _, line := range strings.Split(patch, "\n") {
		switch {
		case strings.HasPrefix(line, "+") && !strings.HasPrefix(line, "+++"):
			added++
		case strings.HasPrefix(line, "-") && !strings.HasPrefix(line, "---"):
			removed++
		}
	}
	return added, removed
}

func relative(cwd, path string) string {
	if cwd == "" || path == "" {
		return ""
	}
	rel, err := filepath.Rel(cwd, path)
	if err != nil || rel == ".." || strings.HasPrefix(rel, ".."+string(filepath.Separator)) {
		return ""
	}
	return rel
}

func compact(raw json.RawMessage) string {
	if len(raw) == 0 || bytes.Equal(raw, []byte("null")) {
		return ""
	}
	var out bytes.Buffer
	if json.Compact(&out, raw) != nil {
		return string(raw)
	}
	return out.String()
}

func millis(value int64) time.Time {
	if value == 0 {
		return time.Time{}
	}
	return time.UnixMilli(value)
}

func first(parts ...string) string {
	for _, value := range parts {
		if value != "" {
			return value
		}
	}
	return ""
}

func firstInt(values ...int64) int64 {
	for _, value := range values {
		if value != 0 {
			return value
		}
	}
	return 0
}

func joinText(before, after string) string {
	if before == "" {
		return after
	}
	if after == "" {
		return before
	}
	return before + "\n" + after
}

func boolInt(value bool) int {
	if value {
		return 1
	}
	return 0
}
