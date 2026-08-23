// Package ui provides minimal ANSI color and message formatting for stderr output.
// Zero external dependencies — uses ANSI 256 escape codes directly.
// Respects NO_COLOR env var and non-TTY detection.
package ui

import (
	"fmt"
	"os"
)

// ANSI 256 color codes.
const (
	ColorPurple = 99
	ColorGreen  = 76
	ColorRed    = 204
	ColorYellow = 214
	ColorBlue   = 69
	ColorGray   = 245
	ColorWhite  = 255
)

// Color support is resolved once at init time, per stream: messages go to
// stderr but list output goes to stdout, and either one may be redirected
// on its own.
var (
	colorsEnabled       bool
	stdoutColorsEnabled bool
)

func init() {
	noColor := os.Getenv("NO_COLOR") != ""
	colorsEnabled = isTTY(os.Stderr) && !noColor
	stdoutColorsEnabled = isTTY(os.Stdout) && !noColor
}

// isTTY reports whether f is a terminal.
func isTTY(f *os.File) bool {
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return info.Mode()&os.ModeCharDevice != 0
}

// IsTTY reports whether stderr is a terminal.
func IsTTY() bool { return colorsEnabled }

// Color wraps text in ANSI 256-color escapes if colors are enabled.
func Color(code int, text string) string {
	if !colorsEnabled {
		return text
	}
	return fmt.Sprintf("\033[38;5;%dm%s\033[0m", code, text)
}

// StdoutColor wraps text in ANSI 256-color escapes if stdout carries colors.
func StdoutColor(code int, text string) string {
	if !stdoutColorsEnabled {
		return text
	}
	return fmt.Sprintf("\033[38;5;%dm%s\033[0m", code, text)
}

// StdoutFaint dims stdout text using the gray color.
func StdoutFaint(text string) string {
	return StdoutColor(ColorGray, text)
}

func Bold(text string) string {
	if !colorsEnabled {
		return text
	}
	return fmt.Sprintf("\033[1m%s\033[0m", text)
}

func Faint(text string) string {
	return Color(ColorGray, text)
}

func AccentBold(text string) string {
	if !colorsEnabled {
		return text
	}
	return fmt.Sprintf("\033[1;38;5;%dm%s\033[0m", ColorPurple, text)
}

func Success(msg string) string {
	return Color(ColorGreen, "✓") + " " + msg
}

func Error(msg string) string {
	return Color(ColorRed, "✗") + " " + msg
}

func Warning(msg string) string {
	return Color(ColorYellow, "⚠") + " " + msg
}

func Info(msg string) string {
	return Color(ColorBlue, "ℹ") + " " + msg
}

func Successf(format string, a ...any) string {
	return Success(fmt.Sprintf(format, a...))
}

func Errorf(format string, a ...any) string {
	return Error(fmt.Sprintf(format, a...))
}

func Warningf(format string, a ...any) string {
	return Warning(fmt.Sprintf(format, a...))
}

func Infof(format string, a ...any) string {
	return Info(fmt.Sprintf(format, a...))
}

// SetColorsEnabled overrides the stderr color detection for testing.
func SetColorsEnabled(enabled bool) {
	colorsEnabled = enabled
}

// SetStdoutColorsEnabled overrides the stdout color detection for testing.
func SetStdoutColorsEnabled(enabled bool) {
	stdoutColorsEnabled = enabled
}
