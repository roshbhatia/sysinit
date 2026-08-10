// Package store holds the JSON-file state machine that diffnote.sh and
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

// Validator decides whether a candidate document is publishable.
type Validator func([]byte) error

var (
	ErrMalformed = errors.New("store is not valid")
	ErrSymlink   = errors.New("store is a symlink")
	ErrLockHeld  = errors.New("another process holds the store lock")
)

const (
	lockAttempts = 50
	lockInterval = 100 * time.Millisecond
)

// Store is one JSON document on disk, guarded by a lock directory beside it.
type Store struct {
	Path     string
	Validate Validator
	Initial  func() ([]byte, error)
}

func (s *Store) lockPath() string { return s.Path + ".lock" }

// Lock takes the store's lock directory and returns the release function.
func (s *Store) Lock() (func(), error) {
	if err := os.MkdirAll(filepath.Dir(s.Path), 0o755); err != nil {
		return nil, err
	}
	for attempt := 0; attempt < lockAttempts; attempt++ {
		err := os.Mkdir(s.lockPath(), 0o755)
		if err == nil {
			var released bool
			return func() {
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
		return nil, fmt.Errorf("%w: %s: %w", ErrMalformed, s.Path, err)
	}
	return data, nil
}

// Publish replaces the store with data, atomically, after validating it.
func (s *Store) Publish(data []byte) error {
	if err := s.Validate(data); err != nil {
		return fmt.Errorf("refusing to publish a malformed store: %w", err)
	}
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
func HasControlBytes(s string) bool {
	return strings.ContainsFunc(s, unicode.IsControl)
}
