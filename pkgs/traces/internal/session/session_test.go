package session

import (
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
)

func TestActivityProviderReplacesRawRuntimeTree(t *testing.T) {
	now := time.Now()
	store := NewStore()
	store.Add([]otlp.Span{
		{SpanID: "raw", Name: "persist_rollout_items", Service: "codex_cli_rs", Session: "one", Start: now, End: now, Attrs: map[string]string{}},
		{SpanID: "turn", Name: "agent.turn", Service: "codex_cli_rs", Session: "one", Start: now, End: now, Attrs: map[string]string{"traces.view": "activity"}},
		{SpanID: "tool", ParentID: "turn", Name: "agent.tool", Service: "codex_cli_rs", Session: "one", Start: now, End: now, Attrs: map[string]string{"traces.view": "activity", "tool_name": "Shell"}},
	})

	found := store.Session("one")
	if found == nil {
		t.Fatal("session not found")
	}
	if got, want := found.ViewCount(), 2; got != want {
		t.Fatalf("ViewCount() = %d, want %d", got, want)
	}
	if len(found.Roots) != 1 || found.Roots[0].Span.SpanID != "turn" {
		t.Fatalf("roots = %#v", found.Roots)
	}
}

func TestToolNamesShareActionLabels(t *testing.T) {
	tests := []struct {
		name   string
		action string
		want   string
	}{
		{name: "apply_patch", want: "Edit"},
		{name: "Edit", want: "Edit"},
		{name: "Bash", want: "Shell"},
		{name: "web.search", want: "Search"},
		{name: "custom_tool", action: "browse", want: "Browse"},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			node := describe(otlp.Span{
				Name:  "agent.tool",
				Attrs: map[string]string{"tool_name": test.name, "traces.action": test.action},
			})
			if node.Label != test.want {
				t.Errorf("label = %q, want %q", node.Label, test.want)
			}
		})
	}
}

func TestSessionsReturnsStableSnapshots(t *testing.T) {
	now := time.Now()
	store := NewStore()
	store.Add([]otlp.Span{{
		SpanID: "one", Name: "agent.turn", Service: "claude-code", Session: "run",
		Start: now, End: now, Attrs: map[string]string{"traces.view": "activity"},
	}})
	first := store.Sessions()[0]
	store.Add([]otlp.Span{{
		SpanID: "two", ParentID: "one", Name: "agent.tool", Service: "claude-code", Session: "run",
		Start: now, End: now, Attrs: map[string]string{"traces.view": "activity"},
	}})
	second := store.Sessions()[0]
	if first == second || first.Count != 1 || second.Count != 2 {
		t.Fatalf("snapshots share state: same %v, counts %d and %d", first == second, first.Count, second.Count)
	}
}
