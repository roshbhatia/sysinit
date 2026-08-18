package agentstate

import (
	"os"
	"path/filepath"
	"strconv"
	"testing"
)

// deadPID is a pid no process can hold: kill(0) on it always fails.
const deadPID = 0x7FFFFFF0

func write(t *testing.T, dir, name, body string) {
	t.Helper()
	if err := os.WriteFile(filepath.Join(dir, name), []byte(body), 0o644); err != nil {
		t.Fatal(err)
	}
}

func exists(dir, name string) bool {
	_, err := os.Stat(filepath.Join(dir, name))
	return err == nil
}

func TestReapDropsRecordsWithNoMuxID(t *testing.T) {
	dir := t.TempDir()
	self := os.Getpid()

	// What a mux-server GUI wrote: MuxID() saw a socket named "sock" and
	// returned 0, so nothing could ever attribute the record to a live GUI.
	write(t, dir, "23.json", `{"mux":0,"status":"done"}`)
	write(t, dir, "23.start", "1700000000")
	// Pre-dating the mux field entirely.
	write(t, dir, "24.json", `{"status":"done"}`)
	// A GUI that is gone.
	write(t, dir, "25.json", `{"mux":`+strconv.Itoa(deadPID)+`,"status":"done"}`)
	// This GUI.
	write(t, dir, "26.json", `{"mux":`+strconv.Itoa(self)+`,"status":"working"}`)

	reapDeadMuxes(dir, self, "26")

	for _, gone := range []string{"23.json", "23.start", "24.json", "25.json"} {
		if exists(dir, gone) {
			t.Errorf("%s survived the reap", gone)
		}
	}
	if !exists(dir, "26.json") {
		t.Error("26.json was reaped but its mux is this process")
	}
}

func TestReapKeepsTheCurrentPanesStartFile(t *testing.T) {
	dir := t.TempDir()
	self := os.Getpid()

	// `working submit` writes .start before it publishes the record, so the
	// reap runs while the current pane looks like an orphan.
	write(t, dir, "26.start", "1700000000")
	write(t, dir, "99.start", "1700000000")

	reapDeadMuxes(dir, self, "26")

	if !exists(dir, "26.start") {
		t.Error("the current pane's .start was reaped mid-turn")
	}
	if exists(dir, "99.start") {
		t.Error("an orphan .start survived")
	}
}

func TestReapClearsMarkersForDeadGUIs(t *testing.T) {
	dir := t.TempDir()
	self := os.Getpid()

	write(t, dir, markerPrefix+strconv.Itoa(deadPID), "")
	write(t, dir, markerPrefix+"notanumber", "")

	reapDeadMuxes(dir, self, "")

	if exists(dir, markerPrefix+strconv.Itoa(deadPID)) {
		t.Error("a marker for a dead GUI survived")
	}
	if !exists(dir, markerPrefix+strconv.Itoa(self)) {
		t.Error("the reap did not record its own marker")
	}
	if !exists(dir, markerPrefix+"notanumber") {
		t.Error("an unparseable marker was removed rather than left alone")
	}
}

func TestReapIsSkippedWithoutAMuxID(t *testing.T) {
	dir := t.TempDir()
	write(t, dir, "23.json", `{"mux":0,"status":"done"}`)

	// A caller with no mux id of its own cannot tell a dead GUI from its own,
	// so it must not delete anything.
	reapDeadMuxes(dir, 0, "23")

	if !exists(dir, "23.json") {
		t.Error("the reap deleted records while it had no mux id")
	}
}
