package pane

import (
	"slices"
	"testing"
)

func TestPaneCaptureDoesNotStartAHeadlessMux(t *testing.T) {
	want := []string{"cli", "--no-auto-start", "get-text", "--start-line", scrollback}
	if got := weztermArgs(); !slices.Equal(got, want) {
		t.Fatalf("weztermArgs() = %q, want %q", got, want)
	}
}
