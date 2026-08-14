package ui

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

func writeFake(dir, name string) error {
	return os.WriteFile(filepath.Join(dir, name), []byte("#!/bin/sh\n"), 0o755)
}

func stream(events ...provider.Event) <-chan provider.Event {
	out := make(chan provider.Event, len(events))
	for _, event := range events {
		out <- event
	}
	close(out)
	return out
}

func TestDrainReturnsTheAnswerTheRunEndedWith(t *testing.T) {
	answer := &provider.Result{Text: "the answer"}
	got := Drain(stream(
		provider.Event{Kind: provider.Started, Text: "a model"},
		provider.Event{Kind: provider.Done, Result: answer},
	), nil)

	if got != answer {
		t.Errorf("the answer is %+v", got)
	}
}

func TestDrainReturnsNothingForARunThatNeverAnswered(t *testing.T) {
	if got := Drain(stream(provider.Event{Kind: provider.Text, Text: "thinking"}), nil); got != nil {
		t.Errorf("a run with no Done event returned %+v", got)
	}
}

func TestDrainWritesTheToolLinesAndNothingElse(t *testing.T) {
	var out strings.Builder
	Drain(stream(
		provider.Event{Kind: provider.Started, Text: "a model"},
		provider.Event{Kind: provider.Text, Text: "thinking out loud"},
		provider.Event{Kind: provider.Tool, Tool: "Bash", Text: "ls -a"},
		provider.Event{Kind: provider.Done, Result: &provider.Result{}},
	), &out)

	if got := out.String(); got != "Bash ls -a\n" {
		t.Errorf("the written lines are %q", got)
	}
}

func TestAQuietDrainWritesNothing(t *testing.T) {
	events := stream(
		provider.Event{Kind: provider.Tool, Tool: "Bash", Text: "ls"},
		provider.Event{Kind: provider.Done, Result: &provider.Result{}},
	)
	if got := Drain(events, nil); got == nil {
		t.Error("a quiet run lost its answer")
	}
}

func TestOnlyTheOpeningLineOfABlockIsShown(t *testing.T) {
	if got := first("  one\ntwo\nthree"); got != "one" {
		t.Errorf("the line is %q", got)
	}
	long := first(strings.Repeat("x", 400))
	if len([]rune(long)) != 200 || !strings.HasSuffix(long, "…") {
		t.Errorf("a long line is %d runes", len([]rune(long)))
	}
}

func TestALineIsCutByRunesRatherThanBytes(t *testing.T) {
	got := clip("日本語テキスト", 4)
	if len([]rune(got)) != 4 {
		t.Errorf("the cut line is %d runes: %q", len([]rune(got)), got)
	}
	if !strings.HasSuffix(got, "…") {
		t.Errorf("the cut line %q does not say it was cut", got)
	}
	if got := clip("short", 40); got != "short" {
		t.Errorf("a line that fits came back as %q", got)
	}
	if got := clip("anything", 0); got != "" {
		t.Errorf("a line cut to nothing is %q", got)
	}
}

func TestTheViewKeepsOnlyItsMostRecentLines(t *testing.T) {
	var m model
	for at := 0; at < depth+5; at++ {
		m.push(row{name: "Bash", text: "ls"})
	}
	if len(m.rows) != depth {
		t.Errorf("the view holds %d rows, want %d", len(m.rows), depth)
	}
}

func TestTheClockReadsAsMinutesAndSeconds(t *testing.T) {
	for _, one := range []struct {
		given time.Duration
		want  string
	}{
		{7 * time.Second, "0:07"},
		{65 * time.Second, "1:05"},
		{3*time.Minute + 20*time.Second, "3:20"},
	} {
		if got := clock(one.given); got != one.want {
			t.Errorf("%v reads as %q, want %q", one.given, got, one.want)
		}
	}
}

func TestTheToolGutterFitsTheWidestNameOnScreen(t *testing.T) {
	rows := []row{{name: "Bash"}, {name: "WebFetch"}, {name: ""}}
	if got := column(rows); got != len("WebFetch") {
		t.Errorf("the gutter is %d wide", got)
	}
	if got := column([]row{{name: strings.Repeat("x", 40)}}); got != 12 {
		t.Errorf("a very long tool name made the gutter %d wide", got)
	}
	if got := column(nil); got != 0 {
		t.Errorf("an empty view made the gutter %d wide", got)
	}
}

func TestTheFrameIsOneWidthAllTheWayDown(t *testing.T) {
	drawn := frame{
		title: "ask",
		width: 40,
		head:  "claude",
		rows:  []string{"Bash  ls -a", "Read  main.go"},
	}.String()

	lines := strings.Split(drawn, "\n")
	if len(lines) != 6 {
		t.Fatalf("the frame drew %d lines: %q", len(lines), drawn)
	}
	for at, line := range lines {
		if got := lipgloss.Width(line); got != 44 {
			t.Errorf("line %d is %d wide, want 44: %q", at, got, line)
		}
	}
	if !strings.Contains(lines[0], "ask") {
		t.Errorf("the top of the frame is %q", lines[0])
	}
}

func TestAFrameWithNoRowsHasNoDivider(t *testing.T) {
	drawn := frame{title: "ask", width: 30, head: "starting"}.String()
	if got := len(strings.Split(drawn, "\n")); got != 3 {
		t.Errorf("a frame with no rows drew %d lines: %q", got, drawn)
	}
}

func TestTheFrameStaysReadableInATinyTerminal(t *testing.T) {
	if got := inner(10); got != narrowest {
		t.Errorf("a 10 column terminal left %d columns, want %d", got, narrowest)
	}
	if got := inner(500); got != widest-4 {
		t.Errorf("a very wide terminal left %d columns, want %d", got, widest-4)
	}
	if got := inner(0); got <= 0 {
		t.Errorf("an unmeasured terminal left %d columns", got)
	}
}

func TestTwoHalvesOfARowReachBothEnds(t *testing.T) {
	got := split("left", "right", 20)
	if lipgloss.Width(got) != 20 {
		t.Errorf("the row is %d wide: %q", lipgloss.Width(got), got)
	}
	if !strings.HasPrefix(got, "left") || !strings.HasSuffix(got, "right") {
		t.Errorf("the row is %q", got)
	}
	if got := split("aVeryLongLeftHalf", "andARightHalf", 8); !strings.Contains(got, " ") {
		t.Errorf("two halves with no room lost the gap between them: %q", got)
	}
}

func TestEveryPickerKeyCarriesItsOwnHelp(t *testing.T) {
	for _, binding := range picking.ShortHelp() {
		if binding.Help().Key == "" || binding.Help().Desc == "" {
			t.Errorf("%v has no help", binding.Keys())
		}
	}
	for _, binding := range running.ShortHelp() {
		if binding.Help().Key == "" || binding.Help().Desc == "" {
			t.Errorf("%v has no help", binding.Keys())
		}
	}
}

func TestThePickerOpensOnAnAgentThatIsInstalled(t *testing.T) {
	dir := t.TempDir()
	t.Setenv("PATH", dir)

	offer := []provider.Info{
		{Name: "missing", Binary: "definitely-not-here"},
		{Name: "present", Binary: "present-agent"},
	}
	if err := writeFake(dir, "present-agent"); err != nil {
		t.Fatal(err)
	}

	if got := ready(offer); got != 1 {
		t.Errorf("the picker opened on %d, want the installed one at 1", got)
	}
}

func TestThePickerOpensOnTheFirstAgentWhenNoneIsInstalled(t *testing.T) {
	t.Setenv("PATH", t.TempDir())
	offer := []provider.Info{{Name: "one", Binary: "nope-one"}, {Name: "two", Binary: "nope-two"}}
	if got := ready(offer); got != 0 {
		t.Errorf("the picker opened on %d, want 0", got)
	}
}

func TestThereIsNothingToPickFromAnEmptyList(t *testing.T) {
	if _, err := Pick(nil); err == nil {
		t.Error("an empty list was picked from")
	}
}

func press(start picker, keys ...tea.KeyMsg) picker {
	at := tea.Model(start)
	for _, one := range keys {
		at, _ = at.Update(one)
	}
	done, _ := at.(picker)
	return done
}

func typed(text string) tea.KeyMsg {
	return tea.KeyMsg{Type: tea.KeyRunes, Runes: []rune(text)}
}

func TestTheArrowsAndTheVimKeysBothMoveThePicker(t *testing.T) {
	three := picker{offer: []provider.Info{{Name: "one"}, {Name: "two"}, {Name: "three"}}}

	if got := press(three, tea.KeyMsg{Type: tea.KeyDown}, typed("j")).at; got != 2 {
		t.Errorf("two moves down landed on %d", got)
	}
	if got := press(three, tea.KeyMsg{Type: tea.KeyDown}, tea.KeyMsg{Type: tea.KeyUp}).at; got != 0 {
		t.Errorf("down then up landed on %d", got)
	}
}

func TestThePickerStopsAtBothEndsOfTheList(t *testing.T) {
	two := picker{offer: []provider.Info{{Name: "one"}, {Name: "two"}}}

	down := []tea.KeyMsg{{Type: tea.KeyDown}, {Type: tea.KeyDown}, {Type: tea.KeyDown}}
	if got := press(two, down...).at; got != 1 {
		t.Errorf("three moves down past the end landed on %d", got)
	}
	if got := press(two, tea.KeyMsg{Type: tea.KeyUp}).at; got != 0 {
		t.Errorf("a move up from the top landed on %d", got)
	}
}

func TestANumberPicksAndRunsInOneKey(t *testing.T) {
	two := picker{offer: []provider.Info{{Name: "one"}, {Name: "two"}}}

	got := press(two, typed("2"))
	if !got.took || got.at != 1 {
		t.Errorf("2 landed on %d, took %v", got.at, got.took)
	}
	if got := press(two, typed("9")); got.took {
		t.Error("a number past the end of the list picked something")
	}
}

func TestEnterTakesWhatTheCursorIsOn(t *testing.T) {
	two := picker{offer: []provider.Info{{Name: "one"}, {Name: "two"}}}

	got := press(two, tea.KeyMsg{Type: tea.KeyDown}, tea.KeyMsg{Type: tea.KeyEnter})
	if !got.took || got.at != 1 {
		t.Errorf("enter landed on %d, took %v", got.at, got.took)
	}
}

func TestQuittingThePickerTakesNothing(t *testing.T) {
	two := picker{offer: []provider.Info{{Name: "one"}, {Name: "two"}}}

	for _, key := range []tea.KeyMsg{typed("q"), {Type: tea.KeyEsc}, {Type: tea.KeyCtrlC}} {
		got := press(two, key)
		if got.took || !got.dropped {
			t.Errorf("%v took %v, dropped %v", key, got.took, got.dropped)
		}
	}
}

func TestStoppingTheRunStopsTheAgentAndNotOnlyTheView(t *testing.T) {
	asked := false
	start := model{events: stream(), stop: func() { asked = true }}

	after, _ := tea.Model(start).Update(tea.KeyMsg{Type: tea.KeyCtrlC})
	done, _ := after.(model)

	if !done.stopped {
		t.Error("ctrl+c left the run going")
	}
	if !asked {
		t.Error("ctrl+c stopped the view without stopping the agent")
	}
	if done.View() != "" {
		t.Errorf("a stopped run still draws %q", done.View())
	}
}

func TestTheRunViewTakesItsWidthFromTheTerminal(t *testing.T) {
	after, _ := tea.Model(model{events: stream()}).Update(tea.WindowSizeMsg{Width: 60})
	if got, _ := after.(model); got.width != 60 {
		t.Errorf("the view is %d wide", got.width)
	}
}
