// Anchoring: a note records the line it was written against and the text of that
// line. The number is what the file changes; the text is what a reader finds it by.
package note

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/store"
)

// How much of a line is kept as its anchor. Long enough to be unique in a file,
// short enough that the record stays readable when it is opened by hand.
const maxAnchor = 200

// newID returns the name a note keeps for as long as it exists.
func newID() (string, error) {
	raw := make([]byte, 4)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return hex.EncodeToString(raw), nil
}

// readLines returns a file's lines, or nil for a file that cannot be read. A caller
// re-anchoring a whole record reads each file once through `lineCache`.
type lineCache map[string][]string

func (c lineCache) lines(root, relative string) []string {
	if found, seen := c[relative]; seen {
		return found
	}
	var lines []string
	body, err := os.ReadFile(filepath.Join(root, relative))
	if err == nil {
		lines = strings.Split(strings.ReplaceAll(string(body), "\r\n", "\n"), "\n")
	}
	c[relative] = lines
	return lines
}

// anchorText is a line reduced to what survives an edit that only moves it: its own
// text, with the indentation and the trailing whitespace gone.
func anchorText(line string) string {
	return clipRunes(store.OneLine(strings.TrimSpace(line)), maxAnchor)
}

// clipRunes shortens text to limit runes.
func clipRunes(text string, limit int) string {
	runes := []rune(text)
	if len(runes) <= limit {
		return text
	}
	return string(runes[:limit])
}

// captureAnchor reads the line a note is being written against. An unreadable file or
// a line past the end anchors on nothing, which leaves the note pinned to its number.
func captureAnchor(root, relative string, line int64) string {
	lines := lineCache{}.lines(root, relative)
	if line < 1 || int(line) > len(lines) {
		return ""
	}
	return anchorText(lines[line-1])
}

// findAnchor returns the line `anchor` is on now, or 0 for a file that does not hold
// it exactly once.
//
// Exactly once is the whole rule, and it is the only guard: a file full of lines
// reading `end` moves no note, and a file holding one `end` moves it correctly. A note
// that lands on the wrong line is worse than one that stayed behind, because the
// reader cannot tell it from a note that was always wrong.
func findAnchor(lines []string, anchor string) int64 {
	if anchor == "" || len(lines) == 0 {
		return 0
	}
	found := int64(0)
	for i, line := range lines {
		if anchorText(line) != anchor {
			continue
		}
		if found != 0 {
			return 0
		}
		found = int64(i + 1)
	}
	return found
}

// reanchor returns the notes with every line moved to where its anchor is now. The
// record is left alone: this is what a reader sees, so a wrong guess is undone by the
// next read rather than written down.
func reanchor(root string, notes []json.RawMessage) []json.RawMessage {
	cache := lineCache{}
	moved := make([]json.RawMessage, 0, len(notes))
	for _, raw := range notes {
		var cur existing
		if err := json.Unmarshal(raw, &cur); err != nil || cur.File == nil || cur.Anchor == nil || cur.Line == nil {
			moved = append(moved, raw)
			continue
		}
		recorded, err := strconv.ParseInt(cur.Line.String(), 10, 64)
		if err != nil {
			moved = append(moved, raw)
			continue
		}
		lines := cache.lines(root, *cur.File)
		// The recorded line still reads the way it did, so nothing moved.
		if recorded >= 1 && int(recorded) <= len(lines) && anchorText(lines[recorded-1]) == *cur.Anchor {
			moved = append(moved, raw)
			continue
		}
		at := findAnchor(lines, *cur.Anchor)
		if at == 0 || at == recorded {
			moved = append(moved, raw)
			continue
		}
		var fields map[string]json.RawMessage
		if json.Unmarshal(raw, &fields) != nil {
			moved = append(moved, raw)
			continue
		}
		fields["line"] = json.RawMessage(strconv.FormatInt(at, 10))
		rewritten, err := json.Marshal(fields)
		if err != nil {
			moved = append(moved, raw)
			continue
		}
		moved = append(moved, rewritten)
	}
	return moved
}
