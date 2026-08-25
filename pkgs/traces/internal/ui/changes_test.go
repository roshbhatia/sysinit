package ui

import (
	"strings"
	"testing"

	"github.com/charmbracelet/bubbles/viewport"

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
