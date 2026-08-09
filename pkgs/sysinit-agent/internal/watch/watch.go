// Package watch implements the `watch` command: one viewer for the three
// things an agent leaves behind.
//
// One viewer rather than three, because the alternative is what this replaces:
// a chord per source, each opening a different program, each knowing where its
// source lives. Here the paths come from the manifest and the rendering is the
// same loop.
//
// The viewer only reads. It never nudges a producer, never opens an editor, and
// never sends a key to a pane. A source that stops being written just stops
// changing on screen.
//
// # Resolution
//
// The three sources do NOT share a key, and pretending they do is the mistake
// this contract exists to prevent. Each is named by what actually identifies
// it:
//
//	wtrun       by pane. wtrun.sh writes under
//	            <agentWtrun>/${WTRUN_SESSION:-pane-$WEZTERM_PANE}/, and nothing
//	            below that records a repository. A viewer spawned into a NEW
//	            pane would resolve its own empty directory, so the name comes
//	            from WTRUN_SESSION or an explicit argument, never from the
//	            viewer's own pane.
//	bus         by directory. The pane record carries `repo` and `worktree`, so
//	            the working directory is a real key here.
//	transcript  by harness session id, <agentTranscripts>/<harness>/<session>.jsonl.
//	            Resolving one by directory needs the repository recorded next to
//	            the session, which is task 5.3's job, not this file's.
package watch

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/signal"
	"path/filepath"
	"sort"
	"strings"
	"syscall"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/sysinit-agent/internal/transcript"
)

const Summary = "render and tail a wtrun log, the agent-state bus, or a transcript"

const usageText = `One viewer for the three things an agent leaves behind.

Usage:
  watch wtrun [<session>] [--log <name>]
  watch bus [<directory>]
  watch transcript <harness>            resolve by directory
  watch transcript <harness>/<session>
  watch transcript <harness> <session>

Each source is named by what identifies it, and they differ:
  wtrun       by pane. Defaults to $WTRUN_SESSION, then pane-$WEZTERM_PANE.
              Never the viewer's own pane when a name is given.
  bus         by directory. Defaults to the working directory.
  transcript  by harness session id, or by directory through the sidecar
              published next to it.

Flags:
  --log <name>   which wtrun log, default "last"
  -n <count>     lines of history to show first, default 40
  --no-follow    render once and exit
  --interval <d> poll interval while following, default 500ms

This command reads. It never opens an editor, never spawns a pane, and never
signals a producer.
`

// pollDefault is how often a followed source is re-read.
//
// Polling rather than a filesystem watch, and the tradeoff is deliberate. A
// watch needs a dependency this module does not have and an open descriptor per
// source; polling a handful of files twice a second costs a stat each and
// cannot leak. It also degrades honestly over a filesystem where change
// notification does not work.
const pollDefault = 500 * time.Millisecond

func Run(args []string) int {
	fs := flag.NewFlagSet("watch", flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	logName := fs.String("log", "last", "which wtrun log")
	history := fs.Int("n", 40, "lines of history")
	noFollow := fs.Bool("no-follow", false, "render once and exit")
	interval := fs.Duration("interval", pollDefault, "poll interval")

	// Parse in passes, taking one positional each time. Go's flag package stops
	// at the first non-flag argument, so a single Parse would read `--no-follow`
	// in `watch bus --no-follow` as a directory name and then follow forever.
	var rest []string
	remaining := args
	for {
		if err := fs.Parse(remaining); err != nil {
			if err == flag.ErrHelp {
				fmt.Fprint(os.Stdout, usageText)
				return 0
			}
			fmt.Fprintf(os.Stderr, "watch: %v\n", err)
			fmt.Fprint(os.Stderr, usageText)
			return 2
		}
		if fs.NArg() == 0 {
			break
		}
		rest = append(rest, fs.Arg(0))
		remaining = fs.Args()[1:]
	}

	if len(rest) == 0 {
		fmt.Fprint(os.Stderr, usageText)
		return 2
	}

	var source renderer
	var err error
	switch rest[0] {
	case "wtrun":
		source, err = newWtrun(rest[1:], *logName)
	case "bus":
		source, err = newBus(rest[1:])
	case "transcript":
		source, err = newTranscript(rest[1:])
	case "help", "-h", "--help":
		fmt.Fprint(os.Stdout, usageText)
		return 0
	default:
		err = fmt.Errorf("unknown source %q, want wtrun, bus, or transcript", rest[0])
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "watch: %v\n", err)
		return 2
	}

	return follow(source, *history, !*noFollow, *interval)
}

// renderer is one source. Render writes everything worth showing right now;
// since is how much history to include, in whatever unit the source counts in.
//
// A source that cannot answer says so in its own output rather than returning
// an error, because a wtrun log that has not been created yet is the normal
// state of a run that is still starting.
type renderer interface {
	// Title is the one line naming what is being watched, so the owner can
	// tell at a glance that the resolution went where they meant.
	Title() string
	// Render writes the current view. history is the number of trailing lines
	// to include on the first call; later calls pass 0 for "only what is new".
	Render(w io.Writer, history int) error
}

// follow renders once, then re-renders on a tick until interrupted.
func follow(source renderer, history int, tail bool, interval time.Duration) int {
	fmt.Fprintf(os.Stdout, "%s\n", source.Title())

	if err := source.Render(os.Stdout, history); err != nil {
		fmt.Fprintf(os.Stderr, "watch: %v\n", err)
		return 1
	}
	if !tail {
		return 0
	}

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	for {
		select {
		case <-stop:
			return 0
		case <-ticker.C:
			if err := source.Render(os.Stdout, 0); err != nil {
				fmt.Fprintf(os.Stderr, "watch: %v\n", err)
				return 1
			}
		}
	}
}

// fileTail is the shared body of the two line-oriented sources. It remembers
// how far it has read, so a tick emits only what was appended.
type fileTail struct {
	path   string
	title  string
	offset int64
	// missing suppresses repeating the "not there yet" line every tick.
	missing bool
}

func (f *fileTail) Title() string { return f.title }

func (f *fileTail) Render(w io.Writer, history int) error {
	info, err := os.Stat(f.path)
	if err != nil {
		if !f.missing {
			fmt.Fprintf(w, "(nothing at %s yet)\n", f.path)
			f.missing = true
		}
		return nil
	}
	f.missing = false

	// A file that shrank was replaced, not appended to. wtrun rotates `last.log`
	// by symlink on every run, so this is the common case and not an oddity:
	// start over rather than reading from an offset that now means something
	// else.
	if info.Size() < f.offset {
		f.offset = 0
	}

	if f.offset == 0 && history > 0 {
		body, err := os.ReadFile(f.path)
		if err != nil {
			return err
		}
		fmt.Fprint(w, lastLines(string(body), history))
		f.offset = int64(len(body))
		return nil
	}

	if info.Size() == f.offset {
		return nil
	}

	handle, err := os.Open(f.path)
	if err != nil {
		return err
	}
	defer handle.Close()
	if _, err := handle.Seek(f.offset, io.SeekStart); err != nil {
		return err
	}
	written, err := io.Copy(w, handle)
	f.offset += written
	return err
}

// lastLines returns the trailing n lines of body, keeping the final newline
// state it found.
func lastLines(body string, n int) string {
	if body == "" || n <= 0 {
		return ""
	}
	lines := strings.SplitAfter(body, "\n")
	// SplitAfter leaves a trailing empty element when the body ends in a
	// newline. Dropping it stops that empty from consuming one of the n.
	if lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "")
}

// newWtrun resolves a wtrun log. The session name is an argument or an
// environment variable, never the viewer's own pane: 5.2 spawns this into a NEW
// pane, whose own id names a directory wtrun has never written to.
func newWtrun(args []string, logName string) (renderer, error) {
	session := ""
	switch len(args) {
	case 0:
	case 1:
		session = args[0]
	default:
		return nil, fmt.Errorf("wtrun takes at most one session name, got %d", len(args))
	}

	if session == "" {
		session = os.Getenv("WTRUN_SESSION")
	}
	if session == "" {
		if pane := os.Getenv("WEZTERM_PANE"); pane != "" {
			session = "pane-" + pane
		}
	}
	if session == "" {
		return nil, fmt.Errorf("no wtrun session: pass one, or set WTRUN_SESSION")
	}
	if strings.Contains(session, "/") {
		return nil, fmt.Errorf("wtrun session %q contains a path separator", session)
	}

	if logName == "" {
		logName = "last"
	}
	logName = strings.TrimSuffix(logName, ".log")
	if strings.Contains(logName, "/") {
		return nil, fmt.Errorf("log name %q contains a path separator", logName)
	}

	path := filepath.Join(paths.AgentWtrun(), session, logName+".log")
	return &fileTail{path: path, title: fmt.Sprintf("wtrun %s/%s", session, logName)}, nil
}

// newTranscript resolves a mirrored harness transcript. Both spellings are
// accepted because the id is written both ways in practice.
func newTranscript(args []string) (renderer, error) {
	var harness, session string
	switch len(args) {
	case 1:
		harness, session, _ = strings.Cut(args[0], "/")
		// A bare harness resolves by directory. Nobody knows a session id, so
		// requiring one would make this source reachable only from the sidecar
		// 5.3 writes, read by hand.
		if session == "" {
			here, err := os.Getwd()
			if err != nil {
				return nil, err
			}
			found, ok := transcript.FindByWorktree(harness, here)
			if !ok {
				return nil, fmt.Errorf("no %s transcript published for %s", harness, here)
			}
			session = found
		}
	case 2:
		harness, session = args[0], args[1]
	default:
		return nil, fmt.Errorf("transcript takes <harness>[/<session>] or <harness> <session>")
	}
	if harness == "" || session == "" {
		return nil, fmt.Errorf("transcript needs a harness, and a session id or a published one here")
	}
	if strings.Contains(harness, "/") || strings.Contains(session, "/") {
		return nil, fmt.Errorf("harness and session must not contain a path separator")
	}

	session = strings.TrimSuffix(session, ".jsonl")
	path := filepath.Join(paths.AgentTranscripts(), harness, session+".jsonl")
	return &fileTail{path: path, title: fmt.Sprintf("transcript %s/%s", harness, session)}, nil
}

// busRecord is the subset of the pane record this viewer shows. The schema is
// internal/agentstate/SCHEMA.md; every field here is read by name, so a field
// added there is invisible to this.
type busRecord struct {
	Mux      int             `json:"mux"`
	Pane     json.RawMessage `json:"pane"`
	Session  string          `json:"session"`
	Repo     string          `json:"repo"`
	Branch   string          `json:"branch"`
	Worktree string          `json:"worktree"`
	Agent    string          `json:"agent"`
	Status   string          `json:"status"`
	Reason   string          `json:"reason"`
	Since    int64           `json:"since"`
}

// bus renders the pane records whose worktree is the directory being watched.
type bus struct {
	dir string
	// last is the previous frame, so an unchanged bus prints nothing.
	last string
}

func newBus(args []string) (renderer, error) {
	dir := ""
	switch len(args) {
	case 0:
		here, err := os.Getwd()
		if err != nil {
			return nil, err
		}
		dir = here
	case 1:
		dir = args[0]
	default:
		return nil, fmt.Errorf("bus takes at most one directory, got %d", len(args))
	}

	resolved, err := filepath.Abs(dir)
	if err != nil {
		return nil, err
	}
	return &bus{dir: strings.TrimRight(resolved, "/")}, nil
}

func (b *bus) Title() string { return "agent-state bus for " + b.dir }

func (b *bus) Render(w io.Writer, _ int) error {
	entries, err := os.ReadDir(paths.AgentPanes())
	if err != nil {
		frame := "(no pane records)\n"
		return b.emit(w, frame)
	}

	var rows []string
	for _, entry := range entries {
		if !strings.HasSuffix(entry.Name(), ".json") {
			continue
		}
		body, err := os.ReadFile(filepath.Join(paths.AgentPanes(), entry.Name()))
		if err != nil {
			continue
		}
		var record busRecord
		if json.Unmarshal(body, &record) != nil {
			continue
		}
		if strings.TrimRight(record.Worktree, "/") != b.dir {
			continue
		}
		rows = append(rows, formatRow(strings.TrimSuffix(entry.Name(), ".json"), record))
	}

	frame := "(no agent in this worktree)\n"
	if len(rows) > 0 {
		sort.Strings(rows)
		frame = strings.Join(rows, "\n") + "\n"
	}
	return b.emit(w, frame)
}

// emit writes a frame only when it differs from the last one, so a followed bus
// that nothing is changing stays quiet.
func (b *bus) emit(w io.Writer, frame string) error {
	if frame == b.last {
		return nil
	}
	b.last = frame
	_, err := fmt.Fprint(w, frame)
	return err
}

func formatRow(pane string, record busRecord) string {
	age := ""
	if record.Since > 0 {
		age = time.Since(time.Unix(record.Since, 0)).Truncate(time.Second).String()
	}
	// Wide enough for a multi-day age. A record from a mux that has been gone
	// for a week is exactly the case worth seeing lined up, not the case worth
	// letting overflow the column.
	return fmt.Sprintf("pane %-6s %-10s %-8s %-12s %-11s %s",
		pane, record.Agent, record.Status, age, liveness(record), record.Reason)
}

// liveness is deliberately weak, and says so in its output.
//
// SCHEMA.md's rule is pane existence, and this command cannot answer it: doing
// so from Go means forking `wezterm cli list` on every frame, which is exactly
// the fork task 2.9 removed. So a row is `unverified` unless it can be RULED
// OUT: the record's `mux` field is the pid of the mux that wrote it, and a dead
// pid means the record is stale.
//
// The marker rejects and never confirms. A live mux says nothing about one pane
// inside it, so `unverified` is the honest answer for every record this cannot
// eliminate, and guessing `live` there would be worse than saying nothing.
func liveness(record busRecord) string {
	if record.Mux <= 0 {
		return "unverified"
	}
	if syscall.Kill(record.Mux, 0) != nil {
		return "stale"
	}
	return "unverified"
}
