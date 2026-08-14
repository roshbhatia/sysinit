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

const maxAnchor = 200

func newID() (string, error) {
	raw := make([]byte, 4)
	if _, err := rand.Read(raw); err != nil {
		return "", err
	}
	return hex.EncodeToString(raw), nil
}

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

func anchorText(line string) string {
	return clipRunes(store.OneLine(strings.TrimSpace(line)), maxAnchor)
}

func clipRunes(text string, limit int) string {
	runes := []rune(text)
	if len(runes) <= limit {
		return text
	}
	return string(runes[:limit])
}

func captureAnchor(root, relative string, line int64) string {
	lines := lineCache{}.lines(root, relative)
	if line < 1 || int(line) > len(lines) {
		return ""
	}
	return anchorText(lines[line-1])
}

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
