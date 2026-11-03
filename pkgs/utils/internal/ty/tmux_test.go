package ty

import (
	"bytes"
	"context"
	"encoding/json"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func runTmuxForTest(args []string, stdin io.Reader, stdout, stderr io.Writer, runner commandRunner) int {
	return run(append([]string{"tmux"}, args...), stdin, stdout, stderr, runner)
}
func TestTmuxPanesReturnsStringIDsFromTmux(t *testing.T) {
	runner, _ := runnerFor(t, map[string][]byte{
		"tmux list-panes -a -F #{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}": []byte("%3\tdemo\t1\t0\t1\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := runTmuxForTest([]string{"panes"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("runTmuxForTest() = %d, stderr %q", got, stderr.String())
	}
	var result panesResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	var pane map[string]any
	if err := json.Unmarshal(result.Panes[0], &pane); err != nil {
		t.Fatal(err)
	}
	if pane["pane_id"] != "%3" || pane["session_name"] != "demo" || pane["pane_active"] != true {
		t.Fatalf("unexpected pane row: %#v", pane)
	}
}

func TestTmuxPaneSendPastesAndSubmits(t *testing.T) {
	calls := []callRecord{}
	runner := func(_ context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
		var input []byte
		if stdin != nil {
			input, _ = io.ReadAll(stdin)
		}
		calls = append(calls, callRecord{name, args, string(input)})
		return nil, nil
	}
	var stdout, stderr bytes.Buffer
	if got := runTmuxForTest([]string{"pane", "send", "--submit", "%3"}, strings.NewReader("review this"), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("runTmuxForTest() = %d, stderr %q", got, stderr.String())
	}
	if len(calls) != 3 || calls[0].name != "tmux" || calls[0].args[0] != "load-buffer" || calls[0].stdin != "review this" || calls[1].args[0] != "paste-buffer" || calls[2].args[0] != "send-keys" {
		t.Fatalf("unexpected tmux calls: %+v", calls)
	}
}

func TestTmuxPaneReadUsesTmuxCapture(t *testing.T) {
	runner, _ := runnerFor(t, map[string][]byte{"tmux capture-pane -p -S - -t %3": []byte("hello\n")})
	var stdout, stderr bytes.Buffer
	if got := runTmuxForTest([]string{"pane", "read", "%3"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("runTmuxForTest() = %d, stderr %q", got, stderr.String())
	}
	if stdout.String() != "hello\n" {
		t.Fatalf("stdout = %q", stdout.String())
	}
}

func TestTmuxPaneSplitUsesStableTmuxPaneID(t *testing.T) {
	runner, _ := runnerFor(t, map[string][]byte{
		"tmux split-window -P -F #{pane_id} -t %3 -v -c /tmp/demo": []byte("%9\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := runTmuxForTest([]string{"pane", "split", "%3", "--direction", "down", "--cwd", "/tmp/demo"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("runTmuxForTest() = %d, stderr %q", got, stderr.String())
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.PaneID != "%9" || result.Action != "pane.split" {
		t.Fatalf("unexpected result: %+v", result)
	}
}

func TestTmuxPaneCommandsRejectNonTmuxIDs(t *testing.T) {
	runner, calls := runnerFor(t, nil)
	for _, args := range [][]string{{"pane", "read"}, {"pane", "read", "9"}, {"pane", "focus", "not-a-pane"}, {"pane", "send", "--submit"}} {
		var stdout, stderr bytes.Buffer
		if got := runTmuxForTest(args, strings.NewReader(""), &stdout, &stderr, runner); got != 2 {
			t.Errorf("runTmuxForTest(%v) = %d, want usage exit 2", args, got)
		}
	}
	if len(*calls) != 0 {
		t.Fatalf("invalid commands reached tmux: %+v", *calls)
	}
}

func TestTmuxAutomaticallySelectedInsideTmux(t *testing.T) {
	t.Setenv("TMUX", "/tmp/tmux-503/default,1234,0")
	runner, calls := runnerFor(t, map[string][]byte{
		"tmux list-panes -a -F #{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}": []byte("%3\tdemo\t1\t0\t1\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"panes"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("exit=%d stderr=%s", got, &stderr)
	}
	if len(*calls) != 1 || (*calls)[0].name != "tmux" {
		t.Fatalf("unexpected backend calls: %v", *calls)
	}
}

func TestDefaultTmuxBackendPreservesNumericPaneTargets(t *testing.T) {
	t.Setenv("SYSINIT_TY_BACKEND", "tmux")
	t.Setenv("TMUX", "")
	t.Setenv("WEZTERM_PANE", "")
	runner, calls := runnerFor(t, map[string][]byte{"wezterm cli --no-auto-start get-text --pane-id 7": []byte("native pane\n")})
	var stdout, stderr bytes.Buffer
	if code := run([]string{"pane", "read", "7"}, strings.NewReader(""), &stdout, &stderr, runner); code != 0 {
		t.Fatalf("exit=%d stderr=%s", code, &stderr)
	}
	if stdout.String() != "native pane\n" || (*calls)[0].name != "wezterm" {
		t.Fatal("native pane target changed backend")
	}
}

func TestTmuxSessionOpenOutsideCreatesRenderer(t *testing.T) {
	terminalTestConfig(t)
	tty := filepath.Join(t.TempDir(), "tty")
	if err := os.WriteFile(tty, nil, 0600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("TMUX", "")
	runner, _ := runnerFor(t, map[string][]byte{
		"tmux list-clients -F #{client_name}\t#{client_termname}\t#{client_activity}\t#{session_name}": []byte(""),
		"sy open demo --format json":                                                                        []byte(`{"version":"seshy.open/v1","id":"seshy:demo","cwd":"/tmp/demo","command":["/bin/sh"],"environment":{}}`),
		"tmux new-session -d -P -F #{pane_id} -s demo -c /tmp/demo '/bin/sh'":                               []byte("%9\n"),
		"/renderer cli --no-auto-start list --format json":                                                  []byte(`[{"pane_id":42,"tty_name":"` + tty + `"}]`),
		"/renderer cli --no-auto-start activate-tab --tab-id 0":                                             nil,
		"/renderer cli --no-auto-start activate-pane --pane-id 42":                                          nil,
		"/usr/bin/open -a /renderer.app":                                                                    nil,
		"/renderer cli --no-auto-start spawn --new-window --cwd /tmp/demo -- tmux-client demo":              []byte("42\n"),
		"tmux list-panes -a -F #{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}": []byte("%9\tdemo\t0\t0\t1\n"),
	})
	var stdout, stderr bytes.Buffer
	if code := runTmuxForTest([]string{"session", "open", "demo"}, strings.NewReader(""), &stdout, &stderr, runner); code != 0 {
		t.Fatalf("exit=%d stderr=%s", code, &stderr)
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.PaneID != "%9" || result.Opened == nil || !*result.Opened {
		t.Fatalf("unexpected result: %+v", result)
	}
}
