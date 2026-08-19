package ui

import (
	"os"
	"strings"
	"testing"
)

func TestSuccessContainsCheckmark(t *testing.T) {
	SetColorsEnabled(false)
	msg := Success("done")
	if !strings.Contains(msg, "✓") || !strings.Contains(msg, "done") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestErrorContainsCross(t *testing.T) {
	SetColorsEnabled(false)
	msg := Error("fail")
	if !strings.Contains(msg, "✗") || !strings.Contains(msg, "fail") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestWarningContainsIcon(t *testing.T) {
	SetColorsEnabled(false)
	msg := Warning("watch out")
	if !strings.Contains(msg, "⚠") || !strings.Contains(msg, "watch out") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestInfoContainsMessage(t *testing.T) {
	SetColorsEnabled(false)
	msg := Info("note")
	if !strings.Contains(msg, "ℹ") || !strings.Contains(msg, "note") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestFaintContainsMessage(t *testing.T) {
	SetColorsEnabled(false)
	msg := Faint("dimmed")
	if !strings.Contains(msg, "dimmed") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestAccentBoldContainsText(t *testing.T) {
	SetColorsEnabled(false)
	msg := AccentBold("highlight")
	if msg != "highlight" {
		t.Errorf("expected plain 'highlight' when colors disabled, got %q", msg)
	}
}

func TestColorNoColorEnv(t *testing.T) {
	t.Setenv("NO_COLOR", "1")
	SetColorsEnabled(false)
	msg := Color(ColorGreen, "test")
	if strings.Contains(msg, "\033") {
		t.Errorf("expected no escape codes with NO_COLOR, got %q", msg)
	}
}

func TestColorPlainWhenNotTTY(t *testing.T) {
	// Colors disabled (simulating non-TTY)
	SetColorsEnabled(false)
	msg := Color(ColorPurple, "plain")
	if msg != "plain" {
		t.Errorf("expected plain text, got %q", msg)
	}
}

func TestColorEnabledProducesEscapes(t *testing.T) {
	SetColorsEnabled(true)
	defer SetColorsEnabled(false)
	msg := Color(ColorPurple, "purple")
	if !strings.Contains(msg, "\033[38;5;99m") {
		t.Errorf("expected ANSI escape, got %q", msg)
	}
}

func TestBoldWhenEnabled(t *testing.T) {
	SetColorsEnabled(true)
	defer SetColorsEnabled(false)
	msg := Bold("strong")
	if !strings.Contains(msg, "\033[1m") {
		t.Errorf("expected bold escape, got %q", msg)
	}
}

func TestAccentBoldWhenEnabled(t *testing.T) {
	SetColorsEnabled(true)
	defer SetColorsEnabled(false)
	msg := AccentBold("highlighted")
	if !strings.Contains(msg, "\033[1;38;5;99m") {
		t.Errorf("expected bold purple escape, got %q", msg)
	}
}

func TestSuccessfFormat(t *testing.T) {
	SetColorsEnabled(false)
	msg := Successf("added %d repos", 3)
	if !strings.Contains(msg, "added 3 repos") {
		t.Errorf("unexpected: %q", msg)
	}
}

func TestIsTTYFunc(t *testing.T) {
	// In test, stderr is not a terminal
	_ = os.Stderr
	// Just ensure it doesn't panic
	_ = IsTTY()
}
