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

const Summary = "print the open Firefox tabs as JSON"

var magic = []byte("mozLz40\x00")

type Tab struct {
	Title string `json:"title"`
	URL   string `json:"url"`
}

type store struct {
	Windows []struct {
		Tabs []struct {
			Index   int `json:"index"`
			Entries []struct {
				URL   string `json:"url"`
				Title string `json:"title"`
			} `json:"entries"`
		} `json:"tabs"`
	} `json:"windows"`
}

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

		matched += 4

		from := len(dst) - offset
		for index := 0; index < matched; index++ {
			dst = append(dst, dst[from+index])
		}
	}
	return dst, nil
}

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
		if _, writeErr := fmt.Fprintln(os.Stdout, "[]"); writeErr != nil {
			return 1
		}
		return 0
	}
	if _, err := fmt.Fprintln(os.Stdout, string(out)); err != nil {
		return 1
	}
	return 0
}
