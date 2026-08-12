// Package worker implements `worker`: send a command to one reused WezTerm pane
// and report the result through files.
//
// It replaces a bash script called `wtrun`. Two things about the shape are
// load-bearing and easy to lose. The pane's tty input buffer is the queue, so
// this package does not schedule anything: a command sent while another is
// running waits in the terminal's buffer, and the ordering is the terminal's. And
// the pane is an ordinary interactive shell, so whatever the owner types into it
// also runs there.
//
// The pane is keyed on the workspace, not on the pane that asked for it. That is
// the defect this package exists to fix: a per-caller key made the worker
// unreachable as soon as its parent pane closed, so the next pane split a second
// worker beside a live one.
package worker

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
)

const Summary = "run a command in one reused WezTerm pane and report the result"

const usage = `usage: worker [-w SECONDS] [-t N] [-n NAME] <command...>
       worker --status | --close | --release NAME

  -w, --wait SECONDS   wait for the run to exit; 0 waits with no timeout
  -t, --tail N         log lines to print after a wait (default 20)
  -n, --name NAME      name this run, instead of run1, run2, and so on
      --status         report the workspace's pane and what it is running
      --close          kill the pane and forget it
      --release NAME   free a run name whose run recorded no exit code
      --force          with --release, free a name the worker pane may still reach
      --               end of flags; every word after it is the command

Every word after the flags is joined into one command, so both
` + "`worker git status`" + ` and ` + "`worker 'git status'`" + ` run the same thing.`

// sessionOverride names the environment variable that replaces the derived key
// with a literal one.
//
// Prefixed, because it is read out of the ambient environment. An unprefixed
// WORKER_SESSION exported by any unrelated tool would redirect every invocation in
// that shell into one shared key, and the in-flight refusal would then fire across
// unrelated workspaces. `paths.go` already reads SYSINIT_PATHS_MANIFEST for this
// same binary, so this matches what is here.
//
// Deliberately not the superseded WTRUN_SESSION, and not because the two
// implementations would collide: they read different roots, so they cannot. It is
// because `watch.go:222` reads WTRUN_SESSION and resolves it under the OLD root, so
// honouring that name here would aim the watcher at a path nothing writes, with no
// error. Task 2.9 repairs the watch side.
const sessionOverride = "SYSINIT_WORKER_SESSION"

// timedOut is the exit code for a wait that expired while the command ran on.
// Inherited from the bash implementation, where callers already branch on it.
const timedOut = 75

// directoryGone is what the generated body records when the caller's directory
// disappeared while the run waited in the tty input buffer.
//
// It MUST NOT be 2. The proposal requires a code distinguishable from the
// command's own, and 2 is an ordinary command status: `make` and `go test` both
// return it for an ordinary failure, and builds are this pane's documented
// workload. This sits with the 130, 143, and 129 the body records for signals.
const directoryGone = 78

// paneClosed is what `--close` records for a run the pane was in the middle of.
// 129 is 128+SIGHUP, which is what the body's own trap would have written had it
// outlived the pane, so a caller branching on it needs no new case.
const paneClosed = 129

// maxWait clamps a requested wait to one year of seconds. Without it,
// `time.Duration(seconds) * time.Second` overflows int64 above 9223372036 and the
// deadline lands in the past, so an absurdly large wait reported a timeout
// immediately instead of waiting.
const maxWait = 365 * 24 * 60 * 60

// errProbe marks a liveness answer that could not be obtained. It is distinct
// from an answer of "no such pane", and the distinction decides whether a caller
// may split a replacement: reading an unanswerable probe as absence turns a
// momentary mux stall into a second worker beside the live one, which is the
// orphan this package exists to prevent.
var errProbe = errors.New("the mux did not answer")

// errSelf marks a record that names the pane doing the asking.
//
// It is a statement about who is asking, not about whether the pane exists, and
// collapsing it into absence loses a live pane. `wtrun.sh:42` collapsed it, and
// `wtrun.sh:83` then removed the record whatever happened, so `wtrun --close` typed
// inside the worker pane deleted the record of a pane that was still on screen.
var errSelf = errors.New("the record names the calling pane")

// The mux calls and the two waits, as variables so a test can drive them without
// a terminal and without paying the real intervals. Production never reassigns
// them.
var (
	muxOutput = muxOutputCmd
	muxRun    = muxRunCmd

	// pollInterval is how often a wait re-reads the exit-code file.
	pollInterval = 2 * time.Second

	// settle is one step of the wait for `tee` to finish draining. The exit code is
	// written by a trap inside the pipeline, so it can land before the last lines of
	// output do.
	settle = 250 * time.Millisecond

	// muxTimeout bounds one call to the mux. The bash implementation piped `wezterm
	// cli list` into `jq` with no timeout, so a mux that stopped answering hung the
	// caller instead of failing it. A variable rather than a constant so the bound can
	// be tested against a real process: the two functions that carry it were reached by
	// no test, so the timeout, both context checks, and the message were unexercised,
	// and this is the half of the behaviour the bash version got wrong.
	muxTimeout = 5 * time.Second
)

// Run executes one invocation and returns the process exit code.
func Run(args []string) int {
	opts, err := parse(args)
	if err != nil {
		return fail(err)
	}
	if opts.help {
		fmt.Println(usage)
		return 0
	}

	pane := os.Getenv("WEZTERM_PANE")
	if pane == "" {
		return fail(errors.New("not inside a WezTerm pane"))
	}

	dir, err := callerDir()
	if err != nil {
		return fail(err)
	}

	ws, err := newWorkspace(dir)
	if err != nil {
		return fail(err)
	}

	// The directory is created by `start` alone. Creating it here made `--status` a
	// writer: every query minted an empty keyed directory, and the migration plan
	// tells the owner to run `--status` for the two-implementation comparison, so the
	// baseline that step 5 compares against was perturbed by the act of reading it.
	switch {
	case opts.status:
		return ws.reportStatus(pane)
	case opts.close:
		return ws.closePane(pane)
	case opts.release != "":
		return ws.release(pane, opts.release, opts.force)
	case opts.command == "":
		return fail(errors.New("no command\n\n" + usage))
	}
	return ws.start(pane, dir, opts)
}

func fail(err error) int {
	fmt.Fprintf(os.Stderr, "worker: %v\n", err)
	return 2
}

// workspace is one keyed state directory and the paths inside it.
type workspace struct {
	// root is a DIRECTORY, always, even under the override. Every line that prints
	// it says "in <root>", and the declared behaviour is that the output names the
	// directory the command runs in, so a bare key here would make one output slot
	// mean two different things.
	root string
	dir  string // the keyed state directory
}

// newWorkspace resolves the record for dir, honouring the explicit key override.
//
// The override is the escape hatch for a caller that wants a worker of its own,
// not a compatibility shim. A bad value FAILS rather than falling back to the
// derived key: the caller asked for isolation, and quietly handing back the shared
// record would aim `--close` and `--release` at another pane's worker and another
// run's name.
func newWorkspace(dir string) (*workspace, error) {
	root := repo.Workspace(dir)

	override := strings.TrimSpace(os.Getenv(sessionOverride))
	if override == "" {
		return &workspace{root: root, dir: repo.WorkerDir(root)}, nil
	}
	if err := validRunName(override); err != nil {
		return nil, fmt.Errorf("%s=%q is not a single path element", sessionOverride, override)
	}
	// A hatch that can forge either prune shape is not a hatch. The freely chosen
	// name is the point, so the constraint is only that it cannot impersonate a
	// derived key or the superseded per-pane key: the first would aim this call at
	// another workspace's record, and the second would make the phase-3 count
	// undecidable.
	if repo.WorkerKeyed(override) || legacyPaneKey(override) {
		return nil, fmt.Errorf(
			"%s=%q has the shape of a derived key, which would address another workspace's record; choose another name",
			sessionOverride, override)
	}
	return &workspace{root: root, dir: filepath.Join(paths.AgentWorker(), override)}, nil
}

// RecordDir returns the state directory holding the worker record for dir, and the
// workspace root it was keyed from.
//
// Exported for readers rather than writers. `watch` has to resolve the same
// directory this package writes, and the phase-1 review spent two rounds on defects
// that came from one rule having two definitions, so the derivation stays in one
// place and callers ask for it. The override is honoured here too, which is what
// makes a private worker watchable.
func RecordDir(dir string) (record, root string, err error) {
	ws, err := newWorkspace(dir)
	if err != nil {
		return "", "", err
	}
	return ws.dir, ws.root, nil
}

// legacyPaneKey reports whether name is the superseded `pane-<digits>` key.
func legacyPaneKey(name string) bool {
	rest, ok := strings.CutPrefix(name, "pane-")
	if !ok || rest == "" {
		return false
	}
	for _, r := range rest {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}

func (w *workspace) paneFile() string    { return filepath.Join(w.dir, "worker-pane") }
func (w *workspace) muxFile() string     { return filepath.Join(w.dir, "worker-mux") }
func (w *workspace) runningFile() string { return filepath.Join(w.dir, "worker-running") }
func (w *workspace) counterFile() string { return filepath.Join(w.dir, "worker-runs") }
func (w *workspace) lockFile() string    { return filepath.Join(w.dir, "worker-lock") }

func (w *workspace) logFile(name string) string  { return filepath.Join(w.dir, name+".log") }
func (w *workspace) rcFile(name string) string   { return filepath.Join(w.dir, name+".rc") }
func (w *workspace) bodyFile(name string) string { return filepath.Join(w.dir, name+".cmd") }

// pane returns the recorded pane id when it is usable.
//
// Four separate reasons make a record unusable, resolved here rather than at each
// call site. The pane may not be recorded. It may be the caller's own, which would
// race the caller's shell for one tty. Its generation may be missing, zero, or
// another mux's: pane ids restart at 0 when the mux restarts, measured on
// 2026-08-11 against an isolated mux server, so a low recorded id passes a liveness
// check against an unrelated new pane. And it may be gone.
//
// A probe that cannot answer is NOT one of the four. It returns errProbe, and no
// caller may read that as absence.
func (w *workspace) pane(caller string) (string, error) {
	// Checked before the record is even read, and ahead of every other rejection.
	// Without a generation of its own this process can neither verify a record nor
	// write one another process could verify, so every outcome is an unknown. Reading
	// it as absence lets `start` split a worker, write an equally unverifiable record,
	// and split again next time: one new pane per invocation, none reachable by
	// `--close`. Ordering matters as much as the check: testing the RECORDED value
	// first left that same loop reachable whenever both were blind.
	// The message names the variable's VALUE rather than asserting it is unset. A pane
	// from a mux server or a unix domain carries a well-formed socket path that is not
	// a `gui-sock-<n>`, so `MuxID` returns 0 for a caller whose `wezterm cli` works
	// perfectly. Measured against an isolated `wezterm-mux-server`: pane 1, socket
	// /tmp/r3-probe-sock, every operation refused. Saying "unset or malformed" there is
	// a false statement of cause and leaves the owner without a next step, so the value
	// is quoted and the supported shape is named instead.
	if currentMux() == "0" {
		return "", fmt.Errorf(
			"%w: this pane reports WEZTERM_UNIX_SOCKET=%q, which is not a gui-sock-<n> socket, so no record can be written or matched; a worker is supported from a GUI pane",
			errProbe, os.Getenv("WEZTERM_UNIX_SOCKET"))
	}

	recorded, err := os.ReadFile(w.paneFile())
	if err != nil {
		return "", errors.New("none recorded")
	}
	id := strings.TrimSpace(string(recorded))
	if id == "" {
		return "", errors.New("none recorded")
	}
	if id == caller {
		return "", errSelf
	}
	if err := w.generationMatches(id); err != nil {
		return "", err
	}
	alive, err := paneAlive(id)
	if err != nil {
		return "", err
	}
	if !alive {
		return "", fmt.Errorf("pane %s is gone", id)
	}
	return id, nil
}

// generationMatches rejects a record this mux generation cannot vouch for.
//
// Absent, empty, and "0" are all "not current", never "current". Treating an
// absent marker as current is what let a pane id from an earlier generation be
// reused, and "0" is what `agentstate.MuxID` returns when the socket is unset or
// malformed, so a record written under that condition would match every later
// generation that was equally blind.
func (w *workspace) generationMatches(id string) error {
	body, err := os.ReadFile(w.muxFile())
	if err != nil {
		return errors.New("no mux generation recorded, so the record is not current")
	}
	recorded := strings.TrimSpace(string(body))
	if recorded == "" || recorded == "0" {
		return fmt.Errorf("the recorded mux generation %q cannot be matched", recorded)
	}
	// `pane` has already established that this process has a generation of its own,
	// so a mismatch here is a real mismatch rather than an unknown: the record was
	// written blind or by an earlier mux. Splitting a replacement is therefore
	// correct AND terminating, because the record it writes is verifiable.
	if now := currentMux(); recorded != now {
		return fmt.Errorf("pane %s belongs to mux %s, not %s", id, recorded, now)
	}
	return nil
}

// start sends one run to the worker pane, splitting one if there is none.
func (w *workspace) start(caller, dir string, opts options) int {
	if err := os.MkdirAll(w.dir, 0o700); err != nil {
		return fail(err)
	}

	target, err := w.pane(caller)
	switch {
	case err == nil:
	case errors.Is(err, errProbe):
		// Never split here. An unanswerable probe means the answer is unknown, and
		// splitting on unknown is how a momentary stall orphans a live worker.
		return fail(fmt.Errorf("cannot tell whether pane %s is alive: %w", w.recordedID(), err))
	default:
		// Includes errSelf. A caller that is itself the recorded worker needs a worker
		// other than itself, and taking over the record is right: the old worker is the
		// caller's own pane, which is not orphaned by losing the role.
		//
		// Read before the split, so the line describes the state that made this call
		// split rather than the state after it.
		note := superseded(caller)
		id, splitErr := w.split(caller)
		if splitErr != nil {
			return fail(splitErr)
		}
		fmt.Print(note)
		target = id
	}

	// The name is claimed by creating its log exclusively, so two callers in one
	// workspace cannot be handed one name and then share one log and one exit code.
	// The counter alone could not do this: two processes read it, both increment,
	// and both get the same number.
	name, err := w.claim(opts.name)
	if err != nil {
		return fail(err)
	}

	// Every failure between the claim and a successful send rolls the name back.
	// Nothing has run, so a log with no exit code left behind reads as a run in
	// flight and burns the name for every pane in the workspace. Rolling back on the
	// send failure alone left two paths that burned it: a full disk, or the record
	// directory removed by hand while this call was in it.
	sent := false
	defer func() {
		if !sent {
			w.rollback(name)
		}
	}()

	body := w.bodyFile(name)
	if err := w.writeBody(body, name, dir, opts.command); err != nil {
		return fail(err)
	}
	if err := w.writeHeader(name, dir, opts.command); err != nil {
		return fail(err)
	}
	os.Remove(w.rcFile(name))

	if err := w.send(target, name, body); err != nil {
		return fail(err)
	}
	sent = true

	if queued := w.runningRun(); queued != "" && queued != name {
		fmt.Printf("pane %s  %s queued behind %s  in %s  log %s\n",
			target, name, queued, dir, w.logFile(name))
	} else {
		fmt.Printf("pane %s  %s  in %s  log %s\n", target, name, dir, w.logFile(name))
	}
	w.linkLast(name)

	if opts.wait == nil {
		return 0
	}
	return w.waitForExit(name, *opts.wait, opts.tail)
}

// recordedID returns the recorded pane id verbatim, for a message about a record
// this process could not verify.
func (w *workspace) recordedID() string {
	body, err := os.ReadFile(w.paneFile())
	if err != nil {
		return "?"
	}
	return strings.TrimSpace(string(body))
}

// claim reserves a run name and creates its log in one step. An empty requested
// name allocates run1, run2, and so on.
//
// Only an explicit name reuses a finished run's name. An allocated one moves past
// it, because the counter is not a reliable high-water mark: it lives in the same
// directory as the runs, so a removed or truncated counter file restarts numbering
// at 1 and would silently take run1's log with it.
//
// The whole allocation runs under a lock on the record. Reclaiming a finished run's
// name means removing a token another caller may be creating, and no ordering of
// remove and exclusive-create fixes that. Two attempts failed here, and the test
// caught both rather than the reasoning: remove-then-create let the second caller
// delete the log the first had just created, and rename-then-create let the second
// caller's rename succeed against that same fresh log.
func (w *workspace) claim(requested string) (string, error) {
	var name string
	err := w.underLock(func() error {
		if requested != "" {
			if err := validRunName(requested); err != nil {
				return err
			}
			name = requested
			return w.claimExact(requested, true)
		}
		for attempt := 0; attempt < 1000; attempt++ {
			candidate := "run" + strconv.Itoa(w.bumpCounter())
			if err := w.claimExact(candidate, false); err == nil {
				name = candidate
				return nil
			}
		}
		return errors.New("could not allocate a run name")
	})
	return name, err
}

// underLock runs fn holding an exclusive advisory lock on the record.
//
// The lock is per record, so two workspaces never wait on each other, and it is
// held only for the allocation, never across a mux call or a wait. `flock` is
// advisory and per open file description, so it serializes goroutines in one
// process and processes in one workspace alike, which is what two panes sharing a
// key needs.
func (w *workspace) underLock(fn func() error) error {
	handle, err := os.OpenFile(w.lockFile(), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return err
	}
	defer handle.Close()
	if err := syscall.Flock(int(handle.Fd()), syscall.LOCK_EX); err != nil {
		return fmt.Errorf("could not lock %s: %w", w.lockFile(), err)
	}
	defer syscall.Flock(int(handle.Fd()), syscall.LOCK_UN)
	return fn()
}

// claimExact creates name's log exclusively, so the winner of a race is decided
// by the filesystem rather than by ordering. reuse allows a finished run's name to
// be taken over, which discards that run's log.
func (w *workspace) claimExact(name string, reuse bool) error {
	created, err := os.OpenFile(w.logFile(name), os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err == nil {
		created.Close()
		return nil
	}
	if !errors.Is(err, os.ErrExist) {
		return err
	}
	// The name exists. Refuse it while its run has recorded no exit code, and reuse
	// it once that run has finished, which is what the superseded script always did.
	if w.inFlight(name) {
		return fmt.Errorf(
			"a run named %s has recorded no exit code; wait for %s, or free the name with --release %s",
			name, w.rcFile(name), name)
	}
	if !reuse {
		return fmt.Errorf("the name %s is taken by a finished run", name)
	}
	// Safe to remove and then create, because `claim` holds the record's lock. The
	// exclusive create stays as the inner check: it costs nothing, and it means a
	// caller reaching here without the lock still cannot silently double-claim.
	os.Remove(w.rcFile(name))
	os.Remove(w.logFile(name))
	created, err = os.OpenFile(w.logFile(name), os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("another caller took the name %s", name)
	}
	created.Close()
	return nil
}

// discard removes one run's artifacts. Used to roll back a run that never
// started, and by --release.
// rollback frees a name whose run never started.
//
// Named and separate from `discard` because it takes the allocation lock, for the
// same reason the claim does: it removes the log that IS the claim, and unlocked
// the read-decide-remove straddled another caller's claim of the same name, so it
// deleted a freshly claimed log and body rather than its own abandoned ones.
func (w *workspace) rollback(name string) {
	w.underLock(func() error {
		w.discard(name)
		return nil
	})
}

func (w *workspace) discard(name string) {
	for _, path := range []string{w.logFile(name), w.rcFile(name), w.bodyFile(name)} {
		os.Remove(path)
	}
}

// writeBody generates the script the worker pane runs.
//
// The command goes into a file rather than into the keystrokes, so a quote, a
// newline, or a glob cannot change meaning in transit.
//
// Two things in here fix defects the bash version had. The exit code is written
// from a trap, so the ordinary ways out of a run record one: zsh abandons the rest
// of a `;` list when an interrupt arrives, measured, so the tail that recorded the
// code and removed the marker did not run and the name stayed burned. The trap does
// NOT cover SIGKILL, an `exec`, or a command that clears it, so `--close` and
// `--release` both reclaim a marker with no owner. And the `cd` is checked here as
// well as in the caller, because the two happen minutes apart: the caller checks
// before splitting, and this runs when the previous command finishes.
func (w *workspace) writeBody(path, name, dir, command string) error {
	body := fmt.Sprintf(`#!/usr/bin/env zsh
# Record an exit code however this run ends, including on a signal.
#
# The order in here is load-bearing, and it is the reverse of the obvious one. The
# exit code is published LAST, because publishing it is what tells every other
# process that this name is free: claimExact's refusal names the rc file to wait
# for, and so does the wait timeout. Writing the code first and then deleting the
# body left a window, measured at up to 19.7ms and hit in 20 of 20 rounds, in which
# a successor reusing the name had already written ITS body to the same path and
# this trap deleted it. The pane was then told to run a file that no longer existed,
# so nothing ran, no trap fired, no exit code was ever written, and the caller
# printed a start line and exited 0.
finish() {
  local code=$?
  # The body is dead once the run is over, and nothing else would ever remove it:
  # 13 of the 41 entries in the live superseded record are dead bodies. Measured
  # safe, twice: zsh runs a 300-line script to completion after the script is
  # deleted mid-run, and a trap can remove the file it is running from. It is named
  # literally rather than as $0, because zsh sets FUNCTION_ARGZERO and $0 inside a
  # function is the function's name.
  rm -f %[7]s
  # Removed only while it still names THIS run. One marker path serves the whole
  # workspace, so a pane that handed over the worker role and kept running would
  # otherwise delete the marker belonging to the pane that replaced it, leaving
  # --status reporting idle for a pane that is running something.
  [[ "$(cat %[2]s 2>/dev/null)" == %[3]s ]] && rm -f %[2]s
  print -r -- $code > %[1]s.new && mv %[1]s.new %[1]s
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

print -r -- %[3]s > %[2]s
dir=%[4]s
# Quoted, so the run does not depend on the owner's zsh options: SH_WORD_SPLIT in
# a sourced ~/.zshenv would split a directory name containing a space.
cd -- "$dir" || { print -u2 -r -- "worker: $dir is gone"; exit %[5]d; }
%[6]s
`,
		shellQuote(w.rcFile(name)),
		shellQuote(w.runningFile()),
		shellQuote(name),
		shellQuote(dir),
		directoryGone,
		command,
		shellQuote(path),
	)
	return os.WriteFile(path, []byte(body), 0o700)
}

func (w *workspace) writeHeader(name, dir, command string) error {
	header := fmt.Sprintf("=== %s  %s\nin %s\n%s\n---\n",
		name, time.Now().Format("2006-01-02 15:04:05"), dir, command)
	return os.WriteFile(w.logFile(name), []byte(header), 0o600)
}

// send types one line into the worker pane's shell.
//
// The leading \025 is C-u: it discards whatever is already sitting in the input
// line. Without it a stray keystroke prefixes the command and it silently does
// not run.
func (w *workspace) send(target, name, body string) error {
	line := fmt.Sprintf("\025clear; zsh %s 2>&1 | tee -a %s\n",
		shellQuote(body), shellQuote(w.logFile(name)))
	return muxRun([]string{"cli", "send-text", "--pane-id", target, "--no-paste"}, line)
}

// retire clears the running marker belonging to the worker this call is about to
// replace, because the marker is part of the record and replacing a record means
// replacing all of it.
//
// Leaving it behind made a fresh pane inherit a run it never had: the start line
// said "queued behind run1", `--status` reported "running run1" on a pane that had
// run one command, and `--close` later recorded exit 129 for run1 against a pane
// that was never the one running it.
//
// Whether an exit code is recorded depends on which pane is losing the role, and
// the difference is the whole point:
//
//   - The outgoing pane is GONE. Its run can never finish and can never write its
//     own code, so 129 is recorded, the same value and for the same reason as in
//     `forget`.
//   - The outgoing pane is the CALLER, handing the role over while it keeps
//     running. Its run is still executing and its own trap still owns the exit
//     code, so recording one here would report a code for a live run, and the
//     trap would later overwrite it. Only the marker is cleared.
func (w *workspace) retire(caller string) {
	marker := w.runningRun()
	if marker == "" {
		return
	}
	outgoing := w.recordedID()
	os.Remove(w.runningFile())
	if outgoing == caller {
		return
	}
	if w.inFlight(marker) {
		writeAtomic(w.rcFile(marker), strconv.Itoa(paneClosed))
	}
}

// superseded describes a worker the bash script's per-pane record still holds, or
// returns "" when there is nothing to explain.
//
// The first run in a workspace splits a pane even though the owner can see a
// perfectly good worker on screen, because that worker is recorded under the
// caller's pane id and this command keys on the workspace. Unexplained, that reads
// as a bug in the new command. It is only a report: the old worker keeps running,
// keeps its record, and is neither adopted nor killed. Adopting it is not an
// option, because the record carries no mux generation, so an id that matches a
// live pane is not proof it is the same pane. The line says "may" for that reason.
//
// Keyed on the caller's pane only. The old script also honoured WTRUN_SESSION,
// which this command has dropped, and reading that name back in to widen a
// courtesy message would keep a superseded variable alive.
func superseded(caller string) string {
	if caller == "" {
		return ""
	}
	body, err := os.ReadFile(filepath.Join(paths.AgentWtrun(), "pane-"+caller, "worker-pane"))
	if err != nil {
		return ""
	}
	id := strings.TrimSpace(string(body))
	if id == "" || id == caller {
		return ""
	}
	if alive, err := paneAlive(id); err != nil || !alive {
		return ""
	}
	return fmt.Sprintf(
		"a worker from the superseded script may still hold pane %s, recorded under pane-%s with no mux generation to confirm it; it is left alone, so this run gets a worker of its own\n",
		id, caller)
}

// split creates the worker pane below the caller and returns focus to the
// caller, so a build does not pull the owner out of the conversation.
func (w *workspace) split(caller string) (string, error) {
	w.retire(caller)
	out, err := muxOutput([]string{
		"cli", "split-pane", "--pane-id", caller, "--bottom", "--percent", "40",
	})
	if err != nil {
		return "", fmt.Errorf("could not create a pane: %w", err)
	}
	id := digits(out)
	if id == "" {
		return "", fmt.Errorf("could not read a pane id from %q", strings.TrimSpace(out))
	}
	// The generation is written FIRST. A failure between the two writes then leaves
	// a generation with no pane id, which reads as no record; the other order would
	// leave a pane id with no generation, which is the case that used to be read as
	// current.
	if err := writeAtomic(w.muxFile(), currentMux()); err != nil {
		return "", err
	}
	if err := writeAtomic(w.paneFile(), id); err != nil {
		return "", err
	}
	// The new shell has to reach its prompt before it will accept the line.
	time.Sleep(time.Second)
	muxRun([]string{"cli", "activate-pane", "--pane-id", caller}, "")
	return id, nil
}

func (w *workspace) linkLast(name string) {
	for _, pair := range [][2]string{
		{w.logFile(name), filepath.Join(w.dir, "last.log")},
		{w.rcFile(name), filepath.Join(w.dir, "last.rc")},
	} {
		os.Remove(pair[1])
		os.Symlink(pair[0], pair[1])
	}
}

// bumpCounter returns the next run number. It is a hint, not a reservation:
// `claimExact` decides who gets the name.
func (w *workspace) bumpCounter() int {
	n := 0
	if body, err := os.ReadFile(w.counterFile()); err == nil {
		n, _ = strconv.Atoi(strings.TrimSpace(string(body)))
	}
	n++
	writeAtomic(w.counterFile(), strconv.Itoa(n))
	return n
}

// inFlight reports whether a run of this name has started and recorded no exit
// code. A name with no log has never run, so it is free.
func (w *workspace) inFlight(name string) bool {
	if _, err := os.Stat(w.logFile(name)); err != nil {
		return false
	}
	_, err := os.Stat(w.rcFile(name))
	return err != nil
}

// release frees one run's name without touching any other run in the workspace.
//
// Removing the whole record cannot serve this purpose: it would discard every
// other run's log.
func (w *workspace) release(caller, name string, force bool) int {
	if err := validRunName(name); err != nil {
		return fail(err)
	}
	if _, err := os.Stat(w.logFile(name)); err != nil {
		fmt.Printf("no run named %s in %s\n", name, w.root)
		return 0
	}

	// The pane is probed OUTSIDE the lock. The probe costs up to muxTimeout, and
	// blocking every claim in the workspace for five seconds behind one query is a
	// worse trade than a liveness answer that is a moment old. What has to be atomic
	// is the in-flight test and the removal, not the probe.
	live := false
	switch _, err := w.pane(caller); {
	case err == nil, errors.Is(err, errSelf):
		// errSelf belongs with the live case, not with the dead one. The caller IS the
		// worker, so a run executing here is executing in the caller's own pane: the one
		// state in which it is certainly live. Treating it as absence unlinked a running
		// run's log while `tee` kept writing to the unlinked inode.
		live = true
	case errors.Is(err, errProbe):
		return fail(fmt.Errorf("cannot tell whether %s is still running: %w", name, err))
	}

	var refusal error
	// Locked, and for the same reason the claim is: the decision reads the log and the
	// removal deletes it, and unlocked the two straddled another caller's claim of the
	// same name, so the release deleted a log and a body that belonged to a run that
	// was about to start.
	if err := w.underLock(func() error {
		if !w.inFlight(name) {
			w.discard(name)
			return nil
		}
		// The marker names it, so it is not "could be running", it IS running: the body
		// writes the marker as its first act. No --force here, because forcing it is the
		// unlink-while-tee-writes harm with an extra step.
		if live && w.runningRun() == name {
			refusal = fmt.Errorf(
				"%s is running now in pane %s; wait for %s, or end it with --close",
				name, w.recordedID(), w.rcFile(name))
			return nil
		}
		// A missing exit code with a live pane is genuinely ambiguous, and it is not
		// decidable from state: the run may be queued in the tty input buffer, where the
		// marker still names its predecessor, or it may be abandoned because the caller
		// died between writing the log and reaching the send. Refusing outright made the
		// name unrecoverable for as long as the worker lived, which is the property that
		// got prune-as-release rejected in the design. So the default still refuses, and
		// --force is the way back, with the cost named rather than discovered.
		if live && !force {
			refusal = fmt.Errorf(
				"%s has recorded no exit code and pane %s is alive, so it is queued or abandoned; wait for %s, or free it with --release %s --force, which breaks it if it was merely queued",
				name, w.recordedID(), w.rcFile(name), name)
			return nil
		}
		// Either no usable pane, so nothing can ever run this name, or the owner forced
		// it. A marker naming the run has no owner either: the pane died before its trap
		// could clear it.
		if w.runningRun() == name {
			os.Remove(w.runningFile())
		}
		w.discard(name)
		return nil
	}); err != nil {
		return fail(err)
	}
	if refusal != nil {
		return fail(refusal)
	}
	fmt.Printf("released %s in %s\n", name, w.root)
	return 0
}

// runningRun returns the run the pane last started, or "" when the marker is
// absent. The marker is empty while a command sits in the tty input buffer, so
// its absence does not mean the pane is free.
func (w *workspace) runningRun() string {
	body, err := os.ReadFile(w.runningFile())
	if err != nil {
		return ""
	}
	return strings.TrimSpace(string(body))
}

func (w *workspace) reportStatus(caller string) int {
	target, err := w.pane(caller)
	switch {
	case errors.Is(err, errProbe):
		// Not "no worker". The record may name a live pane; this process cannot tell.
		return fail(fmt.Errorf("cannot report on pane %s: %w", w.recordedID(), err))
	case errors.Is(err, errSelf):
		fmt.Printf("pane %s is this pane, which is the workspace's worker  in %s\n", w.recordedID(), w.root)
		return 0
	case err != nil:
		fmt.Printf("no worker for %s (%v)\n", w.root, err)
		return 0
	}
	running := w.runningRun()
	if running == "" {
		fmt.Printf("pane %s  idle  in %s\n", target, w.root)
		return 0
	}
	fmt.Printf("pane %s  running %s  log %s\n", target, running, w.logFile(running))
	return 0
}

func (w *workspace) closePane(caller string) int {
	target, err := w.pane(caller)
	switch {
	case errors.Is(err, errProbe):
		// The record is kept. Clearing it while the pane's state is unknown could
		// leave a live pane with nothing addressing it.
		return fail(fmt.Errorf("cannot tell whether pane %s is alive: %w", w.recordedID(), err))
	case errors.Is(err, errSelf):
		// The record is kept, and nothing is killed. errSelf says who is asking, not
		// whether the pane exists, and the pane doing the asking certainly exists.
		// Reading it as absence deleted the record of a pane that was still on screen,
		// and the next call then split a second worker beside it.
		return fail(fmt.Errorf(
			"pane %s is this pane, which is the workspace's worker; close it from another pane, or exit it",
			w.recordedID()))
	case err != nil:
		// The record is unusable, so it is stale, so it is cleared. This is the only
		// path that reclaims a running marker left by a pane that died before its
		// trap; without it a run name stays burned with no way to release it.
		fmt.Printf("no worker for %s (%v)%s\n", w.root, err, w.forget())
		return 0
	}
	if err := muxRun([]string{"cli", "kill-pane", "--pane-id", target}, ""); err != nil {
		// The record is kept, deliberately. The superseded script removed it whatever
		// happened, which left a live pane unreachable on a failed kill.
		return fail(fmt.Errorf("could not kill pane %s, so its record is kept: %w", target, err))
	}
	fmt.Printf("closed pane %s for %s%s\n", target, w.root, w.forget())
	return 0
}

// forget removes the pane record and the running marker, records an exit code for
// a run the closed pane was in the middle of, and describes what it did.
//
// The exit code matters as much as the marker. Killing the pane leaves the run's
// log with no `.rc`, which reads as a run in flight, so `--close` silently burned
// that name for the whole workspace while printing a message that read like
// cleanup finishing. The code is 129, which is what the body's own HUP trap would
// have recorded had it survived the pane.
func (w *workspace) forget() string {
	marker := w.runningRun()
	for _, path := range []string{w.paneFile(), w.muxFile(), w.runningFile()} {
		os.Remove(path)
	}
	if marker == "" {
		return ""
	}
	if !w.inFlight(marker) {
		return fmt.Sprintf("; reclaimed a marker naming %s", marker)
	}
	if err := writeAtomic(w.rcFile(marker), strconv.Itoa(paneClosed)); err != nil {
		return fmt.Sprintf("; %s recorded no exit code and its name is still in use", marker)
	}
	return fmt.Sprintf("; %s was running, and is recorded as exit %d", marker, paneClosed)
}

// waitForExit blocks until the run records an exit code, and returns it. A wait
// of 0 seconds never expires.
func (w *workspace) waitForExit(name string, seconds, tail int) int {
	rc, ok := w.pollExit(name, seconds)
	if !ok {
		fmt.Fprintf(os.Stderr, "worker: still running after %ds; poll %s\n", seconds, w.rcFile(name))
		return timedOut
	}
	w.drain(name)
	fmt.Printf("── %s tail (exit %d)\n", name, rc)
	w.printTail(name, tail)
	return rc
}

// drain waits for the log to stop growing before the tail is read.
//
// The exit code is written by a trap inside the pipeline, so it can appear while
// `tee` is still writing. A fixed pause was a guess about a race the code never
// observed; this observes it, with the pause as one step rather than the whole
// budget. Bounded, because a command that leaves a writer running behind it must
// not hold the caller open.
func (w *workspace) drain(name string) {
	previous := int64(-1)
	for step := 0; step < 20; step++ {
		time.Sleep(settle)
		info, err := os.Stat(w.logFile(name))
		if err != nil {
			return
		}
		if info.Size() == previous {
			return
		}
		previous = info.Size()
	}
}

// pollExit re-reads the exit-code file until it holds a number. It measures the
// wait against a deadline rather than counting polls, so the interval can be
// changed without silently rounding the timeout to zero.
func (w *workspace) pollExit(name string, seconds int) (int, bool) {
	if seconds > maxWait {
		seconds = maxWait
	}
	deadline := time.Now().Add(time.Duration(seconds) * time.Second)
	for {
		if body, err := os.ReadFile(w.rcFile(name)); err == nil {
			if code, err := strconv.Atoi(strings.TrimSpace(string(body))); err == nil {
				return code, true
			}
		}
		if seconds != 0 && !time.Now().Before(deadline) {
			return 0, false
		}
		time.Sleep(pollInterval)
	}
}

func (w *workspace) printTail(name string, lines int) {
	body, err := os.ReadFile(w.logFile(name))
	if err != nil || lines == 0 {
		return
	}
	all := strings.Split(strings.TrimRight(string(body), "\n"), "\n")
	if len(all) > lines {
		all = all[len(all)-lines:]
	}
	fmt.Println(strings.Join(all, "\n"))
}

// callerDir returns the directory the command runs in, and fails if it is gone.
//
// The worker pane keeps whatever directory it was created in, and the caller's
// never reached it: a build run from one checkout resolved `.` to another, built
// the wrong flake, and rewrote the wrong lockfile, with no output naming a
// directory.
func callerDir() (string, error) {
	dir, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("the working directory is gone: %w", err)
	}
	info, err := os.Stat(dir)
	if err != nil || !info.IsDir() {
		return "", fmt.Errorf("%s is not a directory", dir)
	}
	return dir, nil
}

// currentMux is this process's mux generation, as a string because it is only
// ever compared and written. It reuses the pane bus's rule so the two agree
// about what a generation is.
func currentMux() string {
	return strconv.Itoa(agentstate.MuxID())
}

// paneAlive reports whether the mux still has a pane with this id. A probe that
// cannot answer returns errProbe, never false.
func paneAlive(id string) (bool, error) {
	out, err := muxOutput([]string{"cli", "list", "--format", "json"})
	if err != nil {
		return false, fmt.Errorf("%w: %v", errProbe, err)
	}
	var panes []struct {
		PaneID int `json:"pane_id"`
	}
	if err := json.Unmarshal([]byte(out), &panes); err != nil {
		return false, fmt.Errorf("%w: could not read the pane list: %v", errProbe, err)
	}
	for _, p := range panes {
		if strconv.Itoa(p.PaneID) == id {
			return true, nil
		}
	}
	return false, nil
}

func muxOutputCmd(args []string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), muxTimeout)
	defer cancel()
	out, err := exec.CommandContext(ctx, "wezterm", args...).Output()
	if ctx.Err() != nil {
		return "", fmt.Errorf("no answer in %s", muxTimeout)
	}
	return string(out), err
}

func muxRunCmd(args []string, stdin string) error {
	ctx, cancel := context.WithTimeout(context.Background(), muxTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "wezterm", args...)
	if stdin != "" {
		cmd.Stdin = strings.NewReader(stdin)
	}
	if err := cmd.Run(); err != nil {
		if ctx.Err() != nil {
			return fmt.Errorf("no answer in %s", muxTimeout)
		}
		return err
	}
	return nil
}

// writeAtomic replaces path's contents in one step, so a reader never sees a
// half-written record and an interrupted write never empties one.
func writeAtomic(path, content string) error {
	temporary := path + ".new"
	if err := os.WriteFile(temporary, []byte(content+"\n"), 0o600); err != nil {
		return err
	}
	return os.Rename(temporary, path)
}

type options struct {
	name    string
	command string
	tail    int
	wait    *int
	status  bool
	close   bool
	release string
	force   bool
	help    bool
}

// parse reads the flags by hand, matching `internal/editevent`.
//
// A flag that wants a number rejects anything else before any pane exists. The
// bash version read `-w -t 900` as a wait of the literal string `-t`, left `900`
// as the command, split a pane, and ran `900` in it.
func parse(args []string) (options, error) {
	opts := options{tail: 20}
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "-h", "--help":
			opts.help = true
			return opts, nil
		case "--status":
			opts.status = true
		case "--close":
			opts.close = true
		case "--force":
			opts.force = true
		case "--":
			// End of flags: every word after this is the command, dashes and all.
			return finish(opts, args[i+1:])
		case "-w", "--wait", "-t", "--tail", "-n", "--name", "--release":
			if i+1 >= len(args) {
				return opts, fmt.Errorf("%s needs a value", arg)
			}
			i++
			value := args[i]
			switch arg {
			// Both names are validated HERE, before a pane exists, for the same reason a
			// numeric flag is: `-n ../escape` used to be caught inside `claim`, which runs
			// after the worker has been resolved or split, so a name the call was always
			// going to refuse cost a pane on screen. `claimExact` still checks, because it
			// is the one place that turns a name into a file.
			case "-n", "--name":
				if err := validRunName(value); err != nil {
					return opts, err
				}
				opts.name = value
			case "--release":
				if err := validRunName(value); err != nil {
					return opts, err
				}
				opts.release = value
			case "-t", "--tail":
				n, err := nonNegative(arg, value)
				if err != nil {
					return opts, err
				}
				opts.tail = n
			case "-w", "--wait":
				n, err := nonNegative(arg, value)
				if err != nil {
					return opts, err
				}
				opts.wait = &n
			}
		default:
			if strings.HasPrefix(arg, "-") {
				return opts, fmt.Errorf("unknown flag %s", arg)
			}
			return finish(opts, args[i:])
		}
	}
	return finish(opts, nil)
}

// finish joins the remaining words into one command, the way the superseded
// script's `"$*"` did, so `worker git status` runs `git status` rather than
// reporting a second command.
func finish(opts options, words []string) (options, error) {
	if len(words) > 0 {
		// The log-name mistake. `worker build 'nix build .#foo'` reads as a name and a
		// command, and joining them would run `build nix build .#foo`. Caught with the
		// corrected invocation, as the script did.
		if len(words) >= 2 && looksLikeRunName(words[0]) && strings.Contains(words[1], " ") {
			return opts, fmt.Errorf("%q looks like a run name, not a command; use: -n %s %s",
				words[0], words[0], shellQuote(words[1]))
		}
		opts.command = strings.Join(words, " ")
	}
	// A mode flag with a command would have discarded the command and exited 0,
	// which an agent reads as the command having run.
	if opts.command != "" {
		for _, mode := range []struct {
			set  bool
			name string
		}{
			{opts.status, "--status"},
			{opts.close, "--close"},
			{opts.release != "", "--release"},
		} {
			if mode.set {
				return opts, fmt.Errorf("%s takes no command, and %q would not have run", mode.name, opts.command)
			}
		}
	}
	if count := boolCount(opts.status, opts.close, opts.release != ""); count > 1 {
		return opts, errors.New("--status, --close, and --release are three different actions; pass one")
	}
	// --force modifies --release and nothing else. Accepting it anywhere would make
	// `worker --force <command>` look like it did something, and it would have run the
	// command with the flag silently ignored.
	if opts.force && opts.release == "" {
		return opts, errors.New("--force only modifies --release NAME")
	}
	return opts, nil
}

func boolCount(values ...bool) int {
	n := 0
	for _, value := range values {
		if value {
			n++
		}
	}
	return n
}

// looksLikeRunName matches the shape the superseded script tested for: a lower
// case word a caller might have meant as `-n`.
func looksLikeRunName(s string) bool {
	if s == "" || s[0] < 'a' || s[0] > 'z' {
		return false
	}
	for _, r := range s[1:] {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9', r == '_', r == '-':
		default:
			return false
		}
	}
	return true
}

func nonNegative(flag, value string) (int, error) {
	n, err := strconv.Atoi(value)
	if err != nil || n < 0 {
		return 0, fmt.Errorf("%s wants a non-negative whole number, got %q", flag, value)
	}
	return n, nil
}

// validRunName keeps a run name to one path element, because it is used as a
// filename and a separator would let it escape the workspace's directory.
func validRunName(name string) error {
	if name == "" {
		return errors.New("a run name cannot be empty")
	}
	if strings.ContainsAny(name, `/\`) || name == "." || name == ".." {
		return fmt.Errorf("run name %q is not a single path element", name)
	}
	if strings.ContainsAny(name, "\n\r") {
		// The reported counts are line-oriented, so a name holding a newline makes them
		// undecidable.
		return fmt.Errorf("run name %q contains a line break", name)
	}
	// `last` is the alias, not a run. `-n last` made its own log unreadable: the
	// reuse path removed the `last.log` symlink, the run created a regular file with
	// that name, and `linkLast` then removed that file and pointed the symlink at
	// itself. Measured: every read of the result returns ELOOP, so the command ran
	// and reported its exit code with its entire output gone.
	if name == "last" {
		return errors.New("`last` is the alias for the most recent run, so it cannot name one")
	}
	return nil
}

func shellQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func digits(s string) string {
	var b strings.Builder
	for _, r := range s {
		if r >= '0' && r <= '9' {
			b.WriteRune(r)
		}
	}
	return b.String()
}
