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

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/repo"
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

const sessionOverride = "SYSINIT_WORKER_SESSION"

const timedOut = 75

const blockedReturn = 76

const directoryGone = 78

const paneClosed = 129

const maxWait = 365 * 24 * 60 * 60

var errProbe = errors.New("the mux did not answer")

var errSelf = errors.New("the record names the calling pane")

var (
	muxOutput = muxOutputCmd
	muxRun    = muxRunCmd

	pollInterval = 2 * time.Second

	settle = 250 * time.Millisecond

	muxTimeout = 5 * time.Second
)

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

	switch {
	case opts.status:
		return ws.reportStatus(pane)
	case opts.close:
		return ws.closePane(pane)
	case opts.release != "":
		return ws.release(pane, opts.release, opts.force)
	case opts.command == "":
		_, _ = fmt.Fprint(os.Stderr, usage)
		return fail(errors.New("no command"))
	}
	return ws.start(pane, dir, opts)
}

func fail(err error) int {
	fmt.Fprintf(os.Stderr, "worker: %v\n", err)
	return 2
}

type workspace struct {
	root string
	dir  string
}

func newWorkspace(dir string) (*workspace, error) {
	root := repo.Workspace(dir)

	override := strings.TrimSpace(os.Getenv(sessionOverride))
	if override == "" {
		return &workspace{root: root, dir: repo.WorkerDir(root)}, nil
	}
	if err := validRunName(override); err != nil {
		return nil, fmt.Errorf("%s=%q is not a single path element", sessionOverride, override)
	}

	if repo.WorkerKeyed(override) || legacyPaneKey(override) {
		return nil, fmt.Errorf(
			"%s=%q has the shape of a derived key, which would address another workspace's record; choose another name",
			sessionOverride, override)
	}
	return &workspace{root: root, dir: filepath.Join(paths.AgentWorker(), override)}, nil
}

func RecordDir(dir string) (record, root string, err error) {
	ws, err := newWorkspace(dir)
	if err != nil {
		return "", "", err
	}
	return ws.dir, ws.root, nil
}

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

func (w *workspace) pane(caller string) (string, error) {
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

func (w *workspace) generationMatches(id string) error {
	body, err := os.ReadFile(w.muxFile())
	if err != nil {
		return errors.New("no mux generation recorded, so the record is not current")
	}
	recorded := strings.TrimSpace(string(body))
	if recorded == "" || recorded == "0" {
		return fmt.Errorf("the recorded mux generation %q cannot be matched", recorded)
	}

	if now := currentMux(); recorded != now {
		return fmt.Errorf("pane %s belongs to mux %s, not %s", id, recorded, now)
	}
	return nil
}

func (w *workspace) start(caller, dir string, opts options) int {
	if err := os.MkdirAll(w.dir, 0o700); err != nil {
		return fail(err)
	}

	note := ""

	target, err := w.pane(caller)
	switch {
	case err == nil:
	case errors.Is(err, errProbe):
		return fail(fmt.Errorf("cannot tell whether pane %s is alive: %w", w.recordedID(), err))
	default:
		note = superseded(caller)
		id, splitErr := w.split(caller)
		if splitErr != nil {
			return fail(splitErr)
		}
		fmt.Print(note)
		target = id
	}

	if line := prune(note != ""); line != "" {
		fmt.Println(line)
	}

	name, err := w.claim(opts.name)
	if err != nil {
		return fail(err)
	}

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
	_ = os.Remove(w.rcFile(name))

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

func (w *workspace) recordedID() string {
	body, err := os.ReadFile(w.paneFile())
	if err != nil {
		return "?"
	}
	return strings.TrimSpace(string(body))
}

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

func (w *workspace) underLock(fn func() error) error {
	handle, err := os.OpenFile(w.lockFile(), os.O_CREATE|os.O_RDWR, 0o600)
	if err != nil {
		return err
	}
	defer func() { _ = handle.Close() }()
	if err := syscall.Flock(int(handle.Fd()), syscall.LOCK_EX); err != nil {
		return fmt.Errorf("could not lock %s: %w", w.lockFile(), err)
	}
	defer func() { _ = syscall.Flock(int(handle.Fd()), syscall.LOCK_UN) }()
	return fn()
}

func (w *workspace) claimExact(name string, reuse bool) error {
	created, err := os.OpenFile(w.logFile(name), os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err == nil {
		return created.Close()
	}
	if !errors.Is(err, os.ErrExist) {
		return err
	}

	if w.inFlight(name) {
		return fmt.Errorf(
			"a run named %s has recorded no exit code; wait for %s, or free the name with --release %s",
			name, w.rcFile(name), name)
	}
	if !reuse {
		return fmt.Errorf("the name %s is taken by a finished run", name)
	}

	_ = os.Remove(w.rcFile(name))
	_ = os.Remove(w.logFile(name))
	created, err = os.OpenFile(w.logFile(name), os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0o600)
	if err != nil {
		return fmt.Errorf("another caller took the name %s", name)
	}
	return created.Close()
}

func (w *workspace) rollback(name string) {
	_ = w.underLock(func() error {
		w.discard(name)
		return nil
	})
}

func (w *workspace) discard(name string) {
	for _, path := range []string{w.logFile(name), w.rcFile(name), w.bodyFile(name)} {
		_ = os.Remove(path)
	}
}

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

func clearBlocked() string {
	record := shellQuote(paths.AgentPanes()) + `/${WEZTERM_PANE:-none}.json`
	return fmt.Sprintf(
		"  [[ -f %s ]] && %s agent-state worker idle 'the worker run ended' < /dev/null > /dev/null 2>&1",
		record, shellQuote(self()))
}

var self = executable

func executable() string {
	path, err := os.Executable()
	if err != nil {
		return "utils"
	}
	return path
}

func (w *workspace) writeHeader(name, dir, command string) error {
	header := fmt.Sprintf("=== %s  %s\nin %s\n%s\n---\n",
		name, time.Now().Format("2006-01-02 15:04:05"), dir, command)
	return os.WriteFile(w.logFile(name), []byte(header), 0o600)
}

func (w *workspace) send(target, name, body string) error {
	line := fmt.Sprintf("\025clear; zsh %s 2>&1 | tee -a %s\n",
		shellQuote(body), shellQuote(w.logFile(name)))
	return muxRun([]string{"cli", "send-text", "--pane-id", target, "--no-paste"}, line)
}

func (w *workspace) retire(caller string) {
	marker := w.runningRun()
	if marker == "" {
		return
	}
	outgoing := w.recordedID()
	_ = os.Remove(w.runningFile())
	if outgoing == caller {
		return
	}
	if w.inFlight(marker) {
		_ = writeAtomic(w.rcFile(marker), strconv.Itoa(paneClosed))
	}
}

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

func prune(keepLegacy bool) string {
	root := paths.AgentWorker()

	entries, _ := os.ReadDir(root)

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
		case entry.IsDir() && repo.WorkerKeyed(name):
		case entry.IsDir() && legacyPaneKey(name):
			legacy++
			continue
		case entry.IsDir():
			override++
			continue
		default:
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

func removeDead(dir string) bool {
	handle, err := os.OpenFile(filepath.Join(dir, "worker-lock"), os.O_RDWR, 0o600)
	if errors.Is(err, os.ErrNotExist) {
		return os.RemoveAll(dir) == nil
	}
	if err != nil {
		return false
	}
	defer func() { _ = handle.Close() }()
	if syscall.Flock(int(handle.Fd()), syscall.LOCK_EX|syscall.LOCK_NB) != nil {
		return false
	}
	defer func() { _ = syscall.Flock(int(handle.Fd()), syscall.LOCK_UN) }()
	return os.RemoveAll(dir) == nil
}

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

	if err := writeAtomic(w.muxFile(), currentMux()); err != nil {
		return "", err
	}
	if err := writeAtomic(w.paneFile(), id); err != nil {
		return "", err
	}

	time.Sleep(time.Second)
	_ = muxRun([]string{"cli", "activate-pane", "--pane-id", caller}, "")
	return id, nil
}

func (w *workspace) linkLast(name string) {
	for _, pair := range [][2]string{
		{w.logFile(name), filepath.Join(w.dir, "last.log")},
		{w.rcFile(name), filepath.Join(w.dir, "last.rc")},
	} {
		_ = os.Remove(pair[1])
		_ = os.Symlink(pair[0], pair[1])
	}
}

func (w *workspace) bumpCounter() int {
	n := 0
	if body, err := os.ReadFile(w.counterFile()); err == nil {
		n, _ = strconv.Atoi(strings.TrimSpace(string(body)))
	}
	n++
	_ = writeAtomic(w.counterFile(), strconv.Itoa(n))
	return n
}

func (w *workspace) inFlight(name string) bool {
	if _, err := os.Stat(w.logFile(name)); err != nil {
		return false
	}
	_, err := os.Stat(w.rcFile(name))
	return err != nil
}

func (w *workspace) release(caller, name string, force bool) int {
	if err := validRunName(name); err != nil {
		return fail(err)
	}
	if _, err := os.Stat(w.logFile(name)); err != nil {
		fmt.Printf("no run named %s in %s\n", name, w.root)
		return 0
	}

	live := false
	switch _, err := w.pane(caller); {
	case err == nil, errors.Is(err, errSelf):
		live = true
	case errors.Is(err, errProbe):
		return fail(fmt.Errorf("cannot tell whether %s is still running: %w", name, err))
	}

	var refusal error

	if err := w.underLock(func() error {
		if !w.inFlight(name) {
			w.discard(name)
			return nil
		}

		if live && w.runningRun() == name {
			refusal = fmt.Errorf(
				"%s is running now in pane %s; wait for %s, or end it with --close",
				name, w.recordedID(), w.rcFile(name))
			return nil
		}

		if live && !force {
			refusal = fmt.Errorf(
				"%s has recorded no exit code and pane %s is alive, so it is queued or abandoned; wait for %s, or free it with --release %s --force, which breaks it if it was merely queued",
				name, w.recordedID(), w.rcFile(name), name)
			return nil
		}

		if w.runningRun() == name {
			_ = os.Remove(w.runningFile())
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
		return fail(fmt.Errorf("cannot tell whether pane %s is alive: %w", w.recordedID(), err))
	case errors.Is(err, errSelf):
		return fail(fmt.Errorf(
			"pane %s is this pane, which is the workspace's worker; close it from another pane, or exit it",
			w.recordedID()))
	case err != nil:
		fmt.Printf("no worker for %s (%v)%s\n", w.root, err, w.forget())
		return 0
	}
	if err := muxRun([]string{"cli", "kill-pane", "--pane-id", target}, ""); err != nil {
		return fail(fmt.Errorf("could not kill pane %s, so its record is kept: %w", target, err))
	}
	fmt.Printf("closed pane %s for %s%s%s\n", target, w.root, w.forget(), clearState(target))
	return 0
}

func clearState(target string) string {
	record, start := agentstate.PaneRecord(target)
	if _, err := os.Stat(record); err != nil {
		return ""
	}
	_ = os.Remove(record)
	_ = os.Remove(start)
	return "; its state record is removed"
}

func (w *workspace) forget() string {
	marker := w.runningRun()
	for _, path := range []string{w.paneFile(), w.muxFile(), w.runningFile()} {
		_ = os.Remove(path)
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

type waitEnd int

const (
	endExit waitEnd = iota
	endBlocked
	endTimeout
)

func (w *workspace) waitForExit(name string, seconds, tail int) int {
	return w.wait(name, "", seconds, tail)
}

func (w *workspace) waitForBlocked(name, target string, seconds, tail int) int {
	return w.wait(name, target, seconds, tail)
}

func (w *workspace) wait(name, target string, seconds, tail int) int {
	rc, reason, end := w.poll(name, target, seconds)
	switch end {
	case endTimeout:
		fmt.Fprintf(os.Stderr, "worker: still running after %ds; poll %s\n", seconds, w.rcFile(name))
		return timedOut
	case endBlocked:
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

func currentMux() string {
	return strconv.Itoa(agentstate.MuxID())
}

func paneAlive(id string) (bool, error) {
	live, err := livePanes()
	if err != nil {
		return false, err
	}
	return live[id], nil
}

func livePanes() (map[string]bool, error) {
	out, err := muxOutput([]string{"cli", "list", "--format", "json"})
	if err != nil {
		return nil, fmt.Errorf("%w: %w", errProbe, err)
	}
	var panes []struct {
		PaneID int `json:"pane_id"`
	}
	if err := json.Unmarshal([]byte(out), &panes); err != nil {
		return nil, fmt.Errorf("%w: could not read the pane list: %w", errProbe, err)
	}
	live := make(map[string]bool, len(panes))
	for _, p := range panes {
		live[strconv.Itoa(p.PaneID)] = true
	}
	return live, nil
}

func muxArgs(args []string) []string {
	if len(args) == 0 || args[0] != "cli" {
		return append([]string(nil), args...)
	}
	guarded := make([]string, 0, len(args)+1)
	guarded = append(guarded, "cli", "--no-auto-start")
	return append(guarded, args[1:]...)
}

func muxOutputCmd(args []string) (string, error) {
	ctx, cancel := context.WithTimeout(context.Background(), muxTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "wezterm", muxArgs(args)...)

	cmd.WaitDelay = muxTimeout
	out, err := cmd.Output()
	if ctx.Err() != nil {
		return "", fmt.Errorf("no answer in %s", muxTimeout)
	}
	return string(out), err
}

func muxRunCmd(args []string, stdin string) error {
	ctx, cancel := context.WithTimeout(context.Background(), muxTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, "wezterm", muxArgs(args)...)
	cmd.WaitDelay = muxTimeout
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
			return finish(opts, args[i+1:])
		case "-w", "--wait", "-b", "--wait-blocked", "-t", "--tail", "-n", "--name", "--release":
			if i+1 >= len(args) {
				return opts, fmt.Errorf("%s needs a value", arg)
			}
			i++
			value := args[i]
			switch arg {
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

func finish(opts options, words []string) (options, error) {
	if len(words) > 0 {
		if len(words) >= 2 && looksLikeRunName(words[0]) && strings.Contains(words[1], " ") {
			return opts, fmt.Errorf("%q looks like a run name, not a command; use: -n %s %s",
				words[0], words[0], shellQuote(words[1]))
		}
		opts.command = strings.Join(words, " ")
	}

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

	if opts.wait != nil && opts.blocked != nil {
		return opts, errors.New("-w and -b are two different waits; pass one")
	}
	if count := boolCount(opts.status, opts.close, opts.release != ""); count > 1 {
		return opts, errors.New("--status, --close, and --release are three different actions; pass one")
	}

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

func validRunName(name string) error {
	if name == "" {
		return errors.New("a run name cannot be empty")
	}
	if strings.ContainsAny(name, `/\`) || name == "." || name == ".." {
		return fmt.Errorf("run name %q is not a single path element", name)
	}
	if strings.ContainsAny(name, "\n\r") {
		return fmt.Errorf("run name %q contains a line break", name)
	}

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
