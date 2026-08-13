// Package fftabs prints the open Firefox tabs as JSON, for a launcher that lists them
// beside the applications. Firefox keeps them in a session store compressed with mozlz4,
// which is an LZ4 block behind an eight byte header, so the decoder is here rather than a
// dependency: this binary carries none.
package fftabs

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
)

// Summary is the one-line description the dispatcher prints.
const Summary = "print the open Firefox tabs as JSON"

// The header every mozlz4 file opens with.
var magic = []byte("mozLz40\x00")

// Tab is one open tab.
type Tab struct {
	Title string `json:"title"`
	URL   string `json:"url"`
}

// The shape of a session store, to the depth this needs.
type store struct {
	Windows []struct {
		Tabs []struct {
			// One-based, and the entry it names is the page the tab is showing; the
			// others are where it has been.
			Index   int `json:"index"`
			Entries []struct {
				URL   string `json:"url"`
				Title string `json:"title"`
			} `json:"entries"`
		} `json:"tabs"`
	} `json:"windows"`
}

// decompress expands one LZ4 block. The format is a sequence of sequences: a token whose
// high nibble counts literal bytes and whose low nibble counts matched bytes, each count
// extended by 255-terminated bytes when the nibble is full.
func decompress(src []byte, size int) ([]byte, error) {
	dst := make([]byte, 0, size)
	at := 0
	for at < len(src) {
		token := int(src[at])
		at++

		literals := token >> 4
		if literals == 15 {
			for {
				if at >= len(src) {
					return nil, errors.New("truncated literal length")
				}
				more := int(src[at])
				at++
				literals += more
				if more != 255 {
					break
				}
			}
		}
		if at+literals > len(src) {
			return nil, errors.New("truncated literals")
		}
		dst = append(dst, src[at:at+literals]...)
		at += literals

		// The last sequence carries literals and no match, so running out here is the
		// end of the block rather than a fault.
		if at+2 > len(src) {
			break
		}
		offset := int(binary.LittleEndian.Uint16(src[at:]))
		at += 2
		if offset == 0 || offset > len(dst) {
			return nil, fmt.Errorf("match offset %d outside %d bytes", offset, len(dst))
		}

		matched := token & 0xF
		if matched == 15 {
			for {
				if at >= len(src) {
					return nil, errors.New("truncated match length")
				}
				more := int(src[at])
				at++
				matched += more
				if more != 255 {
					break
				}
			}
		}
		// The minimum match is four bytes, which the token counts from.
		matched += 4

		// Byte at a time, because a match may overlap what it is still writing, which is
		// how the format expresses a run.
		from := len(dst) - offset
		for index := 0; index < matched; index++ {
			dst = append(dst, dst[from+index])
		}
	}
	return dst, nil
}

// read expands one mozlz4 file.
func read(path string) ([]byte, error) {
	raw, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	if len(raw) < len(magic)+4 {
		return nil, errors.New("shorter than a mozlz4 header")
	}
	if string(raw[:len(magic)]) != string(magic) {
		return nil, errors.New("not a mozlz4 file")
	}
	size := int(binary.LittleEndian.Uint32(raw[len(magic):]))
	return decompress(raw[len(magic)+4:], size)
}

// profiles are the session stores worth reading, newest first, so the window a reader was
// last in is the one whose tabs come first.
func profiles(root string) []string {
	entries, err := os.ReadDir(filepath.Join(root, "Profiles"))
	if err != nil {
		return nil
	}
	type found struct {
		path string
		when int64
	}
	var all []found
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		// Both the live store and the backup, because Firefox writes the live one only
		// on a clean exit and the backup is what a running Firefox keeps current.
		for _, name := range []string{
			filepath.Join(root, "Profiles", entry.Name(), "sessionstore-backups", "recovery.jsonlz4"),
			filepath.Join(root, "Profiles", entry.Name(), "sessionstore.jsonlz4"),
		} {
			info, err := os.Stat(name)
			if err == nil {
				all = append(all, found{path: name, when: info.ModTime().Unix()})
				break
			}
		}
	}
	sort.Slice(all, func(i, j int) bool { return all[i].when > all[j].when })
	paths := make([]string, 0, len(all))
	for _, entry := range all {
		paths = append(paths, entry.path)
	}
	return paths
}

// tabs are the open tabs of one session store.
func tabs(path string) ([]Tab, error) {
	raw, err := read(path)
	if err != nil {
		return nil, err
	}
	var decoded store
	if err := json.Unmarshal(raw, &decoded); err != nil {
		return nil, err
	}
	var found []Tab
	for _, window := range decoded.Windows {
		for _, tab := range window.Tabs {
			at := tab.Index - 1
			if at < 0 || at >= len(tab.Entries) {
				continue
			}
			entry := tab.Entries[at]
			if entry.URL == "" {
				continue
			}
			title := entry.Title
			if title == "" {
				title = entry.URL
			}
			found = append(found, Tab{Title: title, URL: entry.URL})
		}
	}
	return found, nil
}

// Run prints every open tab as JSON. It always exits zero with a list, because a launcher
// asks for this on every open and a missing or half-written store is not an error the
// reader can act on.
func Run(args []string) int {
	root := filepath.Join(os.Getenv("HOME"), "Library", "Application Support", "Firefox")
	if len(args) > 0 {
		root = args[0]
	}

	found := []Tab{}
	seen := map[string]bool{}
	for _, path := range profiles(root) {
		some, err := tabs(path)
		if err != nil {
			continue
		}
		for _, tab := range some {
			if seen[tab.URL] {
				continue
			}
			seen[tab.URL] = true
			found = append(found, tab)
		}
	}

	out, err := json.Marshal(found)
	if err != nil {
		fmt.Fprintln(os.Stdout, "[]")
		return 0
	}
	fmt.Fprintln(os.Stdout, string(out))
	return 0
}
