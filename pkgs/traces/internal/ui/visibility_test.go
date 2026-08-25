package ui

import (
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
)

// A turn with two children, so folding it has something to hide.
func foldable(t *testing.T) Model {
	t.Helper()
	now := time.Now()
	store := session.NewStore()
	store.Add([]otlp.Span{
		{SpanID: "turn", Name: "agent.turn", Service: "claude-code", Session: "one",
			Start: now, End: now.Add(time.Second),
			Attrs: map[string]string{"traces.view": "activity", "user_prompt": "go"}},
		{SpanID: "a", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: map[string]string{"traces.view": "activity", "tool_name": "Bash"}},
		{SpanID: "b", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: map[string]string{"traces.view": "activity", "tool_name": "Read"}},
	})
	m := New(store, "one", "test")
	mm, _ := m.Update(tea.WindowSizeMsg{Width: 120, Height: 20})
	return mm.(Model)
}

// clamp no longer recomputes the visible list, because that walk measured every
// label on a 35870 row session and ran on every keystroke. Every fold has to
// refresh it itself, and this is the test that says so.
func TestFoldingUpdatesVisibility(t *testing.T) {
	m := foldable(t)
	if got := len(m.visible()); got != 3 {
		t.Fatalf("rows visible = %d, want 3", got)
	}

	// h collapses the row under the cursor. The cursor starts on the last row,
	// so step to the turn first.
	up, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("gg")[:1]})
	m = up.(Model)
	up, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune("g")})
	m = up.(Model)

	for _, key := range []string{"zM", "zR"} {
		want := 1
		if key == "zR" {
			want = 3
		}
		for _, r := range key {
			next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}})
			m = next.(Model)
		}
		if got := len(m.visible()); got != want {
			t.Errorf("after %s rows visible = %d, want %d", key, got, want)
		}
	}
}

// Separate keys keep both panes available without a focus mode.
func TestTraceAndInspectorNavigationUseSeparateKeys(t *testing.T) {
	m := foldable(t)
	m.cursor = 1
	m.pane.Height = 4
	m.pane.SetContent(strings.Repeat("line\n", 40))

	press := func(key tea.KeyMsg) {
		next, _ := m.Update(key)
		m = next.(Model)
	}
	rune_ := func(r rune) tea.KeyMsg {
		return tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}}
	}

	// The trace moves and the inspector holds still.
	press(tea.KeyMsg{Type: tea.KeyDown})
	if m.cursor != 2 || m.pane.YOffset != 0 {
		t.Fatalf("down: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	press(tea.KeyMsg{Type: tea.KeyUp})
	if m.cursor != 1 || m.pane.YOffset != 0 {
		t.Fatalf("up: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}

	// A trace motion refreshes the pane from the row it landed on, so the long
	// content has to be put back before the inspector is driven.
	m.pane.Height = 4
	m.pane.SetContent(strings.Repeat("line\n", 40))

	// The inspector moves and the trace holds still.
	press(rune_('j'))
	if m.cursor != 1 || m.pane.YOffset == 0 {
		t.Fatalf("j: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	down := m.pane.YOffset
	press(rune_('k'))
	if m.cursor != 1 || m.pane.YOffset >= down {
		t.Fatalf("k: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}

	press(tea.KeyMsg{Type: tea.KeyCtrlJ})
	if m.cursor != 1 || m.pane.YOffset <= 1 {
		t.Fatalf("ctrl+j: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	press(tea.KeyMsg{Type: tea.KeyCtrlK})
	if m.cursor != 1 || m.pane.YOffset != 0 {
		t.Fatalf("ctrl+k: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
}

// An empty batch has to be free: the poll fires once per provider every 15
// seconds and rebuilt every session each time.
func TestEmptyBatchChangesNothing(t *testing.T) {
	m := foldable(t)
	rows := len(m.rows)
	next, cmd := m.Update(BatchMsg(otlp.Batch{}))
	out := next.(Model)
	if len(out.rows) != rows || cmd != nil {
		t.Errorf("rows %d -> %d, cmd %v", rows, len(out.rows), cmd)
	}
}

// Tristan read a turn's cost as 1.5m against a model that holds 1m. One request
// had its counts on both the model span and the tool span it asked for, so the
// rollup counted it twice.
func TestRollupCountsARequestOnce(t *testing.T) {
	now := time.Now()
	usage := map[string]string{
		"traces.view": "activity", "request_id": "req_1",
		"cache_read_tokens": "900000", "output_tokens": "100",
	}
	tool := map[string]string{"traces.view": "activity", "tool_name": "Bash"}
	for key, value := range usage {
		tool[key] = value
	}
	store := session.NewStore()
	store.Add([]otlp.Span{
		{SpanID: "turn", Name: "agent.turn", Service: "claude-code", Session: "one",
			Start: now, End: now.Add(time.Second),
			Attrs: map[string]string{"traces.view": "activity", "user_prompt": "go"}},
		{SpanID: "req_1", ParentID: "turn", Name: "agent.model", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: usage},
		{SpanID: "t1", ParentID: "req_1", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: now, End: now, Attrs: tool},
	})
	m := New(store, "one", "test")
	mm, _ := m.Update(tea.WindowSizeMsg{Width: 120, Height: 20})
	v := mm.(Model)

	want := 900100
	for i, r := range v.rows {
		if r.kind == kindTurn || r.kind == kindPrompt {
			if got := v.rollup(i); got != want {
				t.Errorf("%s rollup = %d, want %d", r.label, got, want)
			}
		}
	}
}
