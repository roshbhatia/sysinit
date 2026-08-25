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
	"strconv"
	"strings"
	"sync"
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
	asked := flag.String("provider", "", "read exactly these sources, comma separated, instead of the ones declared per harness in "+source.ConfigFile())
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
	directory := ""
	if !*all && *pinned == "" {
		if here, err := os.Getwd(); err == nil {
			scope = attach.Scope(here)
			directory = here
		}
	}

	providers, err := source.Resolve(*asked, *service)
	if err != nil {
		fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		os.Exit(1)
	}
	for _, one := range providers {
		one.Session = which
		one.Directory = directory
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
	src := sources{path: path, providers: providers, back: *back, every: *every, lag: *lag, service: *service}

	if *asJSON || *list || *once {
		os.Exit(src.report(which, scope, directory, *list, *asJSON))
	}
	os.Exit(src.watch(which, scope, directory))
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
	path      string
	providers []*source.Provider
	back      time.Duration
	every     time.Duration
	lag       time.Duration
	service   string
}

// name says what the frame is reading, so an empty view names the source that
// was empty rather than leaving the reader to guess which one.
func (s sources) name() string {
	where := s.path
	if where == "" {
		where = "standard input"
	}
	for _, one := range s.providers {
		where += " and " + one.Name
		// A source declared for one harness is read for that harness only, and
		// a header saying only "and observe" hides which run it answered for.
		if who := one.For(); who != "" {
			where += "(" + who + ")"
		}
	}
	return where
}

// fetch runs every provider over the same window and folds the answers into one
// batch. A provider that fails is named and skipped: the others already
// answered, and one unreachable source should not empty the view.
func (s sources) fetch(ctx context.Context) otlp.Batch {
	type answer struct {
		batch otlp.Batch
		err   error
	}
	answers := make(chan answer, len(s.providers))
	for _, one := range s.providers {
		go func() {
			read, err := one.Fetch(ctx, s.back)
			answers <- answer{batch: read, err: err}
		}()
	}

	out := otlp.Batch{}
	for range s.providers {
		one := <-answers
		if one.err != nil {
			fmt.Fprintf(os.Stderr, "traces: %v\n", one.err)
			continue
		}
		out.Spans = append(out.Spans, one.batch.Spans...)
		out.Records = append(out.Records, one.batch.Records...)
	}
	return out
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

func (s sources) report(which string, scope []string, directory string, listing, asJSON bool) int {
	batch, err := s.read()
	if err != nil {
		fmt.Fprintf(os.Stderr, "traces: %v\n", err)
		return 1
	}
	if len(s.providers) > 0 {
		// The file already answered, so a provider that cannot run costs its
		// own harness and not the whole view.
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
		read := s.fetch(ctx)
		cancel()
		batch.Spans = append(batch.Spans, read.Spans...)
		batch.Records = append(batch.Records, read.Records...)
	}
	batch = s.keep(batch)
	if asJSON {
		// --json ignored --session, so `traces --session X --json` printed every
		// span on the machine: 17447 codex runtime spans over a Claude run of
		// 350. A filter the reader gave has to reach every output.
		if err := source.Encode(os.Stdout, only(batch, which, scope, directory)); err != nil {
			fmt.Fprintf(os.Stderr, "traces: %v\n", err)
			return 1
		}
		return 0
	}
	return show(batch, s.name(), which, scope, directory, listing)
}

// show is the non-interactive half of both sources, so a provider prints the
// same list and the same tree the file does.
func show(batch otlp.Batch, from, which string, scope []string, directory string, listing bool) int {
	store := session.NewStore()
	store.Scope(scope, directory)
	store.AddBatch(batch)

	if listing {
		fmt.Fprintf(os.Stderr, "traces: %d spans and %d records from %s\n", len(batch.Spans), len(batch.Records), from)
		list(os.Stdout, store.Sessions())
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

// list sizes every column to the rows it holds. The widths were fixed at 12 and
// 40 before this, and `github-copilot` and a 47 character trace key both
// overran theirs, so each long row shifted the two columns after it.
//
// The id column prints the short id, because that is what --session takes, and
// the name beside it is what the harness itself called the run. A list of six
// sessions used to read as six hex strings.
func list(w io.Writer, all []*session.Session) {
	service, id, count := 0, 0, 0
	for _, one := range all {
		service = max(service, len(one.Service))
		id = max(id, len(one.Short()))
		count = max(count, len(strconv.Itoa(one.ViewCount())))
	}
	for _, one := range all {
		shown := one.ViewCount()
		fmt.Fprintf(w, "%-*s  %-*s  %*d %-5s  %s  %s\n",
			service, one.Service,
			id, one.Short(),
			count, shown, plural(shown, "item"),
			one.Last.Format("15:04:05"),
			clip(one.Name(), 56))
	}
}

// A title runs as long as the harness wants, and a wrapped listing row loses
// the column alignment that makes the listing readable at all.
func clip(s string, width int) string {
	if len(s) <= width {
		return s
	}
	return s[:width-1] + "\u2026"
}

func plural(n int, word string) string {
	if n == 1 {
		return word
	}
	return word + "s"
}

// only narrows a batch to the run the reader named, by building the same store
// the tree is drawn from and reading back the spans that survived. Filtering the
// spans directly would need session grouping in two places, and the two would
// disagree the first time either changed.
func only(batch otlp.Batch, which string, scope []string, directory string) otlp.Batch {
	if which == "" && len(scope) == 0 {
		return batch
	}
	store := session.NewStore()
	store.Scope(scope, directory)
	store.Add(batch.Spans)
	store.AddRecords(batch.Records)
	found := pick(store, which)
	if found == nil {
		return otlp.Batch{}
	}
	keep := map[string]bool{}
	var walk func(*session.Node)
	walk = func(node *session.Node) {
		keep[node.Span.SpanID] = true
		for _, facet := range node.Facets {
			keep[facet.SpanID] = true
		}
		for _, kid := range node.Children {
			walk(kid)
		}
	}
	for _, root := range found.Roots {
		walk(root)
	}
	out := otlp.Batch{}
	for _, span := range batch.Spans {
		if keep[span.SpanID] {
			out.Spans = append(out.Spans, span)
		}
	}
	for _, one := range batch.Records {
		// A record with no session of its own belongs to this run only when its
		// service does. Keeping every session-less record let 149 opencode and
		// codex records into a Claude run's own output.
		if one.Session == found.ID || (one.Session == "" && one.Service == found.Service) {
			out.Records = append(out.Records, one)
		}
	}
	return out
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
func (s sources) watch(which string, scope []string, directory string) int {
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

	// One channel per provider would need one select arm per provider, so each
	// follower writes into a shared channel and a counter closes it once.
	var fromProvider chan otlp.Batch
	if len(s.providers) > 0 {
		fromProvider = make(chan otlp.Batch, 32)
		each := make([]chan otlp.Batch, len(s.providers))
		for i, one := range s.providers {
			each[i] = make(chan otlp.Batch, 32)
			go source.Follow(*one, s.every, s.back, s.lag, each[i], stop)
		}
		var wg sync.WaitGroup
		for _, in := range each {
			wg.Add(1)
			go func() {
				defer wg.Done()
				for batch := range in {
					fromProvider <- batch
				}
			}()
		}
		go func() {
			wg.Wait()
			close(fromProvider)
		}()
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

	return run(batches, stop, which, scope, directory, s.name())
}

// run owns the program either way. Follow owns its own goroutine, so the spans
// arrive as messages rather than as a blocking read inside Update.
func run(batches chan otlp.Batch, stop chan struct{}, which string, scope []string, directory, from string) int {
	store := session.NewStore()
	store.Scope(scope, directory)
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
