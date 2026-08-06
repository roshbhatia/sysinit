// Package store holds the JSON-file state machine that diffnote.sh and
// citelock.sh each implemented in bash and jq.
//
// Every behavior here corresponds to a defect the shell versions paid for once.
// The comments name the defect rather than restating the code, and each one has
// a test. See ../../../../modules/home/programs/llm/runtime/diffnote.sh for the
// originals while the migration is in flight.
package store

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
	"unicode"
)

// Validator decides whether a candidate document is publishable. A store is
// only ever replaced by bytes that pass it, so a producer that dies mid-pipeline
// cannot leave a fragment behind.
type Validator func([]byte) error

var (
	// ErrMalformed is returned for a non-empty store that does not validate.
	// The notes in it belong to the owner, so this is never repaired silently.
	ErrMalformed = errors.New("store is not valid")
	// ErrSymlink is returned when the store path is a symlink. Replacing the
	// link with a regular file is what emptied the owner's real target.
	ErrSymlink = errors.New("store is a symlink")
	// ErrLockHeld is returned when the lock could not be taken in time.
	ErrLockHeld = errors.New("another process holds the store lock")
)

const (
	lockAttempts = 50
	lockInterval = 100 * time.Millisecond
)

// Store is one JSON document on disk, guarded by a lock directory beside it.
type Store struct {
	Path      string
	Validate  Validator
	// Initial produces the document written when the store is absent or empty.
	Initial func() ([]byte, error)
}

func (s *Store) lockPath() string { return s.Path + ".lock" }

// Lock takes the store's lock directory and returns the release function.
//
// mkdir is the primitive because it is atomic on every filesystem this runs on.
// The parent is created before the loop: creating it inside the acquire path
// made a first run fail for a missing parent and then report a held lock that
// had never existed.
func (s *Store) Lock() (func(), error) {
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		return nil, err
	}
	for attempt := 0; attempt < lockAttempts; attempt++ {
		err := os.Mkdir(s.lockPath(), 0o755)
		if err == nil {
			var released bool
			return func() {
				// Guarded against a double release. Between a release and a
				// re-acquire by another process, a second release would remove
				// a lock this process no longer owns.
				if released {
					return
				}
				released = true
				os.Remove(s.lockPath())
			}, nil
		}
		if !os.IsExist(err) {
			return nil, err
		}
		time.Sleep(lockInterval)
	}
	return nil, fmt.Errorf("%w: %s", ErrLockHeld, s.lockPath())
}

// Read returns the current document, initializing it when absent or zero-byte.
//
// A zero-byte file is what an interrupted first write leaves behind. Testing
// only for existence made that state absorbing: jq on an empty file exits 0 with
// no output, so every later write reported success and stored nothing, forever.
func (s *Store) Read() ([]byte, error) {
	data, err := os.ReadFile(s.Path)
	if err != nil && !os.IsNotExist(err) {
		return nil, err
	}
	if len(data) == 0 {
		if s.Initial == nil {
			return nil, ErrMalformed
		}
		return s.Initial()
	}
	if err := s.Validate(data); err != nil {
		return nil, fmt.Errorf("%w: %s: %v", ErrMalformed, s.Path, err)
	}
	return data, nil
}

// Publish replaces the store with data, atomically, after validating it.
//
// Validation happens before the rename rather than after, because the previous
// contents are the fallback and a rename cannot be undone.
func (s *Store) Publish(data []byte) error {
	if err := s.Validate(data); err != nil {
		return fmt.Errorf("refusing to publish a malformed store: %w", err)
	}
	// Lstat, not Stat: Stat follows the link and reports the target, which is
	// exactly the case being refused.
	if info, err := os.Lstat(s.Path); err == nil && info.Mode()&os.ModeSymlink != 0 {
		target, _ := os.Readlink(s.Path)
		return fmt.Errorf("%w: %s -> %s", ErrSymlink, s.Path, target)
	}
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(filepath.Dir(s.Path), filepath.Base(s.Path)+".*")
	if err != nil {
		return err
	}
	name := tmp.Name()
	defer os.Remove(name)
	if _, err := tmp.Write(data); err != nil {
		tmp.Close()
		return err
	}
	// Synced before the rename. Without it a crash between rename and flush can
	// leave a correctly-named file with no contents, which is the zero-byte
	// absorbing state this package exists to avoid.
	if err := tmp.Sync(); err != nil {
		tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(name, s.Path)
}

// JSONValidator builds a Validator asserting the document parses and satisfies
// check. Callers supply check because the document shape is theirs, not ours.
func JSONValidator[T any](check func(T) error) Validator {
	return func(data []byte) error {
		var doc T
		if err := json.Unmarshal(data, &doc); err != nil {
			return err
		}
		if check == nil {
			return nil
		}
		return check(doc)
	}
}

// Clean strips control bytes while preserving newlines, for a field whose
// contract allows multiple lines.
//
// Stripping happens once, on the way in, so neither a terminal rendering `list`
// nor the editor has to defend itself against an escape sequence.
func Clean(s string) string {
	return strings.Map(func(r rune) rune {
		if r == '\n' {
			return r
		}
		if unicode.IsControl(r) {
			return -1
		}
		return r
	}, s)
}

// OneLine folds newlines to spaces and strips every other control byte, for a
// field that is one line by contract.
//
// A newline here is the case that forged a whole extra row in `diffnote list`.
func OneLine(s string) string {
	return strings.Map(func(r rune) rune {
		if r == '\n' {
			return ' '
		}
		if unicode.IsControl(r) {
			return -1
		}
		return r
	}, s)
}

// HasControlBytes reports whether s carries any control byte, newline included.
//
// A path is rejected rather than cleaned: cleaning would key the record on a
// path the caller did not name, and no real path carries a control byte.
func HasControlBytes(s string) bool {
	return strings.ContainsFunc(s, unicode.IsControl)
}
