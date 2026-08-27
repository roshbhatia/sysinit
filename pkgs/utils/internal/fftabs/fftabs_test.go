package fftabs

import (
	"encoding/binary"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func literalBlock(data []byte) []byte {
	length := len(data)
	block := []byte{byte(min(length, 15) << 4)}
	if length >= 15 {
		remaining := length - 15
		for remaining >= 255 {
			block = append(block, 255)
			remaining -= 255
		}
		block = append(block, byte(remaining))
	}
	return append(block, data...)
}

func writeSession(t *testing.T, path, body string) {
	t.Helper()
	raw := append([]byte{}, magic...)
	size := make([]byte, 4)
	binary.LittleEndian.PutUint32(size, uint32(len(body)))
	raw = append(raw, size...)
	raw = append(raw, literalBlock([]byte(body))...)
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(path, raw, 0o600); err != nil {
		t.Fatal(err)
	}
}

func TestTabsReadsActiveEntries(t *testing.T) {
	path := filepath.Join(t.TempDir(), "sessionstore.jsonlz4")
	writeSession(t, path, `{"windows":[{"tabs":[{"index":2,"entries":[{"url":"old"},{"url":"new","title":"New"}]},{"index":1,"entries":[{"url":"untitled"}]}]}]}`)
	got, err := tabs(path)
	if err != nil {
		t.Fatalf("tabs: %v", err)
	}
	if len(got) != 2 || got[0] != (Tab{Title: "New", URL: "new"}) || got[1] != (Tab{Title: "untitled", URL: "untitled"}) {
		t.Fatalf("tabs = %+v", got)
	}
}

func TestProfilesPreferRecentRecovery(t *testing.T) {
	root := t.TempDir()
	older := filepath.Join(root, "Profiles", "older", "sessionstore.jsonlz4")
	newer := filepath.Join(root, "Profiles", "newer", "sessionstore-backups", "recovery.jsonlz4")
	writeSession(t, older, `{}`)
	writeSession(t, newer, `{}`)
	now := time.Now()
	if err := os.Chtimes(older, now.Add(-time.Hour), now.Add(-time.Hour)); err != nil {
		t.Fatal(err)
	}
	if err := os.Chtimes(newer, now, now); err != nil {
		t.Fatal(err)
	}
	got := profiles(root)
	if len(got) != 2 || got[0] != newer || got[1] != older {
		t.Fatalf("profiles = %v", got)
	}
}

func TestReadRejectsInvalidData(t *testing.T) {
	path := filepath.Join(t.TempDir(), "bad.jsonlz4")
	if err := os.WriteFile(path, []byte("not mozlz4"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := read(path); err == nil {
		t.Fatal("read accepted an invalid header")
	}
	if _, err := decompress([]byte{0, 1, 0}, 4); err == nil {
		t.Fatal("decompress accepted an invalid offset")
	}
}
