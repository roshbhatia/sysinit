package ty

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"strings"
	"testing"
)

type callRecord struct {
	name  string
	args  []string
	stdin string
}

func testRunner(responses map[string][]byte) (commandRunner, *[]callRecord) {
	calls := []callRecord{}
	runner := func(_ context.Context, name string, args []string, stdin io.Reader) ([]byte, error) {
		var input []byte
		if stdin != nil {
			input, _ = io.ReadAll(stdin)
		}
		calls = append(calls, callRecord{name, append([]string(nil), args...), string(input)})
		key := name + " " + strings.Join(args, " ")
		response, ok := responses[key]
		if !ok {
			return nil, errors.New("unexpected command: " + key)
		}
		return response, nil
	}
	return runner, &calls
}

func TestPanesReturnsStringIDsFromTmux(t *testing.T) {
	runner, _ := testRunner(map[string][]byte{
		"tmux list-panes -a -F #{pane_id}\t#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}": []byte("%3\tdemo\t1\t0\t1\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"panes"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
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

func TestPaneSendPastesAndSubmits(t *testing.T) {
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
	if got := run([]string{"pane", "send", "--submit", "%3"}, strings.NewReader("review this"), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if len(calls) != 3 || calls[0].name != "tmux" || calls[0].args[0] != "load-buffer" || calls[0].stdin != "review this" || calls[1].args[0] != "paste-buffer" || calls[2].args[0] != "send-keys" {
		t.Fatalf("unexpected tmux calls: %+v", calls)
	}
}

func TestPaneReadUsesTmuxCapture(t *testing.T) {
	runner, _ := testRunner(map[string][]byte{"tmux capture-pane -p -S - -t %3": []byte("hello\n")})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "read", "%3"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	if stdout.String() != "hello\n" {
		t.Fatalf("stdout = %q", stdout.String())
	}
}

func TestPaneSplitUsesStableTmuxPaneID(t *testing.T) {
	runner, _ := testRunner(map[string][]byte{
		"tmux split-window -P -F #{pane_id} -t %3 -v -c /tmp/demo": []byte("%9\n"),
	})
	var stdout, stderr bytes.Buffer
	if got := run([]string{"pane", "split", "%3", "--direction", "down", "--cwd", "/tmp/demo"}, strings.NewReader(""), &stdout, &stderr, runner); got != 0 {
		t.Fatalf("run() = %d, stderr %q", got, stderr.String())
	}
	var result actionResult
	if err := json.Unmarshal(stdout.Bytes(), &result); err != nil {
		t.Fatal(err)
	}
	if result.PaneID != "%9" || result.Action != "pane.split" {
		t.Fatalf("unexpected result: %+v", result)
	}
}

func TestPaneCommandsRejectNonTmuxIDs(t *testing.T) {
	runner, calls := testRunner(nil)
	for _, args := range [][]string{{"pane", "read"}, {"pane", "read", "9"}, {"pane", "focus", "not-a-pane"}, {"pane", "send", "--submit"}} {
		var stdout, stderr bytes.Buffer
		if got := run(args, strings.NewReader(""), &stdout, &stderr, runner); got != 2 {
			t.Errorf("run(%v) = %d, want usage exit 2", args, got)
		}
	}
	if len(*calls) != 0 {
		t.Fatalf("invalid commands reached tmux: %+v", *calls)
	}
}
