package ui

import (
	"os"
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

func yes() *bool {
	on := true
	return &on
}

func no() *bool {
	off := false
	return &off
}

// tint answers a base16 slot, and falls back to an ANSI index rather than to a
// 256-colour number. glamour's own styles name colours such as 203 and 63, which
// hold whatever the palette says and ignore the terminal. An index under 16 is
// the terminal's own colour, so an unthemed machine still matches its scheme.
func tint(slot, index string) *string {
	colour := hexOf(slot, index)
	return &colour
}

// base16 maps the scheme's slots onto glamour, following the convention the
// scheme itself is written to: 08 is a variable, 0B a string, 0D a function,
// and 0E a keyword.
func chroma() *ansi.Chroma {
	return &ansi.Chroma{
		Text:                ansi.StylePrimitive{Color: tint("base05", "7")},
		Error:               ansi.StylePrimitive{Color: tint("base08", "1")},
		Comment:             ansi.StylePrimitive{Color: tint("base03", "8")},
		CommentPreproc:      ansi.StylePrimitive{Color: tint("base0A", "3")},
		Keyword:             ansi.StylePrimitive{Color: tint("base0E", "5")},
		KeywordReserved:     ansi.StylePrimitive{Color: tint("base0E", "5")},
		KeywordNamespace:    ansi.StylePrimitive{Color: tint("base08", "1")},
		KeywordType:         ansi.StylePrimitive{Color: tint("base0A", "3")},
		Operator:            ansi.StylePrimitive{Color: tint("base0C", "6")},
		Punctuation:         ansi.StylePrimitive{Color: tint("base05", "7")},
		Name:                ansi.StylePrimitive{Color: tint("base05", "7")},
		NameBuiltin:         ansi.StylePrimitive{Color: tint("base0D", "4")},
		NameTag:             ansi.StylePrimitive{Color: tint("base08", "1")},
		NameAttribute:       ansi.StylePrimitive{Color: tint("base0A", "3")},
		NameClass:           ansi.StylePrimitive{Color: tint("base0A", "3")},
		NameConstant:        ansi.StylePrimitive{Color: tint("base09", "3")},
		NameDecorator:       ansi.StylePrimitive{Color: tint("base0D", "4")},
		NameException:       ansi.StylePrimitive{Color: tint("base08", "1")},
		NameFunction:        ansi.StylePrimitive{Color: tint("base0D", "4")},
		NameOther:           ansi.StylePrimitive{Color: tint("base05", "7")},
		Literal:             ansi.StylePrimitive{Color: tint("base0B", "2")},
		LiteralNumber:       ansi.StylePrimitive{Color: tint("base09", "3")},
		LiteralDate:         ansi.StylePrimitive{Color: tint("base0B", "2")},
		LiteralString:       ansi.StylePrimitive{Color: tint("base0B", "2")},
		LiteralStringEscape: ansi.StylePrimitive{Color: tint("base0C", "6")},
		GenericDeleted:      ansi.StylePrimitive{Color: tint("base08", "1")},
		GenericEmph:         ansi.StylePrimitive{Italic: yes()},
		GenericInserted:     ansi.StylePrimitive{Color: tint("base0B", "2")},
		GenericStrong:       ansi.StylePrimitive{Bold: yes()},
		GenericSubheading:   ansi.StylePrimitive{Color: tint("base0D", "4")},
	}
}

// style takes glamour's skeleton for the prefixes and the indents, then paints
// every colour from the host scheme. Nothing here keeps a colour glamour picked,
// and no element sets a background, so the terminal's own one shows through.
func style() ansi.StyleConfig {
	config := styles.LightStyleConfig
	if dark() {
		config = styles.DarkStyleConfig
	}

	config.Document.Margin = zero()
	config.Document.BlockPrefix = ""
	config.Document.BlockSuffix = ""
	config.Document.Color = tint("base05", "7")

	config.Heading.Color = tint("base0D", "4")
	config.H1.Prefix = "# "
	config.H1.Suffix = ""
	config.H1.Color = tint("base0D", "4")
	config.H1.BackgroundColor = nil
	config.H1.Bold = yes()
	config.H6.Color = tint("base03", "8")
	config.H6.Bold = no()

	config.BlockQuote.Color = tint("base03", "8")
	config.HorizontalRule.Color = tint("base03", "8")
	config.Item.BlockPrefix = "• "
	config.Link.Color = tint("base0C", "6")
	config.LinkText.Color = tint("base0D", "4")
	config.Image.Color = tint("base0E", "5")
	config.ImageText.Color = tint("base03", "8")

	config.Code.Color = tint("base0B", "2")
	config.Code.BackgroundColor = nil
	config.CodeBlock.Color = tint("base05", "7")
	config.CodeBlock.Margin = zero()
	config.CodeBlock.Chroma = chroma()

	config.Table.Color = tint("base05", "7")
	config.Text.Color = tint("base05", "7")

	return config
}

// formatter picks how chroma writes a fenced block. glamour defaults to 256
// colours, which rounds every scheme colour to the nearest of a fixed 256 and
// so paints a code block in colours the scheme does not hold.
func formatter() string {
	switch os.Getenv("COLORTERM") {
	case "truecolor", "24bit":
		return "terminal16m"
	}
	return "terminal256"
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
		glamour.WithChromaFormatter(formatter()),
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
