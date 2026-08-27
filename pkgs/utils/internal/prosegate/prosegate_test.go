package prosegate

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/hookfmt"
)

func reminder(t *testing.T, session, prompt string) hookfmt.Outcome {
	t.Helper()
	payload, err := json.Marshal(map[string]string{"session_id": session, "prompt": prompt})
	if err != nil {
		t.Fatal(err)
	}
	return remind(bytes.NewReader(payload))
}

func TestReminderArmsOnce(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_GATE_DIR", t.TempDir())
	const session = "session-1"
	if outcome := reminder(t, session, ""); outcome.Kind != hookfmt.Context {
		t.Fatalf("first reminder = %+v", outcome)
	}
	if outcome := reminder(t, session, ""); outcome.Kind != hookfmt.Pass {
		t.Fatalf("second reminder = %+v", outcome)
	}
	arm(session)
	if outcome := reminder(t, session, ""); outcome.Kind != hookfmt.Context {
		t.Fatalf("armed reminder = %+v", outcome)
	}
}

func TestNoterseExemptsOneTurn(t *testing.T) {
	t.Setenv("SYSINIT_PROSE_GATE_DIR", t.TempDir())
	const session = "session-2"
	if outcome := reminder(t, session, "explain this NOTERSE"); outcome.Kind != hookfmt.Pass {
		t.Fatalf("escape reminder = %+v", outcome)
	}
	if !release(session) || release(session) {
		t.Fatal("escape did not last exactly one turn")
	}
	if armPath("../escape") != "" {
		t.Fatal("session path accepted a separator")
	}
}

func TestApplyLocateAndSplice(t *testing.T) {
	replaced, ok := apply(" — ", valeAlertAction{Name: "replace", Params: []string{", "}})
	if !ok || replaced != ", " {
		t.Fatalf("replacement = %q, %v", replaced, ok)
	}
	line := []rune("path and target")
	alert := fileAlert{valeAlert: valeAlert{Match: "target"}, Span: []int{99, 120}}
	start, end, ok := locate(line, alert)
	if !ok || string(line[start-1:end]) != "target" {
		t.Fatalf("located %d:%d, %v", start, end, ok)
	}
	spliced, _ := splice([]rune("schema.yaml —  name"), 13, 14, ": ")
	if string(spliced) != "schema.yaml: name" {
		t.Fatalf("spliced line = %q", string(spliced))
	}
}

func TestMarkdownSkipsHiddenDirectories(t *testing.T) {
	root := t.TempDir()
	visible := filepath.Join(root, "README.md")
	hidden := filepath.Join(root, ".cache", "ignored.md")
	if err := os.MkdirAll(filepath.Dir(hidden), 0o700); err != nil {
		t.Fatal(err)
	}
	for _, path := range []string{visible, hidden} {
		if err := os.WriteFile(path, []byte("text\n"), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	files, err := markdown([]string{root})
	if err != nil {
		t.Fatalf("markdown: %v", err)
	}
	if len(files) != 1 || files[0] != visible {
		t.Fatalf("markdown files = %v", files)
	}
}

func TestFindingsUsesConfiguredStyle(t *testing.T) {
	if stylePath() == "" {
		t.Skip("SYSINIT_PROSE_STYLE is unset")
	}
	got := findings("This seamlessly leverages one pivotal unlock.\n")
	if len(got) == 0 {
		t.Fatal("configured style reported no findings")
	}
	for _, finding := range got {
		if strings.TrimSpace(finding.Check) == "" {
			t.Fatalf("finding has no rule: %+v", finding)
		}
	}
}

func TestBlocksCitationMarkupOnFirstAlert(t *testing.T) {
	citation := []valeAlert{{Check: "Sysinit.CitationMarkup"}}
	if !blocks(citation) {
		t.Fatal("citation markup did not block on its first alert")
	}
	if blocks([]valeAlert{{Check: "Sysinit.MarketingVerb"}}) {
		t.Fatal("ordinary style alert blocked before the threshold")
	}
	if !blocks([]valeAlert{{Check: "Sysinit.MarketingVerb"}, {Check: "Sysinit.FillerOpener"}}) {
		t.Fatal("two ordinary style alerts did not block")
	}
}
