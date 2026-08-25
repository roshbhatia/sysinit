package ui

import (
	"strconv"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/x/ansi"

	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
)

func TestChangesTabRendersEditOutput(t *testing.T) {
	patch := "## internal/file.go\n\n@@ -1 +1 @@\n-old\n+new\n"
	model := Model{pane: viewport.New(100, 20)}
	out := model.tabChanges(row{label: "Edit", node: &session.Node{Output: patch}})
	if !strings.Contains(out, "file.go") || !strings.Contains(out, "+1") || !strings.Contains(out, "-1") {
		t.Fatalf("changes tab = %q", out)
	}
}

func TestInspectorDetectsStructuredOutput(t *testing.T) {
	for name, input := range map[string]string{
		"json":       `{"ok":true,"count":2}`,
		"json lines": "{\"ok\":true}\n{\"ok\":false}",
		"diff":       "--- old\n+++ new\n@@ -1 +1 @@\n-old\n+new",
	} {
		if got := detectSyntax(input, ""); got == "" {
			t.Errorf("%s syntax was not detected", name)
		}
	}
	if got := detectSyntax("\x1b[31mred\x1b[0m", "bash"); got != "" {
		t.Errorf("ANSI syntax = %q, want empty", got)
	}
	if got := detectSyntax("printf '%s\\n' ready", "bash"); got != "bash" {
		t.Errorf("shell syntax = %q, want bash", got)
	}
}

func TestInspectorColorsJSONWithTerminalPalette(t *testing.T) {
	m := Model{width: 100, height: 40, split: 50, place: placeBottom, pane: viewport.New(80, 20)}.sized()
	lines := m.codeLines(`{"ok":true,"count":2}`, "json", 80)
	out := strings.Join(lines, "\n")
	if !strings.Contains(out, "\x1b[") {
		t.Fatalf("colored JSON = %q", out)
	}
	if plain := strings.TrimSpace(ansi.Strip(out)); plain != `{"ok":true,"count":2}` {
		t.Fatalf("colored JSON text = %q", plain)
	}
}

func inspectorWithOutput(size int) Model {
	return inspectorWithOutputs(size, 1)
}

func inspectorWithOutputs(size, count int) Model {
	line := `{"event":"build","ok":true,"path":"src/main.go"}` + "\n"
	output := strings.Repeat(line, size/len(line)+1)[:size]
	rows, visible := make([]row, count), make([]int, count)
	for i := range count {
		rows[i] = row{
			label: "Bash", kind: kindTool,
			node: &session.Node{Output: output, Span: otlp.Span{SpanID: strconv.Itoa(i)}},
		}
		visible[i] = i
	}
	return Model{
		rows:        rows,
		visibleRows: visible,
		width:       120,
		height:      40,
		split:       50,
		place:       placeBottom,
		pane:        viewport.New(80, 20),
	}.sized().refresh()
}

func TestInspectorLoadsOutputAsReaderScrolls(t *testing.T) {
	m := inspectorWithOutput(128 * 1024)
	if m.paneShown != inspectorChunkBytes || m.paneTotal != 128*1024 {
		t.Fatalf("initial bytes = %d of %d", m.paneShown, m.paneTotal)
	}
	for m.paneShown < m.paneTotal {
		before := m.paneShown
		m.pane.GotoBottom()
		m = m.scrollPane(1)
		if m.paneShown <= before {
			t.Fatalf("loaded bytes stayed at %d", m.paneShown)
		}
	}
	if output := m.rows[0].node.Output; !strings.Contains(m.rows[0].raw(), output) {
		t.Fatal("raw row lost output bytes")
	}
}

func TestInspectorRefreshPreservesScrollAndDetectsReplacement(t *testing.T) {
	m := inspectorWithOutput(64 * 1024)
	m.pane.SetYOffset(10)
	before := m.pane.YOffset
	unchanged := m.refresh()
	if unchanged.pane.YOffset != before {
		t.Fatalf("unchanged refresh offset = %d, want %d", unchanged.pane.YOffset, before)
	}

	m.rows[0].node.Output = strings.Repeat("x", len(m.rows[0].node.Output))
	replaced := m.refresh()
	if replaced.paneVersion == m.paneVersion {
		t.Fatal("same-size replacement kept stale pane version")
	}
	if replaced.pane.YOffset != before {
		t.Fatalf("replacement offset = %d, want %d", replaced.pane.YOffset, before)
	}
}

func TestInspectorRowChangeResetsLoadedBudget(t *testing.T) {
	m := inspectorWithOutputs(128*1024, 2)
	m.paneLoaded = m.paneTotal
	m = m.renderPane(m.paneIdentity(), m.currentPaneVersion(), false)
	m.cursor = 1
	m = m.refresh()
	if m.paneLoaded != inspectorChunkBytes || m.paneShown != inspectorChunkBytes {
		t.Fatalf("new row loaded %d bytes and showed %d", m.paneLoaded, m.paneShown)
	}
}

func TestWrapToPreservesUnicode(t *testing.T) {
	input := "a界b🙂c界d"
	wrapped := strings.Join(wrapTo(input, 3), "")
	if !utf8.ValidString(wrapped) || wrapped != input {
		t.Fatalf("wrapped text = %q", wrapped)
	}
}

func benchmarkInspectorRefresh(b *testing.B, size int) {
	m := inspectorWithOutput(size)
	if m.paneShown > inspectorChunkBytes {
		b.Fatalf("initial inspector rendered %d bytes", m.paneShown)
	}
	if m.pane.TotalLineCount() > 2000 {
		b.Fatalf("initial inspector rendered %d lines", m.pane.TotalLineCount())
	}
	b.SetBytes(int64(size))
	b.ReportAllocs()
	b.ResetTimer()
	for range b.N {
		one := m
		one.paneKey = ""
		_ = one.refresh()
	}
}

func BenchmarkInspectorRefresh32KiB(b *testing.B) {
	benchmarkInspectorRefresh(b, 32*1024)
}

func BenchmarkInspectorRefresh1MiB(b *testing.B) {
	benchmarkInspectorRefresh(b, 1024*1024)
}

func BenchmarkInspectorSelectionAfter1MiBLoaded(b *testing.B) {
	m := inspectorWithOutputs(1024*1024, 2)
	m.paneLoaded = m.paneTotal
	m = m.renderPane(m.paneIdentity(), m.currentPaneVersion(), false)
	b.ReportAllocs()
	b.ResetTimer()
	for range b.N {
		one := m
		one.cursor = 1
		_ = one.refresh()
	}
}
