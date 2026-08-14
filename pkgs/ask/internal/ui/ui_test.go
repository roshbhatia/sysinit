package ui

import (
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

// stream sends the events and closes, as a provider does when its run ends.
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

// A caller whose stderr is a file gets the tool lines as plain text, since that is the part
// worth keeping and prose is not.
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

// A quiet run gets nothing at all, which is what makes ask safe inside a pipe.
func TestAQuietDrainWritesNothing(t *testing.T) {
	events := stream(
		provider.Event{Kind: provider.Tool, Tool: "Bash", Text: "ls"},
		provider.Event{Kind: provider.Done, Result: &provider.Result{Text: "x"}},
	)
	if got := Drain(events, nil); got == nil || got.Text != "x" {
		t.Errorf("a quiet run lost its answer: %+v", got)
	}
}

func TestTheSummaryCarriesTheTimeTheTurnsAndTheCost(t *testing.T) {
	got := Summary(&provider.Result{
		Duration: 1500 * time.Millisecond,
		Turns:    3,
		CostUSD:  0.1234,
	})
	for _, want := range []string{"1.5s", "3 turns", "$0.1234"} {
		if !strings.Contains(got, want) {
			t.Errorf("the summary %q does not carry %q", got, want)
		}
	}
}

func TestThereIsNoSummaryForARunThatNeverAnswered(t *testing.T) {
	if got := Summary(nil); got != "" {
		t.Errorf("the summary is %q, want nothing", got)
	}
}

// A paragraph in a progress view pushes the rest of it off the screen, so only the opening
// line is shown.
func TestOnlyTheOpeningLineOfABlockIsShown(t *testing.T) {
	if got := first("  one\ntwo\nthree"); got != "one" {
		t.Errorf("the line is %q", got)
	}
	long := first(strings.Repeat("x", 200))
	if len([]rune(long)) != 101 || !strings.HasSuffix(long, "…") {
		t.Errorf("a long line is %d runes", len([]rune(long)))
	}
}

// The view keeps a fixed number of lines, or a long run scrolls the caller's terminal away.
func TestTheViewKeepsOnlyItsMostRecentLines(t *testing.T) {
	var m model
	for at := 0; at < depth+5; at++ {
		m.push("line")
	}
	if len(m.lines) != depth {
		t.Errorf("the view holds %d lines, want %d", len(m.lines), depth)
	}
}
