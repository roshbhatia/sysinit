package ui

import (
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/charmbracelet/bubbles/viewport"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/x/ansi"

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

func TestViewWaitsForTerminalSize(t *testing.T) {
	m := foldable(t)
	m.width, m.height = 0, 0
	if got := m.View(); got != "" {
		t.Fatalf("view before WindowSizeMsg = %q, want empty", got)
	}
}

func applyBatch(t *testing.T, m Model, batch otlp.Batch) Model {
	t.Helper()
	next, cmd := m.Update(BatchMsg(batch))
	if cmd == nil {
		t.Fatal("non-empty batch returned no rebuild command")
	}
	next, follow := next.(Model).Update(cmd())
	if follow != nil {
		t.Fatal("single batch scheduled an unexpected follow-up command")
	}
	return next.(Model)
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
// One set of motions, aimed by the focus. ctrl+j and ctrl+k move the focus, and
// the frame draws the focused pane's border in the accent so no key depends on
// state the reader cannot see.
func TestFocusAimsTheMotions(t *testing.T) {
	m := foldable(t)
	m.cursor = 1

	press := func(key tea.KeyMsg) {
		next, _ := m.Update(key)
		m = next.(Model)
	}
	letter := func(r rune) tea.KeyMsg {
		return tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{r}}
	}
	longPane := func() {
		m.pane.Height = 4
		m.pane.SetContent(strings.Repeat("line\n", 40))
	}

	// The trace holds the focus to begin with.
	if m.onPane() {
		t.Fatal("the inspector holds the focus on open")
	}
	press(letter('j'))
	if m.cursor != 2 || m.pane.YOffset != 0 {
		t.Fatalf("j on the trace: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	press(letter('k'))
	if m.cursor != 1 {
		t.Fatalf("k on the trace: cursor = %d, want 1", m.cursor)
	}

	// ctrl+j hands the focus to the inspector, and j follows it there.
	press(tea.KeyMsg{Type: tea.KeyCtrlJ})
	if !m.onPane() {
		t.Fatal("ctrl+j did not focus the inspector")
	}
	longPane()
	press(letter('j'))
	if m.cursor != 1 || m.pane.YOffset != 1 {
		t.Fatalf("j on the inspector: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	press(letter('k'))
	if m.cursor != 1 || m.pane.YOffset != 0 {
		t.Fatalf("k on the inspector: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}

	// ctrl+k hands it back.
	press(tea.KeyMsg{Type: tea.KeyCtrlK})
	if m.onPane() {
		t.Fatal("ctrl+k did not focus the trace")
	}
	press(letter('j'))
	if m.cursor != 2 {
		t.Fatalf("j after ctrl+k: cursor = %d, want 2", m.cursor)
	}

	// d and u reach the inspector without taking the focus, so the next j is
	// still a row.
	longPane()
	press(letter('d'))
	if m.pane.YOffset == 0 {
		t.Fatal("d did not page the inspector")
	}
	if m.onPane() {
		t.Fatal("d moved the focus")
	}
	press(letter('u'))
	if m.pane.YOffset != 0 {
		t.Fatalf("u: inspector offset = %d, want 0", m.pane.YOffset)
	}

	// vim scrolls a view a line at a time on these two, cursor unmoved.
	longPane()
	at := m.cursor
	press(tea.KeyMsg{Type: tea.KeyCtrlE})
	if m.cursor != at || m.pane.YOffset != 1 {
		t.Fatalf("ctrl+e: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
	press(tea.KeyMsg{Type: tea.KeyCtrlY})
	if m.cursor != at || m.pane.YOffset != 0 {
		t.Fatalf("ctrl+y: cursor = %d, inspector offset = %d", m.cursor, m.pane.YOffset)
	}
}

// With no inspector there is one pane, and the focus cannot leave it.
func TestFocusStaysOnTheTreeWithNoInspector(t *testing.T) {
	m := foldable(t)
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'i'}})
	m = next.(Model)
	m = m.dock(placeHidden)
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyCtrlJ})
	if next.(Model).onPane() {
		t.Error("the focus reached a hidden inspector")
	}
}

func TestVisualRangeKeepsTraceFocus(t *testing.T) {
	m := foldable(t)
	m.focus = winPane
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'v'}})
	m = next.(Model)
	if m.onPane() || !m.visual {
		t.Fatalf("visual start left focus %s and visual %v", m.focus, m.visual)
	}
	next, _ = m.Update(tea.KeyMsg{Type: tea.KeyCtrlJ})
	if next.(Model).onPane() {
		t.Fatal("ctrl+j moved a visual range into the inspector")
	}
}

func TestNarrowFooterKeepsFocusAndHelpHints(t *testing.T) {
	m := foldable(t)
	m.width = 80
	footer := ansi.Strip(m.footer())
	if !strings.Contains(footer, "ctrl+j inspector") || !strings.Contains(footer, "? help") {
		t.Fatalf("narrow trace footer = %q", footer)
	}
	m.focus = winPane
	footer = ansi.Strip(m.footer())
	if !strings.Contains(footer, "ctrl+k trace") || !strings.Contains(footer, "? help") {
		t.Fatalf("narrow inspector footer = %q", footer)
	}
	for _, entry := range helpTable {
		if entry[0] == "gg / G" && !strings.Contains(entry[1], "focused pane") {
			t.Fatalf("end-motion help = %q", entry[1])
		}
	}
}

func TestFrameMatchesTerminalHeight(t *testing.T) {
	for _, height := range []int{8, 15, 16, 23, 30} {
		for _, place := range []placement{placeBottom, placeTop, placeLeft, placeRight, placeHidden} {
			m := foldable(t)
			m.width, m.height, m.place = 140, height, place
			m = m.sized().clamp()
			if got := strings.Count(m.View(), "\n") + 1; got != m.height {
				t.Errorf("%s at height %d has %d rows", m.placeName(), height, got)
			}
		}
	}
}

func TestCursorHitTargetMatchesRenderedHeight(t *testing.T) {
	for _, place := range []placement{placeBottom, placeTop, placeLeft, placeRight} {
		m := foldable(t)
		m.width, m.height, m.place = 140, 30, place
		m.cursor, m.offset = 0, 0
		m = m.sized()
		for line := range 3 {
			if got := m.rowAtY(m.treeTop() + line); got != 0 {
				t.Errorf("%s cursor line %d maps to row %d", m.placeName(), line, got)
			}
		}
		if got := m.rowAtY(m.treeTop() + 3); got != 1 {
			t.Errorf("%s next line maps to row %d", m.placeName(), got)
		}
	}
}

func TestHelpScrollsInSmallTerminal(t *testing.T) {
	m := foldable(t)
	m.width, m.height, m.cursor, m.help = 40, 10, 1, true
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'j'}})
	m = next.(Model)
	if m.helpAt == 0 || m.cursor != 1 {
		t.Fatalf("help offset = %d, cursor = %d", m.helpAt, m.cursor)
	}
	before := m.helpAt
	next, _ = m.Update(tea.MouseMsg{Action: tea.MouseActionPress, Button: tea.MouseButtonWheelDown})
	m = next.(Model)
	if m.helpAt <= before || m.cursor != 1 {
		t.Fatalf("help wheel offset = %d, cursor = %d", m.helpAt, m.cursor)
	}
	view := m.View()
	if !strings.Contains(view, "esc close") || strings.Count(view, "\n")+1 != 10 {
		t.Fatalf("small help frame = %q", view)
	}
}

func TestMinimumFrameShowsSelectedRow(t *testing.T) {
	m := foldable(t)
	m.width, m.height, m.place = minWidth, minHeight, placeHidden
	m = m.sized().clamp()
	if view := m.View(); !strings.Contains(view, "Read") {
		t.Fatalf("minimum frame hid selected row: %q", view)
	}
}

func TestTimelineWheelDoesNotScrollInspector(t *testing.T) {
	for _, place := range []placement{placeBottom, placeTop, placeLeft, placeRight} {
		m := inspectorWithOutput(64 * 1024)
		m.place = place
		m = m.sized().clamp()
		m.pane.SetYOffset(10)
		before := m.pane.YOffset
		timelineY := m.treeRows() + 4
		switch place {
		case placeBottom:
			timelineY = m.dividerY() + 2
		case placeTop:
			timelineY = m.detailLines() + 1
		}
		next, _ := m.mouse(tea.MouseMsg{
			X: 1, Y: timelineY, Action: tea.MouseActionPress, Button: tea.MouseButtonWheelDown,
		})
		m = next.(Model)
		if m.pane.YOffset != before {
			t.Errorf("%s timeline changed inspector offset from %d to %d", m.placeName(), before, m.pane.YOffset)
		}
	}
}

func TestInspectorTabsAcceptTopAndSideClicks(t *testing.T) {
	patch := "--- file.go\n+++ file.go\n@@ -1 +1 @@\n-old\n+new\n"
	for _, place := range []placement{placeTop, placeLeft, placeRight} {
		node := &session.Node{
			Output: patch,
			Patch:  patch,
			Span:   otlp.Span{Attrs: map[string]string{"detail": "value"}},
		}
		m := Model{
			rows: []row{{label: "Edit", kind: kindTool, node: node}}, visibleRows: []int{0},
			width: 140, height: 30, split: 50, place: place, pane: viewport.New(80, 20),
		}.sized().refresh()
		if len(m.tabsFor()) < 2 {
			t.Fatalf("%s has %d tabs", m.placeName(), len(m.tabsFor()))
		}
		x := m.paneLeft() + 1 + m.tabCols()[1]
		next, _ := m.mouse(tea.MouseMsg{
			X: x, Y: m.paneTop(), Action: tea.MouseActionPress, Button: tea.MouseButtonLeft,
		})
		m = next.(Model)
		if m.tabAt() != 1 {
			t.Errorf("%s click selected tab %d", m.placeName(), m.tabAt())
		}
	}
}

func TestLiveReloadKeepsSelectedSpan(t *testing.T) {
	m := foldable(t)
	for i := range m.rows {
		if m.idOf(i) == "b" {
			m.cursor = m.indexOf(i)
		}
	}
	m.follow = false
	root := m.rows[0].node
	m = applyBatch(t, m, otlp.Batch{Spans: []otlp.Span{{
		SpanID: "before", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
		Start: root.Start().Add(time.Nanosecond), End: root.Start().Add(2 * time.Nanosecond),
		Attrs: map[string]string{"traces.view": "activity", "tool_name": "Read"},
	}}})
	if got := m.idOf(m.at(m.cursor)); got != "b" {
		t.Fatalf("selected span = %q, want b", got)
	}
}

func TestLiveReloadRebasesVisualAnchor(t *testing.T) {
	m := foldable(t)
	for i := range m.rows {
		if m.idOf(i) == "b" {
			m.cursor = m.indexOf(i)
		}
	}
	next, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'v'}})
	m = next.(Model)
	root := m.rows[0].node
	m = applyBatch(t, m, otlp.Batch{Spans: []otlp.Span{{
		SpanID: "before", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
		Start: root.Start().Add(-time.Nanosecond), End: root.Start(),
		Attrs: map[string]string{"traces.view": "activity", "tool_name": "Read"},
	}}})
	if got := m.idOf(m.at(m.anchorAt)); got != "b" {
		t.Fatalf("visual anchor = %q, want b", got)
	}
}

func TestLiveBatchRebuildRunsInCommand(t *testing.T) {
	m := foldable(t)
	root := m.rows[0].node
	batch := otlp.Batch{Spans: []otlp.Span{{
		SpanID: "later", ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
		Start: root.Start().Add(time.Millisecond), End: root.Start().Add(2 * time.Millisecond),
		Attrs: map[string]string{"traces.view": "activity", "tool_name": "Read"},
	}}}
	next, cmd := m.Update(BatchMsg(batch))
	queued := next.(Model)
	if cmd == nil || !queued.batchBusy || len(queued.rows) != len(m.rows) {
		t.Fatalf("queued batch: cmd %v, busy %v, rows %d", cmd != nil, queued.batchBusy, len(queued.rows))
	}
	next, _ = queued.Update(cmd())
	ready := next.(Model)
	if ready.batchBusy || len(ready.rows) != len(m.rows)+1 {
		t.Fatalf("ready batch: busy %v, rows %d", ready.batchBusy, len(ready.rows))
	}
}

func TestLiveBatchRebuildSerializesPendingBatches(t *testing.T) {
	m := foldable(t)
	root := m.rows[0].node
	batch := func(id string, offset time.Duration) BatchMsg {
		return BatchMsg(otlp.Batch{Spans: []otlp.Span{{
			SpanID: id, ParentID: "turn", Name: "agent.tool", Service: "claude-code", Session: "one",
			Start: root.Start().Add(offset), End: root.Start().Add(offset + time.Nanosecond),
			Attrs: map[string]string{"traces.view": "activity", "tool_name": "Read"},
		}}})
	}
	next, first := m.Update(batch("first", time.Millisecond))
	queued := next.(Model)
	next, second := queued.Update(batch("second", 2*time.Millisecond))
	queued = next.(Model)
	if first == nil || second != nil || queued.batchNext.Empty() {
		t.Fatalf("pending batch: first %v, second %v, empty %v", first != nil, second != nil, queued.batchNext.Empty())
	}
	next, second = queued.Update(first())
	if second == nil || !next.(Model).batchBusy {
		t.Fatal("first snapshot did not start the pending batch")
	}
	next, follow := next.(Model).Update(second())
	if follow != nil || next.(Model).batchBusy || len(next.(Model).rows) != len(m.rows)+2 {
		t.Fatalf("serialized batches ended with follow %v, busy %v, rows %d",
			follow != nil, next.(Model).batchBusy, len(next.(Model).rows))
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

func liveModelWithRows(b *testing.B, count int) Model {
	b.Helper()
	now := time.Now()
	attrs := map[string]string{"traces.view": "activity"}
	spans := make([]otlp.Span, count)
	for i := range spans {
		spans[i] = otlp.Span{
			SpanID: strconv.Itoa(i), ParentID: "0", Name: "agent.tool",
			Service: "claude-code", Session: "one", Start: now.Add(time.Duration(i)), End: now.Add(time.Duration(i)), Attrs: attrs,
		}
	}
	spans[0].ParentID, spans[0].Name = "", "agent.turn"
	store := session.NewStore()
	store.Add(spans)
	return New(store, "one", "benchmark")
}

func BenchmarkLiveBatchQueue35000Rows(b *testing.B) {
	m := liveModelWithRows(b, 35000)
	batch := otlp.Batch{Spans: []otlp.Span{{
		SpanID: "new", ParentID: "0", Name: "agent.tool", Service: "claude-code", Session: "one",
		Start: time.Now(), End: time.Now(), Attrs: map[string]string{"traces.view": "activity"},
	}}}
	b.ReportAllocs()
	b.ResetTimer()
	for range b.N {
		one := m
		if _, cmd := one.Update(BatchMsg(batch)); cmd == nil {
			b.Fatal("live batch returned no command")
		}
	}
}

func BenchmarkLiveBatchBuild35000Rows(b *testing.B) {
	m := liveModelWithRows(b, 35000)
	batch := otlp.Batch{Spans: []otlp.Span{{
		SpanID: "new", ParentID: "0", Name: "agent.tool", Service: "claude-code", Session: "one",
		Start: time.Now(), End: time.Now(), Attrs: map[string]string{"traces.view": "activity"},
	}}}
	b.ReportAllocs()
	b.ResetTimer()
	for range b.N {
		_ = buildBatch(m.store, batch)()
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
