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
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/agentstate"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/repo"
)

const Summary = "run a command in one reused WezTerm pane and report the result"

// timedOut is the exit code for a wait that expired while the command ran on.
// Inherited from the bash implementation, where callers already branch on it.
const timedOut = 75

// muxTimeout bounds one call to the mux. The bash implementation piped `wezterm
// cli list` into `jq` with no timeout, so a mux that stopped answering hung the
// caller instead of failing it.
const muxTimeout = 5 * time.Second

// The mux calls and the two waits, as variables so a test can drive them without
// a terminal and without paying the real intervals. Production never reassigns
// them.
var (
	muxOutput = muxOutputCmd
	muxRun    = muxRunCmd

	// pollInterval is how often a wait re-reads the exit-code file.
	pollInterval = 2 * time.Second

	// settle is how long a completed run is given to drain through `tee` before
	// the tail is read. The exit code is written by a trap inside the pipeline, so
	// it can land before the last lines of output do. A fixed pause is the cost of
	// letting the body own the exit code, which is what makes an interrupted run
	// record one.
	settle = 250 * time.Millisecond
)

// Run executes one invocation and returns the process exit code.
func Run(args []string) int {
	opts, err := parse(args)
	if err != nil {
		return fail(err)
	}

	pane := os.Getenv("WEZTERM_PANE")
	if pane == "" {
		return fail(errors.New("not inside a WezTerm pane"))
	}

	dir, err := callerDir()
	if err != nil {
		return fail(err)
	}

	ws := newWorkspace(dir)
	if err := os.MkdirAll(ws.dir, 0o700); err != nil {
		return fail(err)
	}

	switch {
	case opts.status:
		return ws.reportStatus(pane)
	case opts.close:
		return ws.closePane(pane)
	case opts.release != "":
		return ws.release(opts.release)
	case opts.command == "":
		return fail(errors.New("no command"))
	}
	return ws.start(pane, dir, opts)
}

func fail(err error) int {
	fmt.Fprintf(os.Stderr, "worker: %v\n", err)
	return 2
}

// workspace is one keyed state directory and the paths inside it.
type workspace struct {
	root string // the workspace directory the key was derived from
	dir  string // the keyed state directory
}

func newWorkspace(dir string) *workspace {
	root := repo.Workspace(dir)
	return &workspace{root: root, dir: repo.WorkerDir(root)}
}

func (w *workspace) paneFile() string    { return filepath.Join(w.dir, "worker-pane") }
func (w *workspace) muxFile() string     { return filepath.Join(w.dir, "worker-mux") }
func (w *workspace) runningFile() string { return filepath.Join(w.dir, "worker-running") }
func (w *workspace) counterFile() string { return filepath.Join(w.dir, "worker-runs") }

func (w *workspace) logFile(name string) string  { return filepath.Join(w.dir, name+".log") }
func (w *workspace) rcFile(name string) string   { return filepath.Join(w.dir, name+".rc") }
func (w *workspace) bodyFile(name string) string { return filepath.Join(w.dir, name+".cmd") }

// pane returns the recorded worker pane id when it is usable.
//
// Three separate reasons make a record unusable, resolved here rather than at
// each call site. The recorded pane may be gone. It may be the caller's own pane,
// which would race the caller's shell for the same tty. And it may belong to an
// earlier mux generation: pane ids restart at 0 when the mux restarts, measured
// on 2026-08-11 against an isolated mux server, so a low recorded id passes a
// liveness check against an unrelated new pane. The workspace key is what makes
// that reachable, because recurring used to need two ids to repeat and now needs
// one.
func (w *workspace) pane(caller string) (string, error) {
	recorded, err := os.ReadFile(w.paneFile())
	if err != nil {
		return "", errors.New("none recorded")
	}
	id := strings.TrimSpace(string(recorded))
	if id == "" {
		return "", errors.New("none recorded")
	}
	if id == caller {
		return "", errors.New("the record names the calling pane")
	}
	if generation, err := os.ReadFile(w.muxFile()); err == nil {
		recordedMux := strings.TrimSpace(string(generation))
		if recordedMux != "" && recordedMux != currentMux() {
			return "", fmt.Errorf("pane %s belongs to mux %s, not %s", id, recordedMux, currentMux())
		}
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

// start sends one run to the worker pane, splitting one if there is none.
func (w *workspace) start(caller, dir string, opts options) int {
	name := opts.name
	if name == "" {
		name = w.nextRunName()
	}
	if err := validRunName(name); err != nil {
		return fail(err)
	}

	// A name whose previous run recorded no exit code is refused, not reused. The
	// bash implementation removed the stale exit-code file unconditionally, so two
	// panes sharing one workspace shared one log: the second truncates it and
	// removes the code, and the first pane's wait then returns the second pane's
	// status as its own.
	if w.inFlight(name) {
		return fail(fmt.Errorf(
			"a run named %s has recorded no exit code; wait for %s, or free the name with --release %s",
			name, w.rcFile(name), name))
	}

	target, err := w.pane(caller)
	if err != nil {
		id, splitErr := w.split(caller)
		if splitErr != nil {
			return fail(splitErr)
		}
		target = id
	}

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

	// Reported before any wait, so a caller that goes on to time out has already
	// been told the pane, the directory, and the log.
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

// writeBody generates the script the worker pane runs.
//
// The command goes into a file rather than into the keystrokes, so a quote, a
// newline, or a glob cannot change meaning in transit.
//
// Two things in here fix defects the bash version had. The exit code is written
// from a trap, so every way out of the run records one: zsh abandons the rest of
// a `;` list when an interrupt arrives, so the tail that recorded the code and
// removed the marker did not run, and the name stayed burned with no code on
// disk. And the `cd` is checked here as well as in the caller, because the two
// happen minutes apart: the caller checks before splitting, and this runs when
// the previous command finishes. A body with no check let a failed `cd` fall
// through and run the command in the pane's own directory under a plausible exit
// code.
func (w *workspace) writeBody(path, name, dir, command string) error {
	body := fmt.Sprintf(`#!/usr/bin/env zsh
# Record an exit code however this run ends, including on a signal.
finish() {
  local code=$?
  print -r -- $code > %[1]s.new && mv %[1]s.new %[1]s
  rm -f %[2]s
}
trap finish EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

print -r -- %[3]s > %[2]s
dir=%[4]s
cd -- $dir || { print -u2 -r -- "worker: $dir is gone"; exit 2; }
%[5]s
`,
		shellQuote(w.rcFile(name)),
		shellQuote(w.runningFile()),
		shellQuote(name),
		shellQuote(dir),
		command,
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

// split creates the worker pane below the caller and returns focus to the
// caller, so a build does not pull the owner out of the conversation.
func (w *workspace) split(caller string) (string, error) {
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
	if err := os.WriteFile(w.paneFile(), []byte(id+"\n"), 0o600); err != nil {
		return "", err
	}
	// Recorded beside the id, so a later invocation can tell this pane from a
	// same-numbered pane in a later mux generation.
	if err := os.WriteFile(w.muxFile(), []byte(currentMux()+"\n"), 0o600); err != nil {
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

// nextRunName allocates run1, run2, and so on within the workspace.
func (w *workspace) nextRunName() string {
	n := 0
	if body, err := os.ReadFile(w.counterFile()); err == nil {
		n, _ = strconv.Atoi(strings.TrimSpace(string(body)))
	}
	n++
	os.WriteFile(w.counterFile(), []byte(strconv.Itoa(n)+"\n"), 0o600)
	return "run" + strconv.Itoa(n)
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
// other run's log, and the case that burns a name is a live pane, which is
// exactly when a record is not removable.
func (w *workspace) release(name string) int {
	if err := validRunName(name); err != nil {
		return fail(err)
	}
	if _, err := os.Stat(w.logFile(name)); err != nil {
		fmt.Printf("no run named %s in %s\n", name, w.root)
		return 0
	}
	if w.runningRun() == name {
		return fail(fmt.Errorf("%s is running now; releasing it would orphan its output", name))
	}
	for _, path := range []string{w.logFile(name), w.rcFile(name), w.bodyFile(name)} {
		os.Remove(path)
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
	if err != nil {
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
	if err != nil {
		fmt.Printf("no worker for %s (%v)\n", w.root, err)
		return 0
	}
	muxRun([]string{"cli", "kill-pane", "--pane-id", target}, "")
	os.Remove(w.paneFile())
	os.Remove(w.muxFile())
	os.Remove(w.runningFile())
	fmt.Printf("closed pane %s for %s\n", target, w.root)
	return 0
}

// waitForExit blocks until the run records an exit code, and returns it. A wait
// of 0 seconds never expires.
func (w *workspace) waitForExit(name string, seconds, tail int) int {
	rc, ok := w.pollExit(name, seconds)
	if !ok {
		fmt.Fprintf(os.Stderr, "worker: still running after %ds; poll %s\n", seconds, w.rcFile(name))
		return timedOut
	}
	time.Sleep(settle)
	fmt.Printf("── %s tail (exit %d)\n", name, rc)
	w.printTail(name, tail)
	return rc
}

// pollExit re-reads the exit-code file until it holds a number. It measures the
// wait against a deadline rather than counting polls, so the interval can be
// changed without silently rounding the timeout to zero.
func (w *workspace) pollExit(name string, seconds int) (int, bool) {
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

// paneAlive reports whether the mux still has a pane with this id.
func paneAlive(id string) (bool, error) {
	out, err := muxOutput([]string{"cli", "list", "--format", "json"})
	if err != nil {
		return false, fmt.Errorf("the mux did not answer: %w", err)
	}
	var panes []struct {
		PaneID int `json:"pane_id"`
	}
	if err := json.Unmarshal([]byte(out), &panes); err != nil {
		return false, fmt.Errorf("could not read the pane list: %w", err)
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

type options struct {
	name    string
	command string
	tail    int
	wait    *int
	status  bool
	close   bool
	release string
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
		case "--status":
			opts.status = true
		case "--close":
			opts.close = true
		case "-w", "-t", "-n", "--release":
			if i+1 >= len(args) {
				return opts, fmt.Errorf("%s needs a value", arg)
			}
			i++
			value := args[i]
			switch arg {
			case "-n":
				opts.name = value
			case "--release":
				opts.release = value
			case "-t", "-w":
				n, err := nonNegative(arg, value)
				if err != nil {
					return opts, err
				}
				if arg == "-t" {
					opts.tail = n
				} else {
					opts.wait = &n
				}
			}
		default:
			if strings.HasPrefix(arg, "-") && arg != "-" {
				return opts, fmt.Errorf("unknown flag %s", arg)
			}
			if opts.command != "" {
				return opts, fmt.Errorf("the command is already %q, got a second one %q", opts.command, arg)
			}
			opts.command = arg
		}
	}
	return opts, nil
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
