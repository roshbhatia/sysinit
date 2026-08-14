package store

import (
	"os"
	"path/filepath"
	"testing"
)

func TestARunIsReadBackAsItWasSaved(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())

	if err := SaveRun([]byte("piped in\n"), "what to do"); err != nil {
		t.Fatal(err)
	}
	if err := SaveOutput([]byte("what came back")); err != nil {
		t.Fatal(err)
	}

	for _, one := range []struct {
		name string
		read func() ([]byte, error)
		want string
	}{
		{"input", Input, "piped in\n"},
		{"prompt", Prompt, "what to do"},
		{"output", Output, "what came back"},
	} {
		got, err := one.read()
		if err != nil {
			t.Fatalf("%s: %v", one.name, err)
		}
		if string(got) != one.want {
			t.Errorf("%s is %q, want %q", one.name, got, one.want)
		}
	}
}

// What is piped into a model is as sensitive as the thing it was piped from, so neither the
// files nor the directory holding them may be readable by anyone else.
func TestTheLastRunIsReadableOnlyByItsOwner(t *testing.T) {
	base := t.TempDir()
	t.Setenv("XDG_STATE_HOME", base)

	if err := SaveRun([]byte("secret"), "prompt"); err != nil {
		t.Fatal(err)
	}

	dir, err := os.Stat(Dir())
	if err != nil {
		t.Fatal(err)
	}
	if got := dir.Mode().Perm(); got != 0o700 {
		t.Errorf("the directory is %04o, want 0700", got)
	}
	file, err := os.Stat(filepath.Join(Dir(), inputFile))
	if err != nil {
		t.Fatal(err)
	}
	if got := file.Mode().Perm(); got != 0o600 {
		t.Errorf("the input is %04o, want 0600", got)
	}
}

func TestNothingSavedIsAnErrorRatherThanAnEmptyAnswer(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", t.TempDir())

	if _, err := Input(); err == nil {
		t.Error("an unsaved input read back as empty")
	}
}

// The state directory rather than the cache one, because a rerun is worth surviving a cache
// sweep.
func TestTheRunIsKeptUnderTheStateDirectory(t *testing.T) {
	t.Setenv("XDG_STATE_HOME", "/somewhere/state")
	if got, want := Dir(), filepath.Join("/somewhere/state", "ask"); got != want {
		t.Errorf("the directory is %q, want %q", got, want)
	}

	t.Setenv("XDG_STATE_HOME", "")
	t.Setenv("HOME", "/home/someone")
	if got, want := Dir(), filepath.Join("/home/someone", ".local", "state", "ask"); got != want {
		t.Errorf("with no XDG_STATE_HOME the directory is %q, want %q", got, want)
	}
}
