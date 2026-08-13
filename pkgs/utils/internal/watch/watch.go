// Package watch implements the `watch` command: one viewer for the three
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

	"github.com/roshbhatia/sysinit/pkgs/utils/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/transcript"
	"github.com/roshbhatia/sysinit/pkgs/utils/internal/worker"
)

const Summary = "render and tail a worker log, the agent-state bus, or a transcript"

const usageText = `One viewer for the three things an agent leaves behind.

Usage:
  watch worker [<directory>] [--log <name>]
  watch bus [<directory>]
  watch transcript <harness>            resolve by directory
  watch transcript <harness>/<session>
  watch transcript <harness> <session>

Each source is named by what identifies it, and they differ:
  worker      by directory, the same key the worker itself uses. Defaults to
              the working directory, and honours $SYSINIT_WORKER_SESSION.
  bus         by directory. Defaults to the working directory.
  transcript  by harness session id, or by directory through the sidecar
              published next to it.

Flags:
  --log <name>   which worker log, default "last"
  -n <count>     lines of history to show first, default 40
  --no-follow    render once and exit
  --interval <d> poll interval while following, default 500ms

This command reads. It never opens an editor, never spawns a pane, and never
signals a producer.
`

// pollDefault is how often a followed source is re-read.
const pollDefault = 500 * time.Millisecond

func Run(args []string) int {
	fs := flag.NewFlagSet("watch", flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	logName := fs.String("log", "last", "which worker log")
	history := fs.Int("n", 40, "lines of history")
	noFollow := fs.Bool("no-follow", false, "render once and exit")
	interval := fs.Duration("interval", pollDefault, "poll interval")

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
	case "worker":
		source, err = newWorker(rest[1:], *logName)
	case "bus":
		source, err = newBus(rest[1:])
	case "transcript":
		source, err = newTranscript(rest[1:])
	case "help", "-h", "--help":
		fmt.Fprint(os.Stdout, usageText)
		return 0
	default:
		err = fmt.Errorf("unknown source %q, want worker, bus, or transcript", rest[0])
	}
	if err != nil {
		fmt.Fprintf(os.Stderr, "watch: %v\n", err)
		return 2
	}

	return follow(source, *history, !*noFollow, *interval)
}

// renderer is one source.
type renderer interface {
	Title() string
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

// fileTail is the shared body of the two line-oriented sources.
type fileTail struct {
	path    string
	title   string
	offset  int64
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
func lastLines(body string, n int) string {
	if body == "" || n <= 0 {
		return ""
	}
	lines := strings.SplitAfter(body, "\n")
	if lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}
	if len(lines) > n {
		lines = lines[len(lines)-n:]
	}
	return strings.Join(lines, "")
}

// newWorker resolves one run's log inside the worker record for a DIRECTORY.
func newWorker(args []string, logName string) (renderer, error) {
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
		return nil, fmt.Errorf("worker takes at most one directory, got %d", len(args))
	}

	if logName == "" {
		logName = "last"
	}
	logName = strings.TrimSuffix(logName, ".log")
	if strings.Contains(logName, "/") {
		return nil, fmt.Errorf("log name %q contains a path separator", logName)
	}

	record, root, err := worker.RecordDir(dir)
	if err != nil {
		return nil, err
	}
	if strings.Contains(filepath.Base(record), "/") {
		return nil, fmt.Errorf("derived worker key %q contains a path separator", filepath.Base(record))
	}

	path := filepath.Join(record, logName+".log")
	return &fileTail{path: path, title: fmt.Sprintf("worker %s/%s", filepath.Base(root), logName)}, nil
}

// newTranscript resolves a mirrored harness transcript.
func newTranscript(args []string) (renderer, error) {
	var harness, session string
	switch len(args) {
	case 1:
		harness, session, _ = strings.Cut(args[0], "/")
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

// busRecord is the subset of the pane record this viewer shows.
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
	dir  string
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
	return fmt.Sprintf("pane %-6s %-10s %-8s %-12s %-11s %s",
		pane, record.Agent, record.Status, age, liveness(record), record.Reason)
}

// liveness is deliberately weak, and says so in its output.
func liveness(record busRecord) string {
	if record.Mux <= 0 {
		return "unverified"
	}
	if syscall.Kill(record.Mux, 0) != nil {
		return "stale"
	}
	return "unverified"
}
