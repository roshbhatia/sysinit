package ty

import (
	"bytes"
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"

	"github.com/charmbracelet/x/ansi"
	"github.com/roshbhatia/go-utils/cell"
)

func terminalTestConfig(t *testing.T) {
	t.Helper()
	root := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", root)
	if err := os.MkdirAll(filepath.Join(root, "sysinit"), 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "sysinit", "terminal.json"), []byte(`{"version":"sysinit.terminal/v1","renderer":"wezterm","executable":"/renderer","application":"/renderer.app"}`), 0600); err != nil {
		t.Fatal(err)
	}
}
func TestTerminalFocusChoosesOwningGUIBeforeRecentClient(t *testing.T) {
	terminalTestConfig(t)
	t.Setenv("TMUX", "")
	tty := filepath.Join(t.TempDir(), "tty")
	if err := os.WriteFile(tty, nil, 0600); err != nil {
		t.Fatal(err)
	}
	responses := map[string][]byte{
		"tmux list-clients -F #{client_name}\t#{client_termname}\t#{client_activity}\t#{session_name}": []byte("/dev/one\twezterm\t1\treview\n/dev/two\twezterm\t20\tother\n/dev/remote\twezterm\t30\treview\n"),
		"tmux switch-client -c /dev/one -t @2":                                                         nil,
		"tmux select-pane -t %3":                                                                       nil,
		"/renderer cli --no-auto-start list --format json":                                             []byte(`[{"pane_id":41,"tty_name":"/dev/one"},{"pane_id":42,"tty_name":"/dev/two"}]`),
		"/renderer cli --no-auto-start activate-tab --tab-id 0":                                        nil,
		"/renderer cli --no-auto-start activate-pane --pane-id 41":                                     nil,
		"/usr/bin/open -a /renderer.app":                                                               nil,
	}
	for key, value := range responses {
		delete(responses, key)
		responses[strings.ReplaceAll(key, "/dev/one", tty)] = []byte(strings.ReplaceAll(string(value), "/dev/one", tty))
	}
	runner, calls := runnerFor(t, responses)
	ok, err := focusTmuxTarget(context.Background(), runner, "review", "@2", "%3")
	if err != nil || !ok {
		t.Fatalf("focused=%v err=%v", ok, err)
	}
	request, err := os.ReadFile(tty)
	if err != nil || !strings.HasPrefix(string(request), "\x1b]1337;SetUserVar=SYSINIT_FOCUS=") {
		t.Fatalf("GUI focus request %q: %v", request, err)
	}
	for _, c := range *calls {
		if strings.Contains(strings.Join(c.args, " "), "/dev/two -t") {
			t.Fatal("switched unrelated GUI")
		}
	}
}
func TestTerminalDetachedSessionDoesNotReplaceAnotherGUI(t *testing.T) {
	terminalTestConfig(t)
	t.Setenv("TMUX", "")
	runner, calls := runnerFor(t, map[string][]byte{"tmux list-clients -F #{client_name}\t#{client_termname}\t#{client_activity}\t#{session_name}": []byte("/dev/two\twezterm\t20\tother\n"), "/renderer cli --no-auto-start list --format json": []byte(`[{"pane_id":42,"tty_name":"/dev/two"}]`)})
	focused, err := focusTmuxTarget(context.Background(), runner, "review", "@2", "%3")
	if err != nil || focused || len(*calls) != 2 {
		t.Fatalf("focused=%v calls=%v err=%v", focused, *calls, err)
	}
}
func TestNativeTokenRenderingPreservesUnicodeAndEscapesTmux(t *testing.T) {
	var items nativeItems
	if err := json.Unmarshal([]byte(`[{"Foreground":{"Color":"#aabbcc"}},{"Text":"界 # two"},"ResetAttributes"]`), &items); err != nil {
		t.Fatal(err)
	}
	output := renderNative(items, 4, false)
	if ansi.Strip(output) != "界 …" || cell.Width(output) != 4 {
		t.Fatalf("rendered %q", output)
	}
	output = renderNative(items, 100, true)
	if !strings.Contains(output, "#[fg=#aabbcc]") || !strings.Contains(output, "## two") {
		t.Fatal(output)
	}
}

func TestStatusKeepsCurrentWindowAndSessionWithinCellBudget(t *testing.T) {
	tokens := func(text string) nativeItems {
		body, _ := json.Marshal(nativeItem{Text: text})
		return nativeItems{body}
	}
	p := presentation{Sessions: []presentationSession{{ID: "$1", Name: "workspace", Text: "[1 workspace]", Items: tokens("[1 workspace]"), Inactive: tokens("[1 workspace]")}}, Windows: []presentationWindow{{ID: "@1", Session: "workspace", Index: 0, Text: "[1 first]", Items: tokens("[1 first]")}, {ID: "@2", Session: "workspace", Index: 1, Text: "[2 界 current]", Items: tokens("[2 界 current]")}}}
	p.Tabs.Active.FG = "#ffffff"
	p.Tabs.Active.BG = "#000000"
	style := regexp.MustCompile(`#[\[][^[\]]*\]`)
	for _, width := range []int{30, 60, 80, 160} {
		output := renderTmuxStatus(p, "$1", width, "@2", false)
		plain := style.ReplaceAllString(output, "")
		if cell.Width(plain) > width || !strings.Contains(plain, "[2") || !strings.Contains(plain, "[1 work") {
			t.Fatalf("width %d: %q (%d cells)", width, plain, cell.Width(plain))
		}
	}
}
func TestTerminalDispatchRemainsAvailableInsideTmux(t *testing.T) {
	terminalTestConfig(t)
	t.Setenv("TMUX", "/tmp/private,123,0")
	tty := filepath.Join(t.TempDir(), "tty")
	if err := os.WriteFile(tty, nil, 0600); err != nil {
		t.Fatal(err)
	}
	runner, _ := runnerFor(t, map[string][]byte{"/renderer cli --no-auto-start activate-tab --tab-id 0": nil,
		"/renderer cli --no-auto-start activate-pane --pane-id 57": nil,
		"/renderer cli --no-auto-start list --format json":         []byte(`[{"pane_id":57,"tty_name":"` + tty + `"}]`), "/usr/bin/open -a /renderer.app": nil})
	var output, stderr bytes.Buffer
	if code := run([]string{"terminal", "focus", "wezterm:57"}, strings.NewReader(""), &output, &stderr, runner); code != 0 {
		t.Fatalf("code=%d stderr=%s", code, &stderr)
	}
}

func TestTerminalFocusInsideRemoteTmuxStaysInThatClient(t *testing.T) {
	t.Setenv("TMUX", "/tmp/remote,123,0")
	runner, calls := runnerFor(t, map[string][]byte{
		"tmux display-message -p -t %3 #{session_name}\t#{window_id}\t#{pane_current_path}\t#{@sysinit_float_parent}": []byte("remote\t@2\t/repo\t\n"),
		"tmux list-clients -F #{client_name}\t#{client_termname}\t#{client_activity}\t#{session_name}":                []byte("/dev/remote\txterm-256color\t20\tremote\n"),
		"tmux select-window -t @2": nil, "tmux select-pane -t %3": nil, "tmux switch-client -t @2": nil,
	})
	if err := terminalFocus(context.Background(), runner, "%3"); err != nil {
		t.Fatal(err)
	}
	for _, call := range *calls {
		if call.name != "tmux" {
			t.Fatalf("remote focus invoked %s", call.name)
		}
	}
}

func TestStatusPreservesNativeSectionsAndWorkingIndicators(t *testing.T) {
	tokens := func(text string) nativeItems {
		body, _ := json.Marshal(nativeItem{Text: text})
		return nativeItems{body}
	}
	p := presentation{Mode: nativeStyle{FG: "#24273a", BG: "#8aadf4"}, Host: nativeStyle{FG: "#24273a", BG: "#8aadf4"}}
	p.Icons.Unlocked = "U"
	p.Icons.Locked = "L"
	p.Sessions = []presentationSession{{ID: "$1", Name: "default", Items: tokens("  [1] default"), Inactive: tokens("  [1] default"), Tail: tokens(" WORK  "), TailText: " WORK  ", Text: "  [1] default WORK  "}}
	p.Windows = []presentationWindow{{ID: "@1", Session: "default", Items: tokens("  [1] roshbhatia/sysinit  "), Tail: tokens("WORK "), TailText: "WORK ", Text: "  [1] roshbhatia/sysinit  WORK ", Host: tokens("[1] HOST local "), HostText: "[1] HOST local "}}
	p.Tabs.Active.FG = "#8aadf4"
	p.Tabs.Active.BG = "#24273a"
	strip := regexp.MustCompile(`#\[[^\]]*\]`)
	for _, width := range []int{60, 80, 160} {
		output := renderTmuxStatus(p, "$1", width, "@1", false)
		plain := strip.ReplaceAllString(output, "")
		if !strings.Contains(plain, "NORMAL U") || strings.Count(plain, "WORK") != 2 || !strings.Contains(plain, "[1] HOST local") || cell.Width(plain) > width {
			t.Fatalf("width %d: %q", width, plain)
		}
	}
	output := strip.ReplaceAllString(renderTmuxStatus(p, "$1", 80, "@1", true), "")
	if !strings.Contains(output, "LOCKED L") {
		t.Fatal(output)
	}
}
