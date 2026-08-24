// reel shows an agent run as a folding trace tree, live, from the OTLP JSON
// the local collector writes. It attaches to a session that is already running,
// the way you would attach to a log.
//
// A machine whose harness cannot reach the local collector points reel at a
// provider instead, with REEL_PROVIDER or --provider. See internal/source for
// what a provider has to print.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/attach"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/source"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/ui"
)

func main() {
	file := flag.String("file", "", "OTLP JSON file to read (default: the collector's)")
	pinned := flag.String("session", "", "attach to this session, by id or prefix")
	list := flag.Bool("list", false, "list the sessions and exit")
	once := flag.Bool("once", false, "print the tree once and exit")
	asked := flag.String("provider", "", "read spans from this provider instead of the file (default: $"+source.Env+")")
	back := flag.Duration("since", 2*time.Hour, "with a provider, how far back the first read reaches")
	every := flag.Duration("poll", 15*time.Second, "with a provider, how often to re-read")
	lag := flag.Duration("lag", 90*time.Second, "with a provider, how much every poll overlaps the last")
	all := flag.Bool("all", false, "show every run on this machine, not only this directory's")
	flag.Parse()

	// reel opens on the work in front of the reader. Inside an agent session
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
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		os.Exit(1)
	}
	if provider != nil {
		provider.Session = which
		if *list || *once {
			os.Exit(reportProvider(*provider, *back, which, scope, *list))
		}
		os.Exit(watchProvider(*provider, which, scope, *every, *back, *lag))
	}

	path := *file
	if path == "" {
		path = paths.OtelTelemetry()
	}

	if *list || *once {
		os.Exit(report(path, which, scope, *list))
	}
	os.Exit(watch(path, which, scope))
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

func report(path, which string, scope []string, listing bool) int {
	batch, err := otlp.ReadAll(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	return show(batch, path, which, scope, listing)
}

func reportProvider(p source.Provider, back time.Duration, which string, scope []string, listing bool) int {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	batch, err := p.Fetch(ctx, back)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	return show(batch, p.Name, which, scope, listing)
}

// show is the non-interactive half of both sources, so a provider prints the
// same list and the same tree the file does.
func show(batch otlp.Batch, from, which string, scope []string, listing bool) int {
	store := session.NewStore()
	store.Scope(scope)
	store.Add(batch.Spans)
	store.AddRecords(batch.Records)

	if listing {
		fmt.Fprintf(os.Stderr, "reel: %d spans and %d records from %s\n", len(batch.Spans), len(batch.Records), from)
		for _, one := range store.Sessions() {
			fmt.Printf("%-12s %-40s %5d spans  %s\n",
				one.Service, one.Title(), one.Count, one.Last.Format("15:04:05"))
		}
		return 0
	}

	found := pick(store, which)
	if found == nil {
		fmt.Fprintln(os.Stderr, "reel: no session in "+from)
		return 1
	}
	ui.Print(os.Stdout, found)
	return 0
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

func watch(path, which string, scope []string) int {
	stop := make(chan struct{})
	batches := make(chan otlp.Batch, 32)
	go otlp.Follow(path, 400*time.Millisecond, batches, stop)
	return run(batches, stop, which, scope, path)
}

func watchProvider(p source.Provider, which string, scope []string, every, back, lag time.Duration) int {
	stop := make(chan struct{})
	batches := make(chan otlp.Batch, 32)
	go source.Follow(p, every, back, lag, batches, stop)
	return run(batches, stop, which, scope, p.Name)
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
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	return 0
}
