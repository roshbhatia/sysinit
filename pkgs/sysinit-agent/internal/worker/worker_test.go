package worker

import (
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

// state points the paths manifest at a temporary tree and returns the directory
// `worker` keys its records under. Both keys are set: seshySessions has to be a
// path the temporary workspace is NOT inside, or Workspace would key on a session
// prefix instead of on the directory under test.
func state(t *testing.T) string {
	t.Helper()
	home := t.TempDir()
	manifest := filepath.Join(home, "paths.json")
	body, err := json.Marshal(map[string]any{
		"version": 1,
		"paths": map[string]string{
			"agentWorker":   filepath.Join(home, "worker"),
			"agentPanes":    filepath.Join(home, "panes"),
			"seshySessions": filepath.Join(home, "no-sessions-here"),
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(manifest, body, 0o600); err != nil {
		t.Fatal(err)
	}
	t.Setenv("SYSINIT_PATHS_MANIFEST", manifest)
	return filepath.Join(home, "worker")
}

// fakeMux replaces both mux calls. panes is the set of live pane ids; sent
// collects every line typed into a pane.
type fakeMux struct {
	panes   []int
	split   int
	sent    []string
	actions []string
	fail    bool
}

func (f *fakeMux) install(t *testing.T) {
	t.Helper()
	realOutput, realRun := muxOutput, muxRun
	t.Cleanup(func() { muxOutput, muxRun = realOutput, realRun })

	muxOutput = func(args []string) (string, error) {
		if f.fail {
			return "", os.ErrDeadlineExceeded
		}
		switch {
		case len(args) > 1 && args[1] == "list":
			type pane struct {
				PaneID int `json:"pane_id"`
			}
			list := make([]pane, 0, len(f.panes))
			for _, id := range f.panes {
				list = append(list, pane{PaneID: id})
			}
			out, _ := json.Marshal(list)
			return string(out), nil
		case len(args) > 1 && args[1] == "split-pane":
			f.panes = append(f.panes, f.split)
			return "\n" + strconv.Itoa(f.split) + "\n", nil
		}
		return "", nil
	}
	muxRun = func(args []string, stdin string) error {
		if f.fail {
			return os.ErrDeadlineExceeded
		}
		f.actions = append(f.actions, strings.Join(args, " "))
		if stdin != "" {
			f.sent = append(f.sent, stdin)
		}
		return nil
	}
}

// fast shrinks the two waits so a timeout test costs milliseconds.
func fast(t *testing.T) {
	t.Helper()
	realPoll, realSettle := pollInterval, settle
	t.Cleanup(func() { pollInterval, settle = realPoll, realSettle })
	pollInterval, settle = time.Millisecond, 0
}

// 1. No WEZTERM_PANE: refuse before touching anything.
func TestRefusesOutsideWezTerm(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "")
	if code := Run([]string{"true"}); code != 2 {
		t.Errorf("Run outside wezterm = %d, want 2", code)
	}
}

// 2. A recorded pane that is gone is not addressed; a fresh one is split.
func TestDeadRecordedPaneIsReplaced(t *testing.T) {
	dir := state(t)
	t.Setenv("WEZTERM_PANE", "7")
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	ws := newWorkspace(t.TempDir())
	if err := os.MkdirAll(ws.dir, 0o700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(ws.paneFile(), []byte("404\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	if _, err := ws.pane("7"); err == nil {
		t.Fatal("a dead recorded pane was accepted")
	}
	if got, err := ws.split("7"); err != nil || got != "9" {
		t.Fatalf("split = %q, %v; want \"9\", nil", got, err)
	}
	body, err := os.ReadFile(ws.paneFile())
	if err != nil || strings.TrimSpace(string(body)) != "9" {
		t.Errorf("pane file = %q, %v; want 9", body, err)
	}
	if !strings.HasPrefix(ws.dir, dir) {
		t.Errorf("record %q is not under the manifest directory %q", ws.dir, dir)
	}
}

// 3. The caller's own pane is never addressed, even when it is alive and
// recorded: sending to it would race the caller's own shell.
func TestRefusesToAddressTheCallingPane(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)

	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)
	os.WriteFile(ws.paneFile(), []byte("7\n"), 0o600)

	_, err := ws.pane("7")
	if err == nil || !strings.Contains(err.Error(), "calling pane") {
		t.Errorf("pane() = %v, want a refusal naming the calling pane", err)
	}
}

// A recorded id from an earlier mux generation is rejected rather than reused.
// Pane ids restart at 0 when the mux restarts, so the id is live and wrong.
func TestRejectsAPaneFromAnEarlierMuxGeneration(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/gui-sock-4242")
	mux := &fakeMux{panes: []int{1}}
	mux.install(t)

	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)
	os.WriteFile(ws.paneFile(), []byte("1\n"), 0o600)
	os.WriteFile(ws.muxFile(), []byte("99\n"), 0o600)

	_, err := ws.pane("7")
	if err == nil || !strings.Contains(err.Error(), "mux 99") {
		t.Errorf("pane() = %v, want a rejection naming the recorded mux", err)
	}

	// The same record in the generation that wrote it is usable.
	os.WriteFile(ws.muxFile(), []byte("4242\n"), 0o600)
	if got, err := ws.pane("7"); err != nil || got != "1" {
		t.Errorf("pane() in its own generation = %q, %v; want \"1\", nil", got, err)
	}
}

// An unresponsive mux fails the call instead of hanging it.
func TestAnUnresponsiveMuxFailsRatherThanHangs(t *testing.T) {
	state(t)
	mux := &fakeMux{fail: true}
	mux.install(t)

	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)
	os.WriteFile(ws.paneFile(), []byte("3\n"), 0o600)

	if _, err := ws.pane("7"); err == nil {
		t.Error("a mux that did not answer was treated as answering")
	}
}

// 4. The caller's directory is checked before anything is sent.
func TestARemovedWorkingDirectoryStopsTheCall(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "7")
	gone := filepath.Join(t.TempDir(), "gone")
	if err := os.MkdirAll(gone, 0o700); err != nil {
		t.Fatal(err)
	}
	t.Chdir(gone)
	if err := os.RemoveAll(gone); err != nil {
		t.Fatal(err)
	}
	if _, err := callerDir(); err == nil {
		t.Error("a removed working directory was accepted")
	}
}

// 5 and 6. The generated body checks the directory again at run time, and a
// directory whose name needs quoting survives the round trip. Both are proved by
// running the body, because the defect they replace was a body that parsed.
func TestTheGeneratedBodyChecksItsDirectoryAndQuotesIt(t *testing.T) {
	if _, err := exec.LookPath("zsh"); err != nil {
		t.Skip("no zsh")
	}
	state(t)
	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)

	awkward := filepath.Join(t.TempDir(), "a dir with 'quotes' and spaces")
	if err := os.MkdirAll(awkward, 0o700); err != nil {
		t.Fatal(err)
	}

	body := ws.bodyFile("run1")
	if err := ws.writeBody(body, "run1", awkward, "pwd"); err != nil {
		t.Fatal(err)
	}
	out, err := exec.Command("zsh", body).CombinedOutput()
	if err != nil {
		t.Fatalf("body failed: %v\n%s", err, out)
	}
	if !strings.Contains(string(out), awkward) {
		t.Errorf("body ran in the wrong directory:\n%s", out)
	}
	if code := readRC(t, ws, "run1"); code != "0" {
		t.Errorf("exit code = %q, want 0", code)
	}

	// Now remove the directory and re-run the same body: it must refuse rather
	// than fall through and run the command wherever the pane happens to be.
	os.RemoveAll(awkward)
	os.Remove(ws.rcFile("run1"))
	out, err = exec.Command("zsh", body).CombinedOutput()
	if err == nil {
		t.Errorf("body ran with its directory gone:\n%s", out)
	}
	if !strings.Contains(string(out), "is gone") {
		t.Errorf("body did not say the directory is gone:\n%s", out)
	}
	if code := readRC(t, ws, "run1"); code != "2" {
		t.Errorf("exit code with the directory gone = %q, want 2", code)
	}
}

// An interrupted run still records an exit code, so its name is not burned. This
// is the case the superseded script lost: the tail of a `;` list does not run
// when zsh abandons the list on a signal.
func TestAnInterruptedRunStillRecordsAnExitCode(t *testing.T) {
	if _, err := exec.LookPath("zsh"); err != nil {
		t.Skip("no zsh")
	}
	state(t)
	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)

	body := ws.bodyFile("run1")
	if err := ws.writeBody(body, "run1", t.TempDir(), "kill -INT $$; sleep 5"); err != nil {
		t.Fatal(err)
	}
	exec.Command("zsh", body).Run()

	if code := readRC(t, ws, "run1"); code != "130" {
		t.Errorf("interrupted run recorded %q, want 130", code)
	}
	if _, err := os.Stat(ws.runningFile()); err == nil {
		t.Error("the running marker survived an interrupted run")
	}
	if ws.inFlight("run1") {
		t.Error("an interrupted run left its name burned")
	}
}

// 7. A number-taking flag rejects a flag name before any pane is created.
func TestNumericFlagsRejectAFlagWhereANumberBelongs(t *testing.T) {
	if _, err := parse([]string{"-w", "-t", "900", "true"}); err == nil {
		t.Error("-w accepted \"-t\" as a wait")
	}
	if _, err := parse([]string{"-t", "abc", "true"}); err == nil {
		t.Error("-t accepted a non-number")
	}
	if _, err := parse([]string{"-w", "-5", "true"}); err == nil {
		t.Error("-w accepted a negative wait")
	}
	if _, err := parse([]string{"-w"}); err == nil {
		t.Error("-w accepted a missing value")
	}
	if _, err := parse([]string{"--nope", "true"}); err == nil {
		t.Error("an unknown flag was accepted")
	}
	if _, err := parse([]string{"one", "two"}); err == nil {
		t.Error("a second command was accepted")
	}
	opts, err := parse([]string{"-w", "900", "-t", "5", "-n", "build", "nix build"})
	if err != nil {
		t.Fatal(err)
	}
	if opts.wait == nil || *opts.wait != 900 || opts.tail != 5 || opts.name != "build" || opts.command != "nix build" {
		t.Errorf("parse = %+v, want wait 900, tail 5, name build, command \"nix build\"", opts)
	}
}

// 8. A name whose previous run recorded no exit code is refused, and --release
// frees it without discarding any other run's log.
func TestANameInFlightIsRefusedAndReleasableAlone(t *testing.T) {
	state(t)
	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)

	os.WriteFile(ws.logFile("build"), []byte("half a log\n"), 0o600)
	os.WriteFile(ws.logFile("other"), []byte("someone else's log\n"), 0o600)
	os.WriteFile(ws.rcFile("other"), []byte("0\n"), 0o600)

	if !ws.inFlight("build") {
		t.Fatal("a log with no exit code did not read as in flight")
	}
	if ws.inFlight("other") {
		t.Error("a finished run read as in flight")
	}
	if ws.inFlight("never-ran") {
		t.Error("a name with no log read as in flight")
	}

	if code := ws.release("build"); code != 0 {
		t.Errorf("release = %d, want 0", code)
	}
	if ws.inFlight("build") {
		t.Error("release left the name burned")
	}
	if _, err := os.Stat(ws.logFile("other")); err != nil {
		t.Error("release discarded another run's log")
	}

	// The running run is not releasable: that would orphan its output.
	os.WriteFile(ws.logFile("live"), []byte("running\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("live\n"), 0o600)
	if code := ws.release("live"); code != 2 {
		t.Errorf("release of the running run = %d, want 2", code)
	}
	if _, err := os.Stat(ws.logFile("live")); err != nil {
		t.Error("release removed the running run's log anyway")
	}
}

// A run name has to stay inside the workspace's directory.
func TestARunNameIsOnePathElement(t *testing.T) {
	for _, name := range []string{"", "..", ".", "../etc/passwd", "a/b", `a\b`} {
		if err := validRunName(name); err == nil {
			t.Errorf("run name %q was accepted", name)
		}
	}
	if err := validRunName("run1"); err != nil {
		t.Errorf("run1 was rejected: %v", err)
	}
}

// Two workspaces never share a record, which is the whole point of the key.
func TestEachWorkspaceKeysItsOwnRecord(t *testing.T) {
	state(t)
	a := newWorkspace(t.TempDir())
	b := newWorkspace(t.TempDir())
	if a.dir == b.dir {
		t.Errorf("two workspaces keyed to one record: %q", a.dir)
	}
	if newWorkspace(a.root).dir != a.dir {
		t.Error("one workspace keyed to two records across calls")
	}
}

// The explicit key override takes a private worker under a name the caller
// chooses, and a name that would escape the state root is refused rather than
// used.
func TestTheSessionOverrideTakesAPrivateWorker(t *testing.T) {
	root := state(t)
	dir := t.TempDir()

	derived := newWorkspace(dir)

	t.Setenv(sessionOverride, "build")
	override := newWorkspace(dir)
	if override.dir != filepath.Join(root, "build") {
		t.Errorf("override keyed to %q, want %q", override.dir, filepath.Join(root, "build"))
	}
	if override.dir == derived.dir {
		t.Error("the override resolved to the derived key")
	}

	// Two callers in different workspaces share one override, which is the point
	// of the hatch: the name is the key.
	if newWorkspace(t.TempDir()).dir != override.dir {
		t.Error("the override did not out-rank the workspace")
	}

	// A traversal is refused and the derived key is used instead.
	t.Setenv(sessionOverride, "../escape")
	if got := newWorkspace(dir); got.dir != derived.dir {
		t.Errorf("a traversing override keyed to %q, want the derived %q", got.dir, derived.dir)
	}

	// Whitespace-only is not a name.
	t.Setenv(sessionOverride, "   ")
	if got := newWorkspace(dir); got.dir != derived.dir {
		t.Errorf("a blank override keyed to %q, want the derived %q", got.dir, derived.dir)
	}
}

// A wait returns the run's own exit code, and a wait that expires returns the
// timeout code and names the file to poll.
func TestWaitReturnsTheRunsCodeOrTheTimeoutCode(t *testing.T) {
	state(t)
	fast(t)
	ws := newWorkspace(t.TempDir())
	os.MkdirAll(ws.dir, 0o700)

	os.WriteFile(ws.logFile("run1"), []byte("output\n"), 0o600)
	os.WriteFile(ws.rcFile("run1"), []byte("3\n"), 0o600)
	if code := ws.waitForExit("run1", 1, 5); code != 3 {
		t.Errorf("wait = %d, want the run's own code 3", code)
	}

	os.WriteFile(ws.logFile("run2"), []byte("output\n"), 0o600)
	if code := ws.waitForExit("run2", 1, 5); code != timedOut {
		t.Errorf("expired wait = %d, want %d", code, timedOut)
	}
}

func readRC(t *testing.T, ws *workspace, name string) string {
	t.Helper()
	body, err := os.ReadFile(ws.rcFile(name))
	if err != nil {
		t.Fatalf("no exit code recorded for %s: %v", name, err)
	}
	return strings.TrimSpace(string(body))
}
