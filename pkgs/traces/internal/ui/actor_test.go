package ui

import (
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
)

func activity(extra map[string]string) map[string]string {
	out := map[string]string{"traces.view": "activity"}
	for k, v := range extra {
		out[k] = v
	}
	return out
}

// @ is the person and + is an agent. A subagent extends its caller's lane; a
// teammate replaces it, because a teammate is a named agent rather than
// something spawned from inside another lane.
func TestActorLanes(t *testing.T) {
	now := time.Now()
	store := session.NewStore()
	store.Add([]otlp.Span{
		{SpanID: "turn", Name: "agent.turn", Service: "claude-code", Session: "one",
			Start: now, End: now.Add(time.Minute),
			Attrs: activity(map[string]string{"user_prompt": "go"})},
		{SpanID: "bash", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: activity(map[string]string{"tool_name": "Bash"})},
		// A subagent the main thread spawned.
		{SpanID: "task", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now,
			Attrs: activity(map[string]string{"tool_name": "Agent", "subagent_type": "Explore"})},
		{SpanID: "inner", ParentID: "task", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: activity(map[string]string{"tool_name": "Grep"})},
		// A teammate, which names itself.
		{SpanID: "mate", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now,
			Attrs: activity(map[string]string{"tool_name": "Agent", "agent.name": "reviewer"})},
		{SpanID: "mateWork", ParentID: "mate", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: activity(map[string]string{"tool_name": "Read"})},
		// A subagent of that teammate.
		{SpanID: "mateSub", ParentID: "mate", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now,
			Attrs: activity(map[string]string{"tool_name": "Agent", "subagent_type": "oracle"})},
		{SpanID: "deep", ParentID: "mateSub", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: activity(map[string]string{"tool_name": "Bash"})},
	})
	m := New(store, "one", "test")
	mm, _ := m.Update(tea.WindowSizeMsg{Width: 140, Height: 30})
	v := mm.(Model)

	got := map[string]string{}
	for _, r := range v.rows {
		if r.node != nil {
			got[r.node.Span.SpanID] = r.actor
		}
	}
	for _, one := range []struct{ span, want string }{
		{"turn", "@user"},
		{"bash", "+main"},
		// The call is made from the lane above it, so the Agent row is +main.
		{"task", "+main"},
		{"inner", "+main/Explore"},
		{"mate", "+main"},
		{"mateWork", "+reviewer"},
		{"mateSub", "+reviewer"},
		{"deep", "+reviewer/oracle"},
	} {
		if got[one.span] != one.want {
			t.Errorf("%s actor = %q, want %q", one.span, got[one.span], one.want)
		}
	}
}

func TestActorUsesRolloutAgentPath(t *testing.T) {
	now := time.Now()
	store := session.NewStore()
	store.Add([]otlp.Span{
		{SpanID: "turn", Name: "agent.turn", Service: "codex_cli_rs", Session: "one",
			Start: now, End: now.Add(time.Minute),
			Attrs: activity(map[string]string{"agent.path": "main/reviewer"})},
		{SpanID: "shell", ParentID: "turn", Name: "agent.tool", Service: "codex_cli_rs", Session: "one",
			Start: now, End: now,
			Attrs: activity(map[string]string{"tool_name": "Shell", "agent.path": "main/reviewer"})},
	})
	m := New(store, "one", "test")
	mm, _ := m.Update(tea.WindowSizeMsg{Width: 140, Height: 30})
	v := mm.(Model)

	for _, r := range v.rows {
		if r.node != nil && r.actor != "+main/reviewer" {
			t.Errorf("%s actor = %q, want +main/reviewer", r.node.Span.SpanID, r.actor)
		}
	}
}
