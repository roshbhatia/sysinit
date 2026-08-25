package ui

import (
	"strings"
	"testing"

	"github.com/charmbracelet/bubbles/viewport"
	"github.com/charmbracelet/x/ansi"

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
