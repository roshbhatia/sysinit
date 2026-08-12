package worker

import (
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"syscall"
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
	// A record is only usable inside the mux generation that wrote it, so every
	// test that reads one needs a generation to be in.
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/gui-sock-4242")
	return filepath.Join(home, "worker")
}

// workspaceIn resolves a record and fails the test if it cannot, which is what
// every caller here wants.
func workspaceIn(t *testing.T, dir string) *workspace {
	t.Helper()
	ws, err := newWorkspace(dir)
	if err != nil {
		t.Fatalf("newWorkspace(%q): %v", dir, err)
	}
	if err := os.MkdirAll(ws.dir, 0o700); err != nil {
		t.Fatal(err)
	}
	return ws
}

// live records a usable worker pane in the current generation.
func (w *workspace) live(t *testing.T, id string) {
	t.Helper()
	if err := os.WriteFile(w.paneFile(), []byte(id+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(w.muxFile(), []byte(currentMux()+"\n"), 0o600); err != nil {
		t.Fatal(err)
	}
}

// fakeMux replaces both mux calls. panes is the set of live pane ids; sent
// collects every line typed into a pane.
type fakeMux struct {
	panes    []int
	split    int
	sent     []string
	actions  []string
	fail     bool
	listFail bool
	sendFail bool
	killFail bool
}

func (f *fakeMux) install(t *testing.T) {
	t.Helper()
	realOutput, realRun := muxOutput, muxRun
	t.Cleanup(func() { muxOutput, muxRun = realOutput, realRun })

	muxOutput = func(args []string) (string, error) {
		if f.fail {
			return "", os.ErrDeadlineExceeded
		}
		// Recorded here too, not only in muxRun. `split-pane` goes through this call, so
		// while it was recorded in one place the "nothing was split" assertions could
		// never fire: they scanned a slice that split-pane never reached.
		f.actions = append(f.actions, strings.Join(args, " "))
		switch {
		case len(args) > 1 && args[1] == "list":
			if f.listFail {
				return "", os.ErrDeadlineExceeded
			}
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
		joined := strings.Join(args, " ")
		if f.fail ||
			(f.sendFail && strings.Contains(joined, "send-text")) ||
			(f.killFail && strings.Contains(joined, "kill-pane")) {
			return os.ErrDeadlineExceeded
		}
		f.actions = append(f.actions, joined)
		if stdin != "" {
			f.sent = append(f.sent, stdin)
		}
		return nil
	}
}

// split reports how many panes the fake was asked to create, so a test can say
// "nothing was split" about the call rather than about a helper.
func (f *fakeMux) splits() int {
	n := 0
	for _, action := range f.actions {
		if strings.Contains(action, "split-pane") {
			n++
		}
	}
	return n
}

// typed returns the line sent to a pane, and the pane it was sent to. Every
// declared output line and the sent line itself are parity contracts, so they are
// asserted rather than assumed: without this the target could be hardcoded and the
// suite stayed green.
func (f *fakeMux) typed(t *testing.T) (target, line string) {
	t.Helper()
	for _, action := range f.actions {
		if !strings.Contains(action, "send-text") {
			continue
		}
		words := strings.Fields(action)
		for i, word := range words {
			if word == "--pane-id" && i+1 < len(words) {
				target = words[i+1]
			}
		}
	}
	if target == "" {
		t.Fatalf("nothing was sent to any pane; actions = %v", f.actions)
	}
	if len(f.sent) != 1 {
		t.Fatalf("lines typed = %d, want exactly 1: %v", len(f.sent), f.sent)
	}
	return target, f.sent[0]
}

// captured collects what fn prints on stdout. The one line every ordinary
// invocation prints, and the three --status forms, are declared behaviour, and a
// suite with no output assertion at all let every one of them be deleted.
func captured(t *testing.T, fn func()) string {
	t.Helper()
	real := os.Stdout
	read, write, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	os.Stdout = write
	done := make(chan string, 1)
	go func() {
		var collected strings.Builder
		io.Copy(&collected, read)
		done <- collected.String()
	}()
	fn()
	write.Close()
	os.Stdout = real
	out := <-done
	read.Close()
	return out
}

// fast shrinks the two waits so a timeout test costs milliseconds.
func fast(t *testing.T) {
	t.Helper()
	realPoll, realSettle := pollInterval, settle
	t.Cleanup(func() { pollInterval, settle = realPoll, realSettle })
	pollInterval, settle = time.Millisecond, 0
}

// The reason this package exists: a live worker recorded by ANOTHER pane is
// reused, and the command goes to it.
//
// This is the whole reuse contract, and it had no test. Every other test that
// called `start` drove a failure path or the errSelf split, so an implementation
// that split a second worker beside a live one, or that sent every command to a
// hardcoded pane, passed the suite.
func TestALiveWorkerRecordedByAnotherPaneIsReused(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{7, 12}, split: 99}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	dir := t.TempDir()

	var code int
	out := captured(t, func() { code = ws.start("7", dir, options{tail: 20, command: "true"}) })
	if code != 0 {
		t.Fatalf("start against a live worker = %d, want 0", code)
	}
	if n := mux.splits(); n != 0 {
		t.Errorf("panes split = %d, want 0: the live worker was recorded and alive", n)
	}

	target, line := mux.typed(t)
	if target != "12" {
		t.Errorf("the command went to pane %s, want the recorded worker 12", target)
	}
	if !strings.HasPrefix(line, "\025clear; ") {
		t.Errorf("sent line %q does not open with C-u and clear", line)
	}
	if !strings.Contains(line, "| tee -a ") || !strings.Contains(line, "run1.log") {
		t.Errorf("sent line %q does not tee into the run's own log", line)
	}
	if !strings.Contains(out, "pane 12  run1  in "+dir+"  log ") {
		t.Errorf("start line = %q, want the pane, the name, the directory, and the log", out)
	}
	// The record is untouched: reuse must not rewrite what it read.
	body, _ := os.ReadFile(ws.paneFile())
	if strings.TrimSpace(string(body)) != "12" {
		t.Errorf("pane record = %q after a reuse, want 12", body)
	}
}

// 2. A recorded pane that is gone is not addressed; a fresh one is split, and
// nothing is ever sent to the dead id.
func TestDeadRecordedPaneIsReplaced(t *testing.T) {
	dir := state(t)
	fast(t)
	t.Setenv("WEZTERM_PANE", "7")
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "404")

	// Driven through `start`, not through `pane` and `split` by hand: "no command is
	// sent to the dead id" is a statement about the call, and calling the two helpers
	// in sequence proved only that each one works alone.
	var code int
	captured(t, func() { code = ws.start("7", t.TempDir(), options{tail: 20, command: "true"}) })
	if code != 0 {
		t.Fatalf("start with a dead recorded worker = %d, want 0", code)
	}
	if n := mux.splits(); n != 1 {
		t.Errorf("panes split = %d, want exactly 1", n)
	}

	target, _ := mux.typed(t)
	if target != "9" {
		t.Errorf("the command went to pane %s, want the freshly split 9", target)
	}
	for _, action := range mux.actions {
		if strings.Contains(action, "send-text") && strings.Contains(action, "--pane-id 404") {
			t.Error("a command was sent to the dead recorded pane")
		}
	}
	// Focus returns to the caller, which is one of the three guards the design calls
	// load-bearing. Untested, it was one line from being lost in the rewrite.
	if !strings.Contains(strings.Join(mux.actions, "\n"), "activate-pane --pane-id 7") {
		t.Errorf("focus was not returned to the caller: %v", mux.actions)
	}

	body, err := os.ReadFile(ws.paneFile())
	if err != nil || strings.TrimSpace(string(body)) != "9" {
		t.Errorf("pane file = %q, %v; want 9", body, err)
	}
	if !strings.HasPrefix(ws.dir, dir) {
		t.Errorf("record %q is not under the manifest directory %q", ws.dir, dir)
	}
}

// A run queued behind another is reported as queued, naming what it waits for.
// This is the second of the three guards the design calls load-bearing, and it
// had no test either.
func TestARunQueuedBehindAnotherSaysSo(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{7, 12}, split: 99}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	if err := os.WriteFile(ws.runningFile(), []byte("earlier\n"), 0o600); err != nil {
		t.Fatal(err)
	}

	out := captured(t, func() { ws.start("7", t.TempDir(), options{tail: 20, command: "true"}) })
	if !strings.Contains(out, "queued behind earlier") {
		t.Errorf("start line = %q, want it to name the run being waited on", out)
	}
}

// The `last.log` and `last.rc` aliases are created, which is what makes `last` a
// reserved name worth reserving.
func TestTheLastAliasesPointAtTheNewestRun(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{7, 12}, split: 99}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	captured(t, func() { ws.start("7", t.TempDir(), options{tail: 20, command: "true"}) })

	for _, pair := range [][2]string{{"last.log", "run1.log"}, {"last.rc", "run1.rc"}} {
		got, err := os.Readlink(filepath.Join(ws.dir, pair[0]))
		if err != nil {
			t.Errorf("%s: %v", pair[0], err)
			continue
		}
		if filepath.Base(got) != pair[1] {
			t.Errorf("%s -> %s, want %s", pair[0], filepath.Base(got), pair[1])
		}
	}
}

// 3. The caller's own pane is never addressed, even when it is alive and
// recorded: sending to it would race the caller's own shell.
func TestRefusesToAddressTheCallingPane(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "7")

	_, err := ws.pane("7")
	if err == nil || !strings.Contains(err.Error(), "calling pane") {
		t.Errorf("pane() = %v, want a refusal naming the calling pane", err)
	}
}

// A recorded id from an earlier mux generation is rejected rather than reused.
// Pane ids restart at 0 when the mux restarts, so the id is live and wrong.
func TestRejectsAPaneFromAnEarlierMuxGeneration(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{1}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	os.WriteFile(ws.paneFile(), []byte("1\n"), 0o600)
	os.WriteFile(ws.muxFile(), []byte("99\n"), 0o600)

	_, err := ws.pane("7")
	if err == nil || !strings.Contains(err.Error(), "mux 99") {
		t.Errorf("pane() = %v, want a rejection naming the recorded mux", err)
	}

	// The same record in the generation that wrote it is usable.
	ws.live(t, "1")
	if got, err := ws.pane("7"); err != nil || got != "1" {
		t.Errorf("pane() in its own generation = %q, %v; want \"1\", nil", got, err)
	}
}

// A generation this process cannot vouch for is "not current", never "current".
// An absent marker used to skip the check, and a recorded "0" used to match the
// "0" a socket-less process reports, so both let a stranger's pane be addressed.
func TestAnUnverifiableGenerationIsNotTreatedAsCurrent(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{1}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	os.WriteFile(ws.paneFile(), []byte("1\n"), 0o600)

	if _, err := ws.pane("7"); err == nil {
		t.Error("a record with no generation marker was accepted")
	}

	os.WriteFile(ws.muxFile(), []byte("0\n"), 0o600)
	if _, err := ws.pane("7"); err == nil {
		t.Error("a record marked with generation 0 was accepted")
	}

	// And a caller with no generation of its own cannot match any record.
	ws.live(t, "1")
	t.Setenv("WEZTERM_UNIX_SOCKET", "")
	if _, err := ws.pane("7"); err == nil {
		t.Error("a caller with no generation matched a record anyway")
	}
}

// An unresponsive mux fails the call instead of hanging it, and the failure is
// distinguishable from an answer of "no such pane".
func TestAnUnresponsiveMuxFailsRatherThanHangs(t *testing.T) {
	state(t)
	mux := &fakeMux{listFail: true}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "3")

	_, err := ws.pane("7")
	if err == nil {
		t.Fatal("a mux that did not answer was treated as answering")
	}
	if !errors.Is(err, errProbe) {
		t.Errorf("pane() = %v, want an errProbe so no caller reads it as absence", err)
	}
}

// A probe that cannot answer MUST NOT split a replacement. Reading an
// unanswerable probe as "no worker" manufactures the second pane beside a live
// one that this package exists to prevent.
func TestAnUnanswerableProbeDoesNotSplitASecondWorker(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}, split: 99, listFail: true}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	if code := ws.start("7", t.TempDir(), options{tail: 20}); code != 2 {
		t.Errorf("start with an unanswerable probe = %d, want 2", code)
	}
	for _, action := range mux.actions {
		if strings.Contains(action, "split-pane") {
			t.Error("a second worker was split while the first one's state was unknown")
		}
	}
	body, _ := os.ReadFile(ws.paneFile())
	if strings.TrimSpace(string(body)) != "12" {
		t.Errorf("the record was overwritten: %q", body)
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
	ws := workspaceIn(t, t.TempDir())

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
	// The body removes itself once its exit code lands, so nothing accumulates a
	// dead script per run.
	if _, err := os.Stat(body); err == nil {
		t.Error("the body survived its own run")
	}

	// Now remove the directory and run a fresh body for the same name: it must
	// refuse rather than fall through and run the command wherever the pane happens
	// to be, and it must say so with a code no ordinary command returns.
	os.RemoveAll(awkward)
	os.Remove(ws.rcFile("run1"))
	if err := ws.writeBody(body, "run1", awkward, "pwd"); err != nil {
		t.Fatal(err)
	}
	out, err = exec.Command("zsh", body).CombinedOutput()
	if err == nil {
		t.Errorf("body ran with its directory gone:\n%s", out)
	}
	if !strings.Contains(string(out), "is gone") {
		t.Errorf("body did not say the directory is gone:\n%s", out)
	}
	if code := readRC(t, ws, "run1"); code != strconv.Itoa(directoryGone) {
		t.Errorf("exit code with the directory gone = %q, want %d; 2 is what `go test` and `make` return for an ordinary failure",
			code, directoryGone)
	}
}

// A directory name that would split under SH_WORD_SPLIT still reaches the
// command, because the body quotes its expansion rather than trusting the
// owner's zsh options.
func TestTheGeneratedBodySurvivesWordSplitting(t *testing.T) {
	if _, err := exec.LookPath("zsh"); err != nil {
		t.Skip("no zsh")
	}
	state(t)
	ws := workspaceIn(t, t.TempDir())

	spaced := filepath.Join(t.TempDir(), "two words")
	if err := os.MkdirAll(spaced, 0o700); err != nil {
		t.Fatal(err)
	}
	body := ws.bodyFile("run1")
	if err := ws.writeBody(body, "run1", spaced, "pwd"); err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command("zsh", "-o", "shwordsplit", body)
	out, err := cmd.CombinedOutput()
	if err != nil || !strings.Contains(string(out), spaced) {
		t.Errorf("body with SH_WORD_SPLIT set: %v\n%s", err, out)
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
	ws := workspaceIn(t, t.TempDir())

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
	opts, err := parse([]string{"-w", "900", "-t", "5", "-n", "build", "nix build"})
	if err != nil {
		t.Fatal(err)
	}
	if opts.wait == nil || *opts.wait != 900 || opts.tail != 5 || opts.name != "build" || opts.command != "nix build" {
		t.Errorf("parse = %+v, want wait 900, tail 5, name build, command \"nix build\"", opts)
	}
}

// The command is every remaining word joined, the way the superseded script's
// `"$*"` did, so an unquoted invocation runs rather than being reported as a
// second command. The long flag forms are the ones the skill's own examples use.
func TestTheCommandIsEveryRemainingWordJoined(t *testing.T) {
	opts, err := parse([]string{"git", "status", "--short"})
	if err != nil {
		t.Fatalf("a bare multi-word command was rejected: %v", err)
	}
	if opts.command != "git status --short" {
		t.Errorf("command = %q, want %q", opts.command, "git status --short")
	}

	opts, err = parse([]string{"--wait", "60", "--tail", "3", "--name", "b", "--", "-n", "hello"})
	if err != nil {
		t.Fatal(err)
	}
	if opts.wait == nil || *opts.wait != 60 || opts.tail != 3 || opts.name != "b" {
		t.Errorf("long flags = %+v", opts)
	}
	if opts.command != "-n hello" {
		t.Errorf("after --, command = %q, want %q", opts.command, "-n hello")
	}
}

// A word that looks like a run name followed by a quoted command is the log-name
// mistake, and joining the two would run the name as part of the command.
func TestARunNameWhereACommandBelongsIsCaught(t *testing.T) {
	_, err := parse([]string{"build", "nix build .#foo"})
	if err == nil {
		t.Fatal("a run name in the command position was joined into the command")
	}
	if !strings.Contains(err.Error(), "-n build") {
		t.Errorf("error %q does not show the corrected invocation", err)
	}
}

// A mode flag with a command is an error, not a silent discard. Exiting 0 having
// run nothing reads to an agent as the command having succeeded.
func TestAModeFlagWithACommandIsRefused(t *testing.T) {
	for _, args := range [][]string{
		{"--status", "true"},
		{"--close", "true"},
		{"--release", "build", "true"},
	} {
		if _, err := parse(args); err == nil {
			t.Errorf("%v was accepted, so the command would have been discarded", args)
		}
	}
	if _, err := parse([]string{"--status", "--close"}); err == nil {
		t.Error("two mode flags were accepted")
	}
}

// 8. A name whose previous run recorded no exit code is refused, and --release
// frees it without discarding any other run's log.
func TestANameInFlightIsRefusedAndReleasableAlone(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)
	ws := workspaceIn(t, t.TempDir())

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
	if err := ws.claimExact("build", true); err == nil {
		t.Error("a name in flight was claimed")
	}
	if err := ws.claimExact("other", true); err != nil {
		t.Errorf("an explicit -n could not reuse a finished name: %v", err)
	}

	if code := ws.release("7", "build", false); code != 0 {
		t.Errorf("release = %d, want 0", code)
	}
	if ws.inFlight("build") {
		t.Error("release left the name burned")
	}
	if _, err := os.Stat(ws.logFile("other")); err != nil {
		t.Error("release discarded another run's log")
	}

	// The running run is not releasable while a live pane could be running it:
	// that would orphan its output.
	ws.live(t, "12")
	mux.panes = append(mux.panes, 12)
	os.WriteFile(ws.logFile("live"), []byte("running\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("live\n"), 0o600)
	if code := ws.release("7", "live", false); code != 2 {
		t.Errorf("release of the running run = %d, want 2", code)
	}
	if _, err := os.Stat(ws.logFile("live")); err != nil {
		t.Error("release removed the running run's log anyway")
	}
}

// A run queued in the tty input buffer is not releasable. Its marker still names
// its predecessor, because the body writes the marker when the PREVIOUS command
// finishes, so keying the refusal on the marker released it and deleted the body
// the pane was about to run.
func TestAQueuedRunIsNotReleasable(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	// `a` is running, so the marker names it. `b` is queued behind it: its log and
	// body exist, and it has recorded no exit code.
	os.WriteFile(ws.logFile("a"), []byte("a's output\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("a\n"), 0o600)
	os.WriteFile(ws.logFile("b"), []byte("=== b\n"), 0o600)
	os.WriteFile(ws.bodyFile("b"), []byte("#!/usr/bin/env zsh\ntrue\n"), 0o700)

	if code := ws.release("7", "b", false); code != 2 {
		t.Errorf("release of a queued run = %d, want 2", code)
	}
	if _, err := os.Stat(ws.bodyFile("b")); err != nil {
		t.Error("release deleted the body the pane was about to run")
	}
	if got := ws.runningRun(); got != "a" {
		t.Errorf("marker = %q, want it untouched at \"a\"", got)
	}

	// And --force is the way back. The default refusal above cannot tell a queued run
	// from one abandoned by a caller that died between writing the log and the send, so
	// refusing outright left the name unrecoverable for as long as the worker lived,
	// which is the property that got prune-as-release rejected in the design.
	if code := ws.release("7", "b", true); code != 0 {
		t.Errorf("forced release of an ambiguous name = %d, want 0", code)
	}
	if _, err := os.Stat(ws.logFile("b")); err == nil {
		t.Error("a forced release left the name burned")
	}
}

// --force still refuses a run the marker names. That run is not "could be
// running", it IS running, and unlinking its log while `tee` writes to the inode
// is the harm the refusal exists for: forcing it would be that harm with an extra
// step.
func TestForceDoesNotReleaseARunThatIsActuallyRunning(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	os.WriteFile(ws.logFile("a"), []byte("a's output\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("a\n"), 0o600)

	if code := ws.release("7", "a", true); code != 2 {
		t.Errorf("forced release of a running run = %d, want 2", code)
	}
	if _, err := os.Stat(ws.logFile("a")); err != nil {
		t.Error("a forced release unlinked the log of a run that is executing")
	}
}

// --force modifies --release and nothing else, so it is rejected anywhere else
// rather than silently ignored while the command runs.
func TestForceWithoutAReleaseIsRefused(t *testing.T) {
	if _, err := parse([]string{"--force", "true"}); err == nil {
		t.Error("--force with a command was accepted")
	}
	if _, err := parse([]string{"--release", "build", "--force"}); err != nil {
		t.Errorf("--release with --force = %v, want it accepted", err)
	}
}

// A marker naming a run whose pane is gone has no owner: the pane died before
// its trap could clear it. Both recoveries have to reclaim it, or the name stays
// unusable with no command-line way back.
func TestAMarkerWithNoOwnerIsReclaimable(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)

	// --release reclaims it.
	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "404")
	os.WriteFile(ws.logFile("build"), []byte("half a log\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("build\n"), 0o600)

	if code := ws.release("7", "build", false); code != 0 {
		t.Fatalf("release with a dead owner = %d, want 0", code)
	}
	if ws.inFlight("build") {
		t.Error("the name is still burned")
	}
	if _, err := os.Stat(ws.runningFile()); err == nil {
		t.Error("the ownerless marker survived --release")
	}

	// --close reclaims it too, and says so rather than clearing it silently.
	other := workspaceIn(t, t.TempDir())
	other.live(t, "404")
	os.WriteFile(other.runningFile(), []byte("build\n"), 0o600)
	if code := other.closePane("7"); code != 0 {
		t.Fatalf("close with a dead pane = %d, want 0", code)
	}
	if _, err := os.Stat(other.runningFile()); err == nil {
		t.Error("the ownerless marker survived --close")
	}
	if _, err := os.Stat(other.paneFile()); err == nil {
		t.Error("the stale pane record survived --close")
	}
}

// A kill that failed leaves a pane that is still alive, so the record MUST stay:
// the superseded script removed it whatever happened, which left the live pane
// unreachable and the next call splitting a second one beside it.
func TestAFailedKillKeepsTheRecord(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}, killFail: true}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	if code := ws.closePane("7"); code != 2 {
		t.Errorf("close with a failing kill = %d, want 2", code)
	}
	body, err := os.ReadFile(ws.paneFile())
	if err != nil || strings.TrimSpace(string(body)) != "12" {
		t.Errorf("record after a failed kill = %q, %v; want it kept", body, err)
	}
}

// Two callers in one workspace never get one name, so they never share one log
// and one exit code. The counter alone could not do this: both read it, both
// increment, and both get the same number.
func TestConcurrentCallersNeverShareARunName(t *testing.T) {
	state(t)
	ws := workspaceIn(t, t.TempDir())

	const callers = 12
	var wait sync.WaitGroup
	names := make([]string, callers)
	for i := range callers {
		wait.Add(1)
		go func() {
			defer wait.Done()
			name, err := ws.claim("")
			if err != nil {
				t.Errorf("claim: %v", err)
				return
			}
			names[i] = name
		}()
	}
	wait.Wait()

	seen := map[string]bool{}
	for _, name := range names {
		if name == "" {
			continue
		}
		if seen[name] {
			t.Errorf("two callers were handed the name %s", name)
		}
		seen[name] = true
	}
	if len(seen) != callers {
		t.Errorf("got %d distinct names for %d callers", len(seen), callers)
	}
}

// An allocated name never takes over a finished run's log. The counter lives in
// the same directory as the runs it numbers, so a counter file that is removed or
// truncated restarts at 1, and reuse there would delete run1's log silently.
func TestAnAllocatedNameNeverTakesAFinishedRunsLog(t *testing.T) {
	state(t)
	ws := workspaceIn(t, t.TempDir())

	os.WriteFile(ws.logFile("run1"), []byte("run1's output\n"), 0o600)
	os.WriteFile(ws.rcFile("run1"), []byte("0\n"), 0o600)
	// The counter is behind the runs on disk, as it is after a partial prune.
	os.WriteFile(ws.counterFile(), []byte("0\n"), 0o600)

	name, err := ws.claim("")
	if err != nil {
		t.Fatal(err)
	}
	if name == "run1" {
		t.Error("an allocated name took over a finished run's name")
	}
	body, err := os.ReadFile(ws.logFile("run1"))
	if err != nil || !strings.Contains(string(body), "run1's output") {
		t.Errorf("run1's log = %q, %v; want it untouched", body, err)
	}

	// An explicit -n still reuses it, which is what the superseded script did.
	if got, err := ws.claim("run1"); err != nil || got != "run1" {
		t.Errorf("explicit -n run1 = %q, %v; want it reusable", got, err)
	}
}

// A send that failed ran nothing, so it MUST NOT leave the name looking like a
// run in flight. Left behind, the log with no exit code burns the name for every
// pane in the workspace and the previous run's exit code is already gone.
func TestAFailedSendDoesNotBurnTheName(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}, sendFail: true}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	if code := ws.start("7", t.TempDir(), options{tail: 20}); code != 2 {
		t.Errorf("start with a failing send = %d, want 2", code)
	}
	if ws.inFlight("run1") {
		t.Error("a run that never started burned its name")
	}
	if _, err := os.Stat(ws.logFile("run1")); err == nil {
		t.Error("a run that never started left a log")
	}
}

// A caller with no mux generation of its own refuses, rather than splitting a
// worker it will refuse again next time. The record it would write is equally
// unverifiable, so accepting the split means one new pane per invocation and no
// way for --close to reach any of them.
func TestACallerWithNoGenerationRefusesInsteadOfSplittingForever(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/not-a-gui-sock")
	mux := &fakeMux{panes: []int{7, 12}, split: 99}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	os.WriteFile(ws.paneFile(), []byte("12\n"), 0o600)
	os.WriteFile(ws.muxFile(), []byte("0\n"), 0o600)

	if code := ws.start("7", t.TempDir(), options{tail: 20}); code != 2 {
		t.Errorf("start with no generation = %d, want 2", code)
	}
	for _, action := range mux.actions {
		if strings.Contains(action, "split-pane") {
			t.Fatal("a worker was split that the next invocation would refuse again")
		}
	}
	// And --close can still say why, rather than deleting the record and killing
	// nothing.
	if code := ws.closePane("7"); code != 2 {
		t.Errorf("close with no generation = %d, want 2", code)
	}
	if _, err := os.Stat(ws.paneFile()); err != nil {
		t.Error("the record was deleted while the pane's state was unknown")
	}
}

// A record naming the calling pane says who is asking, not whether the pane
// exists. Reading it as absence deleted the record of a pane that was still on
// screen, and discarded a run executing in that very pane.
func TestARecordNamingTheCallerIsNotAbsence(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{12}, split: 99}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	// --close from inside the worker pane keeps the record and kills nothing.
	if code := ws.closePane("12"); code != 2 {
		t.Errorf("close from the worker pane = %d, want 2", code)
	}
	if _, err := os.Stat(ws.paneFile()); err != nil {
		t.Error("the record of a live pane was deleted")
	}
	for _, action := range mux.actions {
		if strings.Contains(action, "kill-pane") {
			t.Error("the calling pane was killed")
		}
	}

	// --release from inside the worker pane refuses: the run is executing here.
	os.WriteFile(ws.logFile("live"), []byte("running\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("live\n"), 0o600)
	if code := ws.release("12", "live", false); code != 2 {
		t.Errorf("release from the worker pane = %d, want 2", code)
	}
	if _, err := os.Stat(ws.logFile("live")); err != nil {
		t.Error("a running run's log was unlinked while tee was writing to it")
	}

	// Starting a run from inside the worker still splits, which is correct: the
	// caller needs a worker other than itself, and its own pane is not orphaned.
	if code := ws.start("12", t.TempDir(), options{tail: 20}); code != 0 {
		t.Errorf("start from the worker pane = %d, want 0", code)
	}
}

// --close records an exit code for the run it killed. Without it the log has no
// rc, which reads as a run in flight, so --close silently burned that name for
// the whole workspace while printing a message that read like cleanup finishing.
func TestCloseRecordsACodeForTheRunItKilled(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	os.WriteFile(ws.logFile("build"), []byte("half a build\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("build\n"), 0o600)

	if code := ws.closePane("7"); code != 0 {
		t.Fatalf("close = %d, want 0", code)
	}
	if ws.inFlight("build") {
		t.Error("--close burned the name of the run it killed")
	}
	if got := readRC(t, ws, "build"); got != strconv.Itoa(paneClosed) {
		t.Errorf("recorded exit code = %q, want %d", got, paneClosed)
	}
}

// A read-only query never creates the record directory. The migration plan has
// the owner run --status to compare the two implementations, and a query that
// writes perturbs the baseline the later steps compare against.
func TestAQueryDoesNotCreateTheRecord(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "7")
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)

	dir := t.TempDir()
	t.Chdir(dir)
	ws, err := newWorkspace(dir)
	if err != nil {
		t.Fatal(err)
	}

	for _, args := range [][]string{{"--status"}, {"--close"}, {"--release", "build"}} {
		if code := Run(args); code != 0 {
			t.Errorf("%v = %d, want 0", args, code)
		}
		if _, err := os.Stat(ws.dir); err == nil {
			t.Fatalf("%v created the record directory %s", args, ws.dir)
		}
	}
}

// Two callers passing the same explicit -n never both hold the name. The reuse
// path used to remove the log and then create it, so the second caller removed
// the log the first had just created and both proceeded.
func TestTheReuseRaceHandsTheNameToOneCaller(t *testing.T) {
	state(t)
	ws := workspaceIn(t, t.TempDir())

	// The window is between the exclusive create failing and the replacement being
	// made, so the callers have to arrive inside it. A plain `go` for each is not
	// enough: without the barrier this test passed against the very mutation it
	// exists to catch, over three runs.
	const rounds = 2000
	const callers = 4
	for round := range rounds {
		os.WriteFile(ws.logFile("build"), []byte("a finished run\n"), 0o600)
		os.WriteFile(ws.rcFile("build"), []byte("0\n"), 0o600)

		release := make(chan struct{})
		var ready, done sync.WaitGroup
		won := make([]bool, callers)
		for i := range won {
			ready.Add(1)
			done.Add(1)
			go func() {
				defer done.Done()
				ready.Done()
				<-release
				// `claim`, not `claimExact`: the exclusion lives in `claim`, so a test
				// that calls the inner function proves nothing about the real path.
				name, err := ws.claim("build")
				won[i] = err == nil && name == "build"
			}()
		}
		ready.Wait()
		close(release)
		done.Wait()

		holders := 0
		for _, w := range won {
			if w {
				holders++
			}
		}
		if holders != 1 {
			t.Fatalf("round %d: %d of %d callers held the name build, want exactly 1", round, holders, callers)
		}
		os.Remove(ws.logFile("build"))
		os.Remove(ws.rcFile("build"))
	}
}

// A run name has to stay inside the workspace's directory, and cannot be the
// alias for the most recent run.
func TestARunNameIsOnePathElement(t *testing.T) {
	for _, name := range []string{"", "..", ".", "../etc/passwd", "a/b", `a\b`, "last", "a\nb"} {
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
	a := workspaceIn(t, t.TempDir())
	b := workspaceIn(t, t.TempDir())
	if a.dir == b.dir {
		t.Errorf("two workspaces keyed to one record: %q", a.dir)
	}
	if workspaceIn(t, a.root).dir != a.dir {
		t.Error("one workspace keyed to two records across calls")
	}
}

// The explicit key override takes a private worker under a name the caller
// chooses. A value it cannot honour FAILS: the caller asked for a worker of its
// own, and handing back the shared record would aim --close at another pane's
// worker and --release at another run's name.
func TestTheSessionOverrideTakesAPrivateWorker(t *testing.T) {
	root := state(t)
	dir := t.TempDir()

	derived := workspaceIn(t, dir)

	t.Setenv(sessionOverride, "build")
	override := workspaceIn(t, dir)
	if override.dir != filepath.Join(root, "build") {
		t.Errorf("override keyed to %q, want %q", override.dir, filepath.Join(root, "build"))
	}
	if override.dir == derived.dir {
		t.Error("the override resolved to the derived key")
	}
	if override.root != derived.root {
		t.Errorf("override root = %q, want the directory %q so every message names a path",
			override.root, derived.root)
	}

	// Two callers in different workspaces share one override, which is the point
	// of the hatch: the name is the key.
	if workspaceIn(t, t.TempDir()).dir != override.dir {
		t.Error("the override did not out-rank the workspace")
	}

	// A name it cannot honour is refused, never substituted. The last two are the
	// shapes the phase-3 prune matches, so honouring either would let the hatch
	// address another workspace's record.
	for _, bad := range []string{"../escape", "a/b", "pane-241", "myrepo-0123456789abcdef"} {
		t.Setenv(sessionOverride, bad)
		if got, err := newWorkspace(dir); err == nil {
			t.Errorf("override %q was honoured as %q; it must fail", bad, got.dir)
		}
	}

	// An empty value is "no override", not a bad name: that is what
	// `${WTRUN_SESSION:-<derived>}` meant in the superseded script, and an exported
	// but unset variable is the ordinary way a shell says nothing was chosen.
	for _, blank := range []string{"", "   "} {
		t.Setenv(sessionOverride, blank)
		got, err := newWorkspace(dir)
		if err != nil || got.dir != derived.dir {
			t.Errorf("override %q gave %v, %v; want the derived key", blank, got, err)
		}
	}
}

// A wait returns the run's own exit code, and a wait that expires returns the
// timeout code and names the file to poll.
func TestWaitReturnsTheRunsCodeOrTheTimeoutCode(t *testing.T) {
	state(t)
	fast(t)
	ws := workspaceIn(t, t.TempDir())

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

// A wait far beyond a duration's range still waits. `time.Duration(seconds) *
// time.Second` overflows int64 above 9223372036, which put the deadline in the
// past and reported a timeout at once.
func TestAnEnormousWaitDoesNotExpireImmediately(t *testing.T) {
	state(t)
	fast(t)
	ws := workspaceIn(t, t.TempDir())

	os.WriteFile(ws.logFile("run1"), []byte("output\n"), 0o600)
	done := make(chan int, 1)
	go func() {
		time.Sleep(20 * time.Millisecond)
		os.WriteFile(ws.rcFile("run1"), []byte("0\n"), 0o600)
	}()
	go func() { done <- ws.waitForExit("run1", 1<<62, 1) }()

	select {
	case code := <-done:
		if code != 0 {
			t.Errorf("wait = %d, want the run's own code 0", code)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("the wait never returned")
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

// The exit code is published LAST, so a name is never reusable while the previous
// run's body still exists.
//
// This is the ordering defect, and it is the one that could ship silently. The rc
// appearing is what tells every other process the name is free: claimExact's
// refusal names the rc to wait for, and so does the wait timeout. While the body
// was deleted after the rc, a successor reusing the name had already written its
// own body to the same path and the predecessor's trap deleted it. The pane was
// then told to run a file that no longer existed, so nothing ran and no trap fired,
// which means no exit code was ever written: the caller printed a start line, exited
// 0, and burned the name for the whole workspace. Reproduced in 20 of 20 rounds, with
// a window measured up to 19.7ms, before the order was reversed.
func TestAReusedNameNeverLosesItsBodyToThePreviousRunsTrap(t *testing.T) {
	if _, err := exec.LookPath("zsh"); err != nil {
		t.Skip("no zsh")
	}
	state(t)
	dir := t.TempDir()
	ws := workspaceIn(t, dir)

	lost := 0
	const rounds = 20
	for round := 0; round < rounds; round++ {
		for _, path := range []string{ws.logFile("build"), ws.rcFile("build"), ws.bodyFile("build")} {
			os.Remove(path)
		}
		if _, err := ws.claim("build"); err != nil {
			t.Fatal(err)
		}
		body := ws.bodyFile("build")
		if err := ws.writeBody(body, "build", dir, "true"); err != nil {
			t.Fatal(err)
		}
		run := exec.Command("zsh", body)
		if err := run.Start(); err != nil {
			t.Fatal(err)
		}
		// Polled exactly the way the refusal message and the wait timeout tell a caller
		// to poll: the rc file, and nothing else.
		for {
			if _, err := os.Stat(ws.rcFile("build")); err == nil {
				break
			}
		}
		// Then everything `worker -n build <command>` does before the send.
		if _, err := ws.claim("build"); err != nil {
			t.Fatalf("round %d: the name was still refused after its exit code appeared: %v", round, err)
		}
		if err := ws.writeBody(body, "build", dir, "echo second"); err != nil {
			t.Fatal(err)
		}
		run.Wait()
		if _, err := os.Stat(body); err != nil {
			lost++
		}
	}
	if lost > 0 {
		t.Errorf("%d of %d rounds lost the successor's body to the previous run's trap", lost, rounds)
	}
}

// One marker serves the whole workspace, so a body removes it only while it still
// names that body's own run. A pane that handed the worker role over and kept
// running would otherwise delete the marker of the pane that replaced it.
func TestABodyDoesNotRemoveAnotherRunsMarker(t *testing.T) {
	if _, err := exec.LookPath("zsh"); err != nil {
		t.Skip("no zsh")
	}
	state(t)
	dir := t.TempDir()
	ws := workspaceIn(t, dir)

	// The command stands in for the other pane: the body claims the marker on the way
	// in, as every body does, and by the time it exits the marker names a run that
	// started elsewhere. Writing the marker before the body starts would not test
	// anything, because the body's first act is to overwrite it with its own name.
	body := ws.bodyFile("mine")
	if err := ws.writeBody(body, "mine", dir, "print -r -- theirs > "+shellQuote(ws.runningFile())); err != nil {
		t.Fatal(err)
	}
	if out, err := exec.Command("zsh", body).CombinedOutput(); err != nil {
		t.Fatalf("body: %v: %s", err, out)
	}
	if got := ws.runningRun(); got != "theirs" {
		t.Errorf("marker = %q after another run finished, want it left at \"theirs\"", got)
	}
}

// A replacement split replaces the WHOLE record, marker included, and records an
// exit code for the run the gone pane can no longer finish.
//
// Leaving the marker behind made a fresh pane inherit a run it never had: the start
// line said "queued behind run1", `--status` reported "running run1" on a pane that
// had run one command, and run1's name stayed burned because nothing would ever
// write its exit code.
func TestAReplacementSplitDoesNotInheritTheDeadPanesRun(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "404")
	os.WriteFile(ws.logFile("run1"), []byte("=== run1\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("run1\n"), 0o600)

	out := captured(t, func() { ws.start("7", t.TempDir(), options{tail: 20, command: "true"}) })
	if strings.Contains(out, "queued behind") {
		t.Errorf("start line = %q, want no queue: the pane it would have queued behind is gone", out)
	}
	if got := ws.runningRun(); got != "" {
		t.Errorf("marker = %q on a freshly split pane, want it cleared", got)
	}
	if got := readRC(t, ws, "run1"); got != strconv.Itoa(paneClosed) {
		t.Errorf("run1 recorded %s, want %d: its pane is gone, so it can never record its own", got, paneClosed)
	}
	status := captured(t, func() { ws.reportStatus("7") })
	if strings.Contains(status, "run1") {
		t.Errorf("--status = %q, want no mention of a run this pane never had", status)
	}
}

// Handing the role over is not the same as losing it. The outgoing pane is the
// caller, it is alive, and its run keeps executing, so its exit code stays its own
// trap's to write: recording one here would report a code for a live run and the
// trap would later overwrite it, so one run would report two exit codes.
func TestHandingOverTheRoleDoesNotRecordACodeForTheCallersRun(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{12}, split: 14}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	os.WriteFile(ws.logFile("run1"), []byte("=== run1\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("run1\n"), 0o600)

	// Pane 12 is the recorded worker AND the caller: something inside the run is
	// invoking worker, which is errSelf, so the role moves to a new pane.
	captured(t, func() { ws.start("12", t.TempDir(), options{tail: 20, command: "true"}) })

	if got := ws.runningRun(); got == "run1" {
		t.Error("the marker still names a run that is executing in the pane that gave up the role")
	}
	if _, err := os.Stat(ws.rcFile("run1")); err == nil {
		t.Error("an exit code was recorded for a run still executing in a live pane")
	}
}

// --close records 129 only for a run it can attribute to the pane it killed.
func TestCloseDoesNotRecordACodeForAnotherPanesRun(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{12}, split: 14}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")
	os.WriteFile(ws.logFile("run1"), []byte("=== run1\n"), 0o600)
	os.WriteFile(ws.runningFile(), []byte("run1\n"), 0o600)

	// The role moves from pane 12 to pane 14 while run1 keeps running in 12.
	captured(t, func() { ws.start("12", t.TempDir(), options{tail: 20, command: "true"}) })
	// Closing from a third pane kills 14, which was never the pane running run1.
	out := captured(t, func() { ws.closePane("3") })

	if strings.Contains(out, "run1") {
		t.Errorf("--close = %q, want no claim about a run in a pane it did not kill", out)
	}
	if _, err := os.Stat(ws.rcFile("run1")); err == nil {
		t.Error("--close recorded an exit code for a run executing in a pane it never killed")
	}
}

// The allocation lock covers every path that decides a name's fate, not just the
// claim. release reads the log and then deletes it, and unlocked those two steps
// straddled another caller's claim of the same name.
func TestReleaseTakesTheAllocationLock(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7}}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	os.WriteFile(ws.logFile("build"), []byte("=== build\n"), 0o600)
	os.WriteFile(ws.rcFile("build"), []byte("0\n"), 0o600)

	held, err := os.OpenFile(ws.lockFile(), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		t.Fatal(err)
	}
	defer held.Close()
	if err := syscall.Flock(int(held.Fd()), syscall.LOCK_EX); err != nil {
		t.Fatal(err)
	}

	done := make(chan int, 1)
	go func() { done <- ws.release("7", "build", false) }()
	// The value is taken in the select, not read a second time afterwards: a test that
	// reads a one-value channel twice deadlocks on the very failure it is asserting,
	// which turns a failing test into a hung suite.
	code := -1
	blocked := false
	select {
	case code = <-done:
		t.Error("release ran to completion while another caller held the allocation lock")
	case <-time.After(200 * time.Millisecond):
		blocked = true
	}
	syscall.Flock(int(held.Fd()), syscall.LOCK_UN)
	if blocked {
		code = <-done
	}
	if code != 0 {
		t.Errorf("release after the lock was dropped = %d, want 0", code)
	}
}

// The rollback is under the lock for the same reason the claim is: it removes the
// log that IS the claim, and unlocked it removed a second caller's freshly claimed
// log rather than its own abandoned one.
func TestTheRollbackTakesTheAllocationLock(t *testing.T) {
	state(t)
	fast(t)
	mux := &fakeMux{panes: []int{7, 12}, sendFail: true}
	mux.install(t)

	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	// Driven directly rather than by racing a real `start`: waiting for the claim to
	// appear and then grabbing the lock is a race the test cannot win reliably, and a
	// test that only sometimes exercises the path it names is worse than none.
	os.WriteFile(ws.logFile("run1"), []byte("=== run1\n"), 0o600)
	held, err := os.OpenFile(ws.lockFile(), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		t.Fatal(err)
	}
	defer held.Close()
	if err := syscall.Flock(int(held.Fd()), syscall.LOCK_EX); err != nil {
		t.Fatal(err)
	}

	done := make(chan struct{})
	go func() { ws.rollback("run1"); close(done) }()
	select {
	case <-done:
		t.Error("the rollback ran while another caller held the allocation lock")
	case <-time.After(200 * time.Millisecond):
	}
	syscall.Flock(int(held.Fd()), syscall.LOCK_UN)
	<-done
	if _, err := os.Stat(ws.logFile("run1")); err == nil {
		t.Error("the name stayed burned after the rollback")
	}

	// And the whole path still frees the name when a send fails.
	mux.sendFail = true
	var code int
	captured(t, func() { code = ws.start("7", t.TempDir(), options{tail: 20, command: "true"}) })
	if code != 2 {
		t.Errorf("start with a failing send = %d, want 2", code)
	}
	if _, err := os.Stat(ws.logFile("run1")); err == nil {
		t.Error("a failed send burned the name")
	}
}

// --status has three forms and all three are declared parity items, so all three
// are asserted. The whole reporter could be gutted to `return 0` and the suite
// stayed green: the one test that called it checked only the exit code.
func TestStatusReportsTheThreeStatesItDeclares(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}}
	mux.install(t)
	ws := workspaceIn(t, t.TempDir())

	// No worker at all. Declared as its own negative scenario, and it exits 0 because
	// "there is no worker" is an answer, not a failure.
	var code int
	out := captured(t, func() { code = ws.reportStatus("7") })
	if code != 0 || !strings.Contains(out, "no worker for "+ws.root) {
		t.Errorf("--status with no record = %d, %q; want 0 and a line saying so", code, out)
	}

	// A worker with nothing running.
	ws.live(t, "12")
	out = captured(t, func() { code = ws.reportStatus("7") })
	if code != 0 || !strings.Contains(out, "pane 12  idle  in "+ws.root) {
		t.Errorf("--status on an idle worker = %d, %q", code, out)
	}

	// A worker running a named run, which has to name the run and its log.
	os.WriteFile(ws.runningFile(), []byte("build\n"), 0o600)
	out = captured(t, func() { code = ws.reportStatus("7") })
	if code != 0 || !strings.Contains(out, "pane 12  running build  log "+ws.logFile("build")) {
		t.Errorf("--status on a busy worker = %d, %q", code, out)
	}
}

// The guard against running outside WezTerm splits nothing and never reaches the
// real mux.
//
// Without a fake installed this test passed for the wrong reason: dropping the
// guard let the call fall through to the real `wezterm`, which failed on an empty
// --pane-id and returned the same exit 2 the test asserted. A guard that no test
// protects, satisfied by an unrelated failure, in a test that shelled out to the
// owner's live mux during `go test`.
func TestRefusesOutsideWezTermWithoutTouchingTheMux(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "")
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	if code := Run([]string{"true"}); code != 2 {
		t.Errorf("Run outside wezterm = %d, want 2", code)
	}
	if len(mux.actions) != 0 {
		t.Errorf("the mux was called %d times: %v", len(mux.actions), mux.actions)
	}
	if len(mux.panes) != 1 {
		t.Errorf("panes = %v, want the one that was already there", mux.panes)
	}
}

// A working directory removed under the caller stops the call through `Run`, and
// splits nothing. Proved through the entry point rather than through `callerDir`:
// "splits nothing" is a claim about the call, and a helper cannot make it.
func TestARemovedWorkingDirectoryStopsTheCallAndSplitsNothing(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "7")
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	gone := filepath.Join(t.TempDir(), "gone")
	if err := os.MkdirAll(gone, 0o700); err != nil {
		t.Fatal(err)
	}
	t.Chdir(gone)
	if err := os.RemoveAll(gone); err != nil {
		t.Fatal(err)
	}

	if code := Run([]string{"true"}); code != 2 {
		t.Errorf("Run from a removed directory = %d, want 2", code)
	}
	if len(mux.actions) != 0 {
		t.Errorf("the mux was called before the directory was checked: %v", mux.actions)
	}
}

// A run name is validated before a pane exists, not after.
//
// It used to be checked inside `claim`, which runs once the worker has been
// resolved or split, so `-n ../escape` cost a pane on screen before the refusal.
// The numeric flags have always been checked at parse time; this is the same rule.
func TestABadRunNameIsRefusedBeforeAPaneIsCreated(t *testing.T) {
	state(t)
	t.Setenv("WEZTERM_PANE", "7")
	t.Chdir(t.TempDir())
	mux := &fakeMux{panes: []int{7}, split: 9}
	mux.install(t)

	for _, name := range []string{"../escape", "a/b", "last", "with\nbreak"} {
		if code := Run([]string{"-n", name, "true"}); code != 2 {
			t.Errorf("Run with -n %q = %d, want 2", name, code)
		}
	}
	if len(mux.actions) != 0 {
		t.Errorf("a refused name still cost mux calls: %v", mux.actions)
	}
	if n := mux.splits(); n != 0 {
		t.Errorf("panes split for a name that was always going to be refused = %d", n)
	}
}

// The bound on a mux call is real, and it is proved against a real process.
//
// The two functions that carry it, muxOutputCmd and muxRunCmd, were executed by no
// test: the unresponsive-mux test replaces them with a fake that returns an error,
// which proves the error is classified as errProbe and nothing about the timeout.
// A mux that stops answering is the failure the bash version had, which piped
// `wezterm cli list` into `jq` with no bound at all.
func TestAMuxCallIsBoundedByARealTimeout(t *testing.T) {
	stub := t.TempDir()
	script := filepath.Join(stub, "wezterm")
	if err := os.WriteFile(script, []byte("#!/bin/sh\nsleep 30\n"), 0o700); err != nil {
		t.Fatal(err)
	}
	t.Setenv("PATH", stub+string(os.PathListSeparator)+os.Getenv("PATH"))

	real := muxTimeout
	t.Cleanup(func() { muxTimeout = real })
	muxTimeout = 150 * time.Millisecond

	for _, probe := range []struct {
		name string
		call func() error
	}{
		{"muxOutputCmd", func() error { _, err := muxOutputCmd([]string{"cli", "list"}); return err }},
		{"muxRunCmd", func() error { return muxRunCmd([]string{"cli", "activate-pane"}, "") }},
	} {
		started := time.Now()
		err := probe.call()
		elapsed := time.Since(started)
		if err == nil {
			t.Errorf("%s: a mux that never answered returned no error", probe.name)
		} else if !strings.Contains(err.Error(), "no answer in") {
			t.Errorf("%s: error = %v, want it to name the bound", probe.name, err)
		}
		if elapsed > 3*time.Second {
			t.Errorf("%s: took %s, so the call was not bounded", probe.name, elapsed)
		}
	}
}

// A pane whose socket is not a gui-sock is refused, and the refusal quotes the
// value rather than asserting the variable is unset.
//
// Measured against an isolated wezterm-mux-server: a mux-server or unix-domain
// pane carries a well-formed socket path that MuxID does not accept, so every
// operation is refused for a caller whose `wezterm cli` works. Saying "unset or
// malformed" there is a false statement of cause and leaves no next step.
func TestASocketThatIsNotAGuiSockIsNamedInTheRefusal(t *testing.T) {
	state(t)
	mux := &fakeMux{panes: []int{7, 12}}
	mux.install(t)
	ws := workspaceIn(t, t.TempDir())
	ws.live(t, "12")

	t.Setenv("WEZTERM_UNIX_SOCKET", "/tmp/r3-probe-sock")
	_, err := ws.pane("7")
	if !errors.Is(err, errProbe) {
		t.Fatalf("pane() = %v, want an errProbe", err)
	}
	if !strings.Contains(err.Error(), `"/tmp/r3-probe-sock"`) {
		t.Errorf("refusal = %v, want it to quote the value it read", err)
	}
	if strings.Contains(err.Error(), "unset or malformed") {
		t.Errorf("refusal = %v, want no claim about a variable that is set and well formed", err)
	}
}
