package ui

import (
	"strings"

	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/glamour/ansi"
	"github.com/charmbracelet/glamour/styles"
)

// The frame draws on stderr and erases itself when the answer lands, so this
// renders for the watcher only. stdout still carries the bytes the caller asked
// for, byte for byte, whether or not a terminal is on the other end.

func zero() *uint {
	var none uint
	return &none
}

// style takes glamour's own scheme and drops the document margin, which would
// otherwise indent every line inside a border that already indents.
func style() ansi.StyleConfig {
	config := styles.LightStyleConfig
	if dark() {
		config = styles.DarkStyleConfig
	}
	config.Document.Margin = zero()
	config.Document.BlockPrefix = ""
	config.Document.BlockSuffix = ""
	if text := hexOf("base05", ""); text != "" {
		config.Document.Color = &text
	}
	if head := hexOf("base0D", ""); head != "" {
		config.Heading.Color = &head
	}
	return config
}

// A renderer costs a style parse to build, and the frame rebuilds its prose on
// every block the agent writes, so the one for this width is kept.
var (
	held  *glamour.TermRenderer
	sized int
)

func renderer(width int) (*glamour.TermRenderer, error) {
	if held != nil && sized == width {
		return held, nil
	}
	made, err := glamour.NewTermRenderer(
		glamour.WithStyles(style()),
		glamour.WithWordWrap(width),
	)
	if err != nil {
		return nil, err
	}
	held, sized = made, width
	return made, nil
}

// render turns the agent's markdown into frame rows. It answers the raw lines
// when glamour will not build, because a frame with plain text beats no frame.
func render(text string, width int) []string {
	if strings.TrimSpace(text) == "" {
		return nil
	}
	raw := strings.Split(text, "\n")
	if width < 8 {
		return raw
	}

	made, err := renderer(width)
	if err != nil {
		return raw
	}
	out, err := made.Render(text)
	if err != nil {
		return raw
	}

	lines := strings.Split(strings.Trim(out, "\n"), "\n")
	for at, line := range lines {
		lines[at] = strings.TrimRight(line, " ")
	}
	return lines
}
