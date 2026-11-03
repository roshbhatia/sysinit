package ty

import (
	"context"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func TestTmuxPickerAcceptsQInSearch(t *testing.T) {
	model := newChoiceModel([]string{"query-service", "other"}, "sessions")
	updated, _ := model.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'q'}})
	actual := updated.(choiceModel)
	if actual.done || actual.input.Value() != "q" || len(actual.matches) != 1 {
		t.Fatalf("q must search in insert mode: %+v", actual)
	}
	updated, _ = actual.Update(tea.KeyMsg{Type: tea.KeyEsc})
	updated, _ = updated.(choiceModel).Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'q'}})
	if !updated.(choiceModel).done {
		t.Fatal("q must quit in normal mode")
	}
}

func TestTmuxPickerActionsRespectSearchMode(t *testing.T) {
	m := newChoiceModel([]string{"session", "provider"}, "sessions")
	m.closeTargets, m.shortcuts = true, map[string]int{"$": 1}
	updated, _ := m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'x'}})
	if updated.(choiceModel).done {
		t.Fatal("search text closed a session")
	}
	m.insert = false
	updated, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'x'}})
	if got := updated.(choiceModel); got.action != "close" || got.selected != 0 {
		t.Fatalf("close=%+v", got)
	}
	updated, _ = m.Update(tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune{'$'}})
	if got := updated.(choiceModel); !got.done || got.selected != 1 {
		t.Fatalf("shortcut=%+v", got)
	}
}

func TestTmuxPickerReadsXDGConfig(t *testing.T) {
	config := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", config)
	t.Setenv("SYSINIT_TMUX_PROVIDERS", "")
	t.Setenv("TMUX", "test")
	if err := os.Mkdir(filepath.Join(config, "sysinit"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(config, "sysinit", "tmux-providers.json"), []byte(`{"version":"sysinit.tmux-providers/v1","providers":[]}`), 0600); err != nil {
		t.Fatal(err)
	}
	runner, calls := runnerFor(t, map[string][]byte{
		"tmux list-sessions -F #{session_name}\t#{session_windows}\t#{session_attached}":                                                   []byte("test\t1\t1\n"),
		"tmux list-panes -a -F #{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_current_command}\t#{pane_current_path}": []byte("%0\ttest\t0\t0\tsh\t/tmp\n"),
	})
	err := runTmuxPicker(io.Discard, runner)
	if err == nil || !strings.Contains(err.Error(), "needs a terminal") || len(*calls) != 2 {
		t.Fatalf("configuration was not read from XDG_CONFIG_HOME: calls=%v err=%v", *calls, err)
	}
}

func TestTmuxProviderProtocol(t *testing.T) {
	manifest := providerManifest{Version: "provider/v1", Command: []string{"provider"}}
	manifest.Actions = make(map[string]struct {
		Argv []string `json:"argv"`
	})
	manifest.Actions["picker.list"] = struct {
		Argv []string `json:"argv"`
	}{Argv: []string{"list"}}
	runner := func(_ context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
		var request map[string]any
		if err := json.NewDecoder(stdin).Decode(&request); err != nil {
			t.Fatal(err)
		}
		if name != "provider" || len(args) != 1 || args[0] != "list" || request["capability"] != "picker.list" {
			t.Fatalf("unexpected request: %s %v %v", name, args, request)
		}
		return json.Marshal(map[string]any{"version": "provider/v1", "kind": "result", "requestId": request["requestId"], "status": "ok", "output": map[string]any{"items": []any{}}})
	}
	output, err := callProvider(context.Background(), runner, manifest, "picker.list", "")
	if err != nil || string(output) != `{"items":[]}` {
		t.Fatalf("output=%s err=%v", output, err)
	}
}
