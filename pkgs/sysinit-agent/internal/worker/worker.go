// Package worker implements `worker`: send a command to one reused WezTerm pane and
// report the result through files.
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
  -b, --wait-blocked S like -w, and also returns 76 if the run asks for input
  -t, --tail N         log lines to print after a wait (default 20)
  -n, --name NAME      name this run, instead of run1, run2, and so on
      --status         report the workspace's pane and what it is running
      --close          kill the pane and forget it
      --release NAME   free a run name whose run recorded no exit code
      --force          with --release, free a name the worker pane may still reach
      --               end of flags; every word after it is the command

Every word after the flags is joined into one command, so both
` + "`worker git status`" + ` and ` + "`worker 'git status'`" + ` run the same thing.`

// sessionOverride names the environment variable that replaces the derived key with a
// literal one.
const sessionOverride = "SYSINIT_WORKER_SESSION"

// timedOut is the exit code for a wait that expired while the command ran on.
// Inherited from the bash implementation, where callers already branch on it.
const timedOut = 75

// blockedReturn is what `-b` returns when the caller's own run asked for input instead
// of finishing.
const blockedReturn = 76

// directoryGone is what the generated body records when the caller's directory
// disappeared while the run waited in the tty input buffer.
const directoryGone = 78

// paneClosed is what `--close` records for a run the pane was in the middle of.
// 129 is 128+SIGHUP, which is what the body's own trap would have written had it
// outlived the pane, so a caller branching on it needs no new case.
const paneClosed = 129

// maxWait clamps a requested wait to one year of seconds.
const maxWait = 365 * 24 * 60 * 60

// errProbe marks a liveness answer that could not be obtained.
var errProbe = errors.New("the mux did not answer")

// errSelf marks a record that names the pane doing the asking.
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

	// muxTimeout bounds one call to the mux.
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

	// The directory is created by `start` alone.
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
	// root is a DIRECTORY, always, even under the override.
	root string
	dir  string // the keyed state directory
}

// newWorkspace resolves the record for dir, honouring the explicit key override.
func newWorkspace(dir string) (*workspace, error) {
	root := repo.Workspace(dir)

	override := strings.TrimSpace(os.Getenv(sessionOverride))
	if override == "" {
		return &workspace{root: root, dir: repo.WorkerDir(root)}, nil
	}
	if err := validRunName(override); err != nil {
		return nil, fmt.Errorf("%s=%q is not a single path element", sessionOverride, override)
	}
	// A hatch that can forge either prune shape is not a hatch.
	if repo.WorkerKeyed(override) || legacyPaneKey(override) {
		return nil, fmt.Errorf(
			"%s=%q has the shape of a derived key, which would address another workspace's record; choose another name",
			sessionOverride, override)
	}
	return &workspace{root: root, dir: filepath.Join(paths.AgentWorker(), override)}, nil
}

// RecordDir returns the state directory holding the worker record for dir, and the
// workspace root it was keyed from.
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
func (w *workspace) pane(caller string) (string, error) {
	// Checked before the record is even read, and ahead of every other rejection.
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
func (w *workspace) generationMatches(id string) error {
	body, err := os.ReadFile(w.muxFile())
	if err != nil {
		return errors.New("no mux generation recorded, so the record is not current")
	}
	recorded := strings.TrimSpace(string(body))
	if recorded == "" || recorded == "0" {
		return fmt.Errorf("the recorded mux generation %q cannot be matched", recorded)
	}
	// `pane` has already established that this process has a generation of its own, so a
	// mismatch here is a real mismatch rather than an unknown: the record was written
	// blind or by an earlier mux.
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

	// Declared out here because the prune below reads it as well: a superseded worker
	// that is still alive holds the old root back for one more call.
	note := ""

	target, err := w.pane(caller)
	switch {
	case err == nil:
	case errors.Is(err, errProbe):
		// Never split here. An unanswerable probe means the answer is unknown, and
		// splitting on unknown is how a momentary stall orphans a live worker.
		return fail(fmt.Errorf("cannot tell whether pane %s is alive: %w", w.recordedID(), err))
	default:
		// Includes errSelf.
		note = superseded(caller)
		id, splitErr := w.split(caller)
		if splitErr != nil {
			return fail(splitErr)
		}
		fmt.Print(note)
		target = id
	}

	// Pruned here and nowhere else.
	if line := prune(note != ""); line != "" {
		fmt.Println(line)
	}

	// The name is claimed by creating its log exclusively, so two callers in one workspace
	// cannot be handed one name and then share one log and one exit code.
	name, err := w.claim(opts.name)
	if err != nil {
		return fail(err)
	}

	// Every failure between the claim and a successful send rolls the name back.
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

	switch {
	case opts.blocked != nil:
		return w.waitForBlocked(name, target, *opts.blocked, opts.tail)
	case opts.wait != nil:
		return w.waitForExit(name, *opts.wait, opts.tail)
	}
	return 0
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

// claim reserves a run name and creates its log in one step.
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

// discard removes one run's artifacts.
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
%[8]s
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
		clearBlocked(),
	)
	return os.WriteFile(path, []byte(body), 0o700)
}

// clearBlocked is the fragment of the trap that clears a `waiting` the run published,
// written to be indented two spaces inside `finish`.
func clearBlocked() string {
	record := shellQuote(paths.AgentPanes()) + `/${WEZTERM_PANE:-none}.json`
	return fmt.Sprintf(
		"  [[ -f %s ]] && %s agent-state worker idle 'the worker run ended' < /dev/null > /dev/null 2>&1",
		record, shellQuote(self()))
}

// self is the absolute path of this binary, for a generated body that has to call back
// into it.
var self = executable

func executable() string {
	path, err := os.Executable()
	if err != nil {
		// A PATH lookup is worse and it is still better than nothing: the alternative is
		// a body with no clear at all, which leaves a declared `waiting` on screen.
		return "sysinit-agent"
	}
	return path
}

func (w *workspace) writeHeader(name, dir, command string) error {
	header := fmt.Sprintf("=== %s  %s\nin %s\n%s\n---\n",
		name, time.Now().Format("2006-01-02 15:04:05"), dir, command)
	return os.WriteFile(w.logFile(name), []byte(header), 0o600)
}

// send types one line into the worker pane's shell.
func (w *workspace) send(target, name, body string) error {
	line := fmt.Sprintf("\025clear; zsh %s 2>&1 | tee -a %s\n",
		shellQuote(body), shellQuote(w.logFile(name)))
	return muxRun([]string{"cli", "send-text", "--pane-id", target, "--no-paste"}, line)
}

// retire clears the running marker belonging to the worker this call is about to
// replace, because the marker is part of the record and replacing a record means
// replacing all of it.
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

// prune removes every record whose WORKER pane is gone, disposes of the superseded
// root, and returns one report line, or "" when it did nothing worth saying.
func prune(keepLegacy bool) string {
	root := paths.AgentWorker()
	// The read error is not a reason to stop. An absent root holds no records, and the
	// superseded root below still has to go; returning here left it in place forever
	// on a machine whose first current-shape run had not happened yet.
	entries, _ := os.ReadDir(root)

	// Probed only when there is something to decide. A record's liveness is the only
	// question that needs the mux, so a call with no records does not pay for one.
	var live map[string]bool
	if len(entries) > 0 {
		answer, err := livePanes()
		if err != nil {
			return fmt.Sprintf("pruned nothing: %v", err)
		}
		live = answer
	}

	removed, override, legacy := 0, 0, 0
	for _, entry := range entries {
		name := entry.Name()
		switch {
		// The current shape is tested FIRST, before the superseded `pane-N` one and
		// before anything is removed. A workspace whose basename is literally `pane-3`
		// keys to `pane-3-<16 hex>`, which an unanchored `pane-*` test would claim.
		case entry.IsDir() && repo.WorkerKeyed(name):
		case entry.IsDir() && legacyPaneKey(name):
			legacy++
			continue
		case entry.IsDir():
			override++
			continue
		default:
			// A flat run artifact, or anything else that is not a record directory. The two
			// `last.*` symlinks are NOT in this count: they live INSIDE a record, beside the
			// run they point at, so nothing at this level is one of them.
			legacy++
			continue
		}
		id := ""
		if body, err := os.ReadFile(filepath.Join(root, name, "worker-pane")); err == nil {
			id = strings.TrimSpace(string(body))
		}
		if id == "" || live[id] {
			continue
		}
		if removeDead(filepath.Join(root, name)) {
			removed++
		}
	}

	old := ""
	if superseded := paths.AgentWtrun(); superseded != root && !keepLegacy {
		if _, err := os.Stat(superseded); err == nil && os.RemoveAll(superseded) == nil {
			old = "; removed the superseded wtrun root"
		}
	}
	if removed == 0 && old == "" {
		return ""
	}
	return fmt.Sprintf(
		"pruned %d record(s) whose worker pane was gone; kept %d, of which %d override-keyed and %d legacy%s",
		removed, len(entries)-removed, override, legacy, old)
}

// removeDead removes one record while holding its allocation lock, and reports whether
// it did.
func removeDead(dir string) bool {
	handle, err := os.OpenFile(filepath.Join(dir, "worker-lock"), os.O_RDWR, 0o600)
	if errors.Is(err, os.ErrNotExist) {
		// No lock file at all means no name has ever been claimed here, so there is
		// nothing to exclude. Creating one to lock it would make this read a write.
		return os.RemoveAll(dir) == nil
	}
	if err != nil {
		// A lock that cannot be examined is treated as held. This is the case the skip
		// exists for, and guessing the other way is the one mistake it cannot survive.
		return false
	}
	defer handle.Close()
	if syscall.Flock(int(handle.Fd()), syscall.LOCK_EX|syscall.LOCK_NB) != nil {
		return false
	}
	defer syscall.Flock(int(handle.Fd()), syscall.LOCK_UN)
	return os.RemoveAll(dir) == nil
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
	// The generation is written FIRST. A failure between the two writes then leaves a
	// generation with no pane id, which reads as no record; the other order would leave a
	// pane id with no generation, which is the case that used to be read as current.
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
func (w *workspace) release(caller, name string, force bool) int {
	if err := validRunName(name); err != nil {
		return fail(err)
	}
	if _, err := os.Stat(w.logFile(name)); err != nil {
		fmt.Printf("no run named %s in %s\n", name, w.root)
		return 0
	}

	// The pane is probed OUTSIDE the lock.
	live := false
	switch _, err := w.pane(caller); {
	case err == nil, errors.Is(err, errSelf):
		// errSelf belongs with the live case, not with the dead one.
		live = true
	case errors.Is(err, errProbe):
		return fail(fmt.Errorf("cannot tell whether %s is still running: %w", name, err))
	}

	var refusal error
	// Locked, and for the same reason the claim is: the decision reads the log and the
	// removal deletes it, and unlocked the two straddled another caller's claim of the
	// same name, so the release deleted a log and a body that belonged to a run that was
	// about to start.
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
		// marker still names its predecessor, or it may be abandoned because the caller died
		// between writing the log and reaching the send.
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
	if reason, yes := w.blocked(target, running); yes {
		fmt.Printf("pane %s  waiting %s: %s  log %s\n", target, running, reason, w.logFile(running))
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
		// The record is kept, and nothing is killed.
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
	fmt.Printf("closed pane %s for %s%s%s\n", target, w.root, w.forget(), clearState(target))
	return 0
}

// clearState removes the pane's state-bus record, and describes it when there was one.
func clearState(target string) string {
	record, start := agentstate.PaneRecord(target)
	if _, err := os.Stat(record); err != nil {
		return ""
	}
	os.Remove(record)
	os.Remove(start)
	return "; its state record is removed"
}

// forget removes the pane record and the running marker, records an exit code for a run
// the closed pane was in the middle of, and describes what it did.
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

// blocked reports the reason the worker pane is waiting on input on behalf of run name,
// and whether it is.
func (w *workspace) blocked(target, name string) (string, bool) {
	if target == "" || name == "" || w.runningRun() != name {
		return "", false
	}
	status, reason := agentstate.PaneStatus(target)
	if status != "waiting" {
		return "", false
	}
	if reason == "" {
		reason = status
	}
	return reason, true
}

// waitEnd is how a wait ended.
type waitEnd int

const (
	endExit waitEnd = iota
	endBlocked
	endTimeout
)

// waitForExit blocks until the run records an exit code, and returns it. A wait
// of 0 seconds never expires.
func (w *workspace) waitForExit(name string, seconds, tail int) int {
	return w.wait(name, "", seconds, tail)
}

// waitForBlocked also returns when the caller's own run asks for input, which is
// what `watch` names the worker pane for.
func (w *workspace) waitForBlocked(name, target string, seconds, tail int) int {
	return w.wait(name, target, seconds, tail)
}

// wait blocks until the run ends, or until it asks for input when target names
// the pane to watch, and returns the code for whichever happened.
func (w *workspace) wait(name, target string, seconds, tail int) int {
	rc, reason, end := w.poll(name, target, seconds)
	switch end {
	case endTimeout:
		fmt.Fprintf(os.Stderr, "worker: still running after %ds; poll %s\n", seconds, w.rcFile(name))
		return timedOut
	case endBlocked:
		// The tail is printed here for the same reason it is printed on an exit: the
		// prompt the run is waiting at is the last thing in the log, and a caller told
		// only that something is blocked has to go and read the file to find out what.
		w.drain(name)
		fmt.Printf("── %s is waiting on input: %s\n", name, reason)
		w.printTail(name, tail)
		return blockedReturn
	}
	w.drain(name)
	fmt.Printf("── %s tail (exit %d)\n", name, rc)
	w.printTail(name, tail)
	return rc
}

// drain waits for the log to stop growing before the tail is read.
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

// poll re-reads the exit-code file until it holds a number, and re-reads the worker
// pane's state as well when target names a pane.
func (w *workspace) poll(name, target string, seconds int) (int, string, waitEnd) {
	if seconds > maxWait {
		seconds = maxWait
	}
	deadline := time.Now().Add(time.Duration(seconds) * time.Second)
	for {
		if body, err := os.ReadFile(w.rcFile(name)); err == nil {
			if code, err := strconv.Atoi(strings.TrimSpace(string(body))); err == nil {
				return code, "", endExit
			}
		}
		if reason, yes := w.blocked(target, name); yes {
			return 0, reason, endBlocked
		}
		if seconds != 0 && !time.Now().Before(deadline) {
			return 0, "", endTimeout
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
	live, err := livePanes()
	if err != nil {
		return false, err
	}
	return live[id], nil
}

// livePanes returns the ids the mux currently has, as a set, so a caller with several
// ids to check pays one mux call rather than one each.
func livePanes() (map[string]bool, error) {
	out, err := muxOutput([]string{"cli", "list", "--format", "json"})
	if err != nil {
		return nil, fmt.Errorf("%w: %v", errProbe, err)
	}
	var panes []struct {
		PaneID int `json:"pane_id"`
	}
	if err := json.Unmarshal([]byte(out), &panes); err != nil {
		return nil, fmt.Errorf("%w: could not read the pane list: %v", errProbe, err)
	}
	live := make(map[string]bool, len(panes))
	for _, p := range panes {
		live[strconv.Itoa(p.PaneID)] = true
	}
	return live, nil
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
	blocked *int
	status  bool
	close   bool
	release string
	force   bool
	help    bool
}

// parse reads the flags by hand, matching `internal/editevent`.
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
		case "-w", "--wait", "-b", "--wait-blocked", "-t", "--tail", "-n", "--name", "--release":
			if i+1 >= len(args) {
				return opts, fmt.Errorf("%s needs a value", arg)
			}
			i++
			value := args[i]
			switch arg {
			// Both names are validated HERE, before a pane exists, for the same reason a numeric
			// flag is: `-n ../escape` used to be caught inside `claim`, which runs after the
			// worker has been resolved or split, so a name the call was always going to refuse
			// cost a pane on screen.
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
			case "-b", "--wait-blocked":
				n, err := nonNegative(arg, value)
				if err != nil {
					return opts, err
				}
				opts.blocked = &n
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
	// Two waits are two different contracts for one exit code, so passing both is a
	// question this command cannot answer. Silently preferring one would decide for
	// the caller whether 76 can come back, which is the whole reason `-b` is separate.
	if opts.wait != nil && opts.blocked != nil {
		return opts, errors.New("-w and -b are two different waits; pass one")
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
	// `last` is the alias, not a run.
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
