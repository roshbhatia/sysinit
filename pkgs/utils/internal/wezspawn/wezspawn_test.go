package wezspawn

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

type mux struct {
	dir string
}

func stub(t *testing.T, clients, panes string) *mux {
	t.Helper()
	dir := t.TempDir()

	script := fmt.Sprintf(`#!/bin/sh
case "$2" in
  list-clients) printf '%%s' '%[2]s' ;;
  list)         printf '%%s' '%[3]s' ;;
  spawn)        echo "$@" > %[1]s/spawn.txt; echo 42 ;;
esac
`, dir, clients, panes)
	path := filepath.Join(dir, "wezterm")
	if err := os.WriteFile(path, []byte(script), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))
	return &mux{dir: dir}
}

func (m *mux) spawned(t *testing.T) string {
	t.Helper()
	data, err := os.ReadFile(filepath.Join(m.dir, "spawn.txt"))
	if err != nil {
		t.Fatalf("nothing was spawned: %v", err)
	}
	return strings.TrimSpace(string(data))
}

func clientsFor(workspace string, pane int) string {
	return fmt.Sprintf(`[{"workspace":%q,"focused_pane_id":%d}]`, workspace, pane)
}

func panesFor(pane int, cwd string) string {
	return fmt.Sprintf(`[{"pane_id":%d,"cwd":"file://somehost%s"}]`, pane, cwd)
}

func TestTheWindowJoinsTheFocusedWorkspaceAndDirectory(t *testing.T) {
	dir := t.TempDir()
	m := stub(t, clientsFor("fra-region-spin-up", 23), panesFor(23, dir))
	if code := Run(nil); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	for _, want := range []string{"--new-window", "--workspace fra-region-spin-up", "--cwd " + dir} {
		if got := m.spawned(t); !strings.Contains(got, want) {
			t.Errorf("spawn is missing %q:\n%s", want, got)
		}
	}
}

func TestADirectoryThatIsNotHereIsLeftOff(t *testing.T) {
	m := stub(t, clientsFor("laurel", 4), panesFor(4, "/not/a/directory/here"))
	if code := Run(nil); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	got := m.spawned(t)
	if strings.Contains(got, "--cwd") {
		t.Errorf("a path that does not exist here was still passed:\n%s", got)
	}
	if !strings.Contains(got, "--workspace laurel") {
		t.Errorf("the workspace was dropped along with the path:\n%s", got)
	}
}

func TestAnUnlistedFocusedPaneStillPicksTheWorkspace(t *testing.T) {
	m := stub(t, clientsFor("default", 99), panesFor(23, t.TempDir()))
	if code := Run(nil); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	got := m.spawned(t)
	if strings.Contains(got, "--cwd") {
		t.Errorf("a pane that was not listed still produced a directory:\n%s", got)
	}
	if !strings.Contains(got, "--workspace default") {
		t.Errorf("spawn = %s", got)
	}
}

func TestNoClientStillSpawnsAWindow(t *testing.T) {
	m := stub(t, "[]", "[]")
	if code := Run(nil); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	got := m.spawned(t)
	if !strings.Contains(got, "--new-window") {
		t.Errorf("spawn = %s", got)
	}
	if strings.Contains(got, "--workspace") || strings.Contains(got, "--cwd") {
		t.Errorf("nothing was known, yet the spawn named something:\n%s", got)
	}
}

func TestAProgramRunsInsteadOfTheShell(t *testing.T) {
	m := stub(t, clientsFor("default", 1), "[]")
	if code := Run([]string{"nvim", "-R"}); code != 0 {
		t.Fatalf("Run exited %d", code)
	}
	if got := m.spawned(t); !strings.Contains(got, "-- nvim -R") {
		t.Errorf("spawn is missing the program:\n%s", got)
	}
}

func TestHelpIsNotASpawn(t *testing.T) {
	m := stub(t, clientsFor("default", 1), "[]")
	if code := Run([]string{"--help"}); code != 0 {
		t.Errorf("--help exited %d", code)
	}
	if _, err := os.Stat(filepath.Join(m.dir, "spawn.txt")); err == nil {
		t.Error("--help opened a window")
	}
}

func TestANamedBinaryIsDrivenInsteadOfThePathOne(t *testing.T) {
	m := stub(t, clientsFor("laurel", 3), "[]")
	named := filepath.Join(m.dir, "wezterm")
	t.Setenv("PATH", t.TempDir())

	if code := Run([]string{"--wezterm", named}); code != 0 {
		t.Fatalf("Run exited %d with no wezterm on PATH", code)
	}
	if got := m.spawned(t); !strings.Contains(got, "--workspace laurel") {
		t.Errorf("spawn = %s", got)
	}
	if code := Run([]string{"--wezterm"}); code != 2 {
		t.Errorf("--wezterm with no path exited %d, want 2", code)
	}
}

func TestAMuxCallIsBounded(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "wezterm"), []byte("#!/bin/sh\nsleep 30\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", dir+string(os.PathListSeparator)+os.Getenv("PATH"))

	real := muxTimeout
	t.Cleanup(func() { muxTimeout = real })
	muxTimeout = 150 * time.Millisecond

	started := time.Now()
	if code := Run(nil); code != 1 {
		t.Errorf("a mux that never answered exited %d, want 1", code)
	}
	if elapsed := time.Since(started); elapsed > 3*time.Second {
		t.Errorf("took %s, so the calls were not bounded", elapsed)
	}
}
