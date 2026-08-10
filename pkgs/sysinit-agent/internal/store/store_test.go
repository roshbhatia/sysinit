package store

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"testing"
)

type doc struct {
	Notes []map[string]any `json:"notes"`
}

func newStore(t *testing.T) *Store {
	t.Helper()
	return &Store{
		Path: filepath.Join(t.TempDir(), "sub", "store.json"),
		Validate: JSONValidator(func(d doc) error {
			if d.Notes == nil {
				return errors.New("notes must be an array")
			}
			return nil
		}),
		Initial: func() ([]byte, error) { return json.Marshal(doc{Notes: []map[string]any{}}) },
	}
}

// A zero-byte file is what an interrupted first write leaves behind. It must be
func TestReadTreatsZeroByteAsAbsent(t *testing.T) {
	s := newStore(t)
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(s.Path, nil, 0o644); err != nil {
		t.Fatal(err)
	}
	data, err := s.Read()
	if err != nil {
		t.Fatalf("read: %v", err)
	}
	if err := s.Validate(data); err != nil {
		t.Fatalf("initialized store did not validate: %v", err)
	}
}

// A non-empty store that does not parse holds the owner's data. Rebuilding it
func TestReadRefusesMalformed(t *testing.T) {
	s := newStore(t)
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(s.Path, []byte("{not json"), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Read(); !errors.Is(err, ErrMalformed) {
		t.Fatalf("want ErrMalformed, got %v", err)
	}
}

func TestPublishRefusesMalformed(t *testing.T) {
	s := newStore(t)
	if err := s.Publish([]byte(`{"notes": "not an array"}`)); err == nil {
		t.Fatal("published a malformed document")
	}
	if _, err := os.Stat(s.Path); !os.IsNotExist(err) {
		t.Fatal("a refused publish created the store anyway")
	}
}

// A symlinked store is the owner's layout choice. Replacing the link with a
func TestPublishRefusesSymlink(t *testing.T) {
	s := newStore(t)
	dir := filepath.Dir(s.Path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		t.Fatal(err)
	}
	target := filepath.Join(dir, "real.json")
	if err := os.WriteFile(target, []byte(`{"notes":[]}`), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(target, s.Path); err != nil {
		t.Fatal(err)
	}
	if err := s.Publish([]byte(`{"notes":[{"a":1}]}`)); !errors.Is(err, ErrSymlink) {
		t.Fatalf("want ErrSymlink, got %v", err)
	}
	got, err := os.ReadFile(target)
	if err != nil {
		t.Fatal(err)
	}
	if string(got) != `{"notes":[]}` {
		t.Fatalf("symlink target was modified: %s", got)
	}
}

// Read-modify-write with no lock was last-write-wins, and the losing run still
func TestLockSerializesWriters(t *testing.T) {
	s := newStore(t)
	const writers = 8
	var wg sync.WaitGroup
	for i := 0; i < writers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			release, err := s.Lock()
			if err != nil {
				t.Errorf("lock: %v", err)
				return
			}
			defer release()
			data, err := s.Read()
			if err != nil {
				t.Errorf("read: %v", err)
				return
			}
			var d doc
			if err := json.Unmarshal(data, &d); err != nil {
				t.Errorf("unmarshal: %v", err)
				return
			}
			d.Notes = append(d.Notes, map[string]any{"n": 1})
			out, err := json.Marshal(d)
			if err != nil {
				t.Errorf("marshal: %v", err)
				return
			}
			if err := s.Publish(out); err != nil {
				t.Errorf("publish: %v", err)
			}
		}()
	}
	wg.Wait()

	data, err := s.Read()
	if err != nil {
		t.Fatal(err)
	}
	var d doc
	if err := json.Unmarshal(data, &d); err != nil {
		t.Fatal(err)
	}
	if len(d.Notes) != writers {
		t.Fatalf("lost a write: got %d notes, want %d", len(d.Notes), writers)
	}
}

// Releasing twice must not remove a lock another holder has since taken.
func TestReleaseIsIdempotent(t *testing.T) {
	s := newStore(t)
	release, err := s.Lock()
	if err != nil {
		t.Fatal(err)
	}
	release()
	other, err := s.Lock()
	if err != nil {
		t.Fatalf("second acquire: %v", err)
	}
	release()
	if _, err := os.Stat(s.lockPath()); err != nil {
		t.Fatal("a stale release removed a lock it did not own")
	}
	other()
}

// Only the control byte is removed, which is what defangs an escape sequence:
func TestCleanKeepsNewlinesAndDropsControls(t *testing.T) {
	got := Clean("a\x07b\nc\x1b[31md")
	want := "ab\nc[31md"
	if got != want {
		t.Fatalf("Clean = %q, want %q", got, want)
	}
}

// Non-ASCII must survive. The shell original once used an escaped \uXXXX range
func TestCleanKeepsUnicode(t *testing.T) {
	got := Clean("héllo → wörld\x07")
	want := "héllo → wörld"
	if got != want {
		t.Fatalf("Clean = %q, want %q", got, want)
	}
}

func TestOneLineFoldsNewlines(t *testing.T) {
	got := OneLine("a\nb\x07c")
	want := "a bc"
	if got != want {
		t.Fatalf("OneLine = %q, want %q", got, want)
	}
}

// grep matches within a line, so a newline is a separator it can never match.
func TestHasControlBytesDetectsNewline(t *testing.T) {
	if !HasControlBytes("a\nb") {
		t.Fatal("newline not reported as a control byte")
	}
	if HasControlBytes("plain/path.txt") {
		t.Fatal("a real path reported as carrying a control byte")
	}
}
