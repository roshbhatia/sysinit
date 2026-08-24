// traces shows an agent run as a folding trace tree, live, from the OTLP JSON
// the local collector writes. It attaches to a session that is already running,
// the way you would attach to a log.
//
// A harness that cannot reach the local collector gets a provider, named by
// TRACES_PROVIDER or --provider. A provider is read as well as the file, not
// instead of it: on this machine one harness is redirected and four reach the
// collector directly. See internal/source for what a provider has to print.
package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/attach"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/session"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/source"
	"github.com/roshbhatia/sysinit/pkgs/traces/internal/ui"
)

func main() {
	file := flag.String("file", "", "OTLP JSON file to read (default: the collector's)")
	pinned := flag.String("session", "", "attach to this session, by id or prefix")
	list := flag.Bool("list", false, "list the sessions and exit")
	once := flag.Bool("once", false, "print the tree once and exit; status 2 when a span failed")
	asked := flag.String("provider", "", "read this provider as well as the collector file (default: $"+source.Env+")")
	back := flag.Duration("since", 2*time.Hour, "with a provider, how far back the first read reaches")
	every := flag.Duration("poll", 15*time.Second, "with a provider, how often to re-read")
	lag := flag.Duration("lag", 90*time.Second, "with a provider, how much every poll overlaps the last")
	all := flag.Bool("all", false, "show every run on this machine, not only this directory's")
	asJSON := flag.Bool("json", false, "print the spans as newline delimited JSON and exit")
	service := flag.String("service", "", "keep only this service, by name or prefix")
	flag.Parse()

	// traces opens on the work in front of the reader. Inside an agent session
	// that is the session itself, and outside one it is whatever ran in this
	// directory, which Claude Code already records per directory.
	which := attached(*pinned, *all)
	scope := []string{}
	if !*all && *pinned == "" {
		if here, err := os.Getwd(); err == nil {
			scope = attach.Scope(here)
		}
	}

	provider, err := source.Resolve(*asked)
	if err != nil {
		fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		os.Exit(1)
	}
	if provider != nil {
		provider.Session = which
	}

	path := *file
	if path == "" {
		path = paths.OtelTelemetry()
	}
	// A dash is the shell's own name for standard input, so a provider or a
	// saved capture pipes straight in: `traces-observe --since 1h | traces --once`.
	if path == "-" {
		path = ""
	}

	// A provider adds to the collector's file rather than replacing it. Only
	// one harness on this machine needs a provider, and goose, codex, opencode
	// and copilot all reach the collector directly: reading one source meant
	// `traces` showed the redirected harness and none of the others, and every
	// look at the rest needed the variable unset by hand.
	src := sources{path: path, provider: provider, back: *back, every: *every, lag: *lag, service: *service}

	if *asJSON || *list || *once {
		os.Exit(src.report(which, scope, *list, *asJSON))
	}
	os.Exit(src.watch(which, scope))
}

// attached names the run to open. A flag wins, then the session this process
// was started inside.
func attached(pinned string, all bool) string {
	if pinned != "" {
		return pinned
	}
	if all {
		return ""
	}
	return attach.Current()
}

// sources is every place this machine keeps spans.
type sources struct {
	path     string
	provider *source.Provider
	back     time.Duration
	every    time.Duration
	lag      time.Duration
	service  string
}

// name says what the frame is reading, so an empty view names the source that
// was empty rather than leaving the reader to guess which one.
func (s sources) name() string {
	where := s.path
	if where == "" {
		where = "standard input"
	}
	if s.provider == nil {
		return where
	}
	return where + " and " + s.provider.Name
}

// read pulls every source into one batch. An empty path means standard input.
func (s sources) read() (otlp.Batch, error) {
	if s.path == "" {
		blob, err := io.ReadAll(os.Stdin)
		if err != nil {
			return otlp.Batch{}, err
		}
		return source.DecodeAny(blob), nil
	}
	return otlp.ReadAll(s.path)
}

// keep drops the services the reader did not ask for. A prefix matches, because
// `codex` is what a reader types for `codex_exec`.
func (s sources) keep(in otlp.Batch) otlp.Batch {
	if s.service == "" {
		return in
	}
	out := otlp.Batch{}
	for _, one := range in.Spans {
		if strings.HasPrefix(one.Service, s.service) {
			out.Spans = append(out.Spans, one)
		}
	}
	for _, one := range in.Records {
		if strings.HasPrefix(one.Service, s.service) {
			out.Records = append(out.Records, one)
		}
	}
	return out
}

func (s sources) report(which string, scope []string, listing, asJSON bool) int {
	batch, err := s.read()
	if err != nil {
		fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		return 1
	}
	if s.provider != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
		read, err := s.provider.Fetch(ctx, s.back)
		cancel()
		if err != nil {
			// The file already answered, so a provider that cannot run costs
			// its own harness and not the whole view.
			fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		} else {
			batch.Spans = append(batch.Spans, read.Spans...)
			batch.Records = append(batch.Records, read.Records...)
		}
	}
	batch = s.keep(batch)
	if asJSON {
		if err := source.Encode(os.Stdout, batch); err != nil {
			fmt.Fprintf(os.Stderr, "traces: %v\n", err)
			return 1
		}
		return 0
	}
	return show(batch, s.name(), which, scope, listing)
}

// show is the non-interactive half of both sources, so a provider prints the
// same list and the same tree the file does.
func show(batch otlp.Batch, from, which string, scope []string, listing bool) int {
	store := session.NewStore()
	store.Scope(scope)
	store.Add(batch.Spans)
	store.AddRecords(batch.Records)

	if listing {
		fmt.Fprintf(os.Stderr, "traces: %d spans and %d records from %s\n", len(batch.Spans), len(batch.Records), from)
		for _, one := range store.Sessions() {
			fmt.Printf("%-12s %-40s %5d spans  %s\n",
				one.Service, one.Title(), one.Count, one.Last.Format("15:04:05"))
		}
		return 0
	}

	found := pick(store, which)
	if found == nil {
		fmt.Fprintln(os.Stderr, "traces: no session in "+from)
		return 1
	}
	ui.Print(os.Stdout, found)
	// 2 for a run that holds a failed span, so a script can gate on it without
	// reading the tree. 1 stays "traces could not answer", which is the ordinary
	// meaning of 1 and the one a caller already handles.
	if failed(found) {
		return 2
	}
	return 0
}

func failed(one *session.Session) bool {
	var walk func(*session.Node) bool
	walk = func(n *session.Node) bool {
		if n.Span.Failed {
			return true
		}
		for _, kid := range n.Children {
			if walk(kid) {
				return true
			}
		}
		return false
	}
	for _, root := range one.Roots {
		if walk(root) {
			return true
		}
	}
	return false
}

func pick(store *session.Store, which string) *session.Session {
	if which != "" {
		return store.Session(which)
	}
	all := store.Sessions()
	if len(all) == 0 {
		return nil
	}
	return all[0]
}

// watch follows every source at once. Each writes into the same channel, and
// the file's own closer is the one that ends it: a provider poll is slow and
// the file is the source that is always present.
func (s sources) watch(which string, scope []string) int {
	stop := make(chan struct{})
	batches := make(chan otlp.Batch, 32)

	fromFile := make(chan otlp.Batch, 32)
	if s.path != "" {
		go otlp.Follow(s.path, 400*time.Millisecond, fromFile, stop)
	} else {
		// Standard input is read once and ends. Following it would block the
		// view on a pipe that is already closed.
		go func() {
			defer close(fromFile)
			if batch, err := s.read(); err == nil && !batch.Empty() {
				fromFile <- batch
			}
		}()
	}

	var fromProvider chan otlp.Batch
	if s.provider != nil {
		fromProvider = make(chan otlp.Batch, 32)
		go source.Follow(*s.provider, s.every, s.back, s.lag, fromProvider, stop)
	}

	go func() {
		defer close(batches)
		for fromFile != nil || fromProvider != nil {
			select {
			case one, ok := <-fromFile:
				if !ok {
					fromFile = nil
					continue
				}
				batches <- s.keep(one)
			case one, ok := <-fromProvider:
				if !ok {
					fromProvider = nil
					continue
				}
				batches <- s.keep(one)
			}
		}
	}()

	return run(batches, stop, which, scope, s.name())
}

// run owns the program either way. Follow owns its own goroutine, so the spans
// arrive as messages rather than as a blocking read inside Update.
func run(batches chan otlp.Batch, stop chan struct{}, which string, scope []string, from string) int {
	store := session.NewStore()
	store.Scope(scope)
	program := tea.NewProgram(
		ui.New(store, which, from),
		tea.WithAltScreen(),
	)
	go func() {
		for batch := range batches {
			program.Send(ui.BatchMsg(batch))
		}
	}()

	_, err := program.Run()
	close(stop)
	if err != nil {
		fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		return 1
	}
	return 0
}
