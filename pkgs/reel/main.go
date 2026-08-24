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
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/source"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/ui"
)

func main() {
	file := flag.String("file", "", "OTLP JSON file to read (default: the collector's)")
	which := flag.String("session", "", "attach to this session, by id or prefix")
	list := flag.Bool("list", false, "list the sessions and exit")
	once := flag.Bool("once", false, "print the tree once and exit")
	asked := flag.String("provider", "", "read spans from this provider instead of the file (default: $"+source.Env+")")
	back := flag.Duration("since", 2*time.Hour, "with a provider, how far back the first read reaches")
	every := flag.Duration("poll", 15*time.Second, "with a provider, how often to re-read")
	lag := flag.Duration("lag", 90*time.Second, "with a provider, how much every poll overlaps the last")
	flag.Parse()

	provider, err := source.Resolve(*asked)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		os.Exit(1)
	}
	if provider != nil {
		provider.Session = *which
		if *list || *once {
			os.Exit(reportProvider(*provider, *back, *which, *list))
		}
		os.Exit(watchProvider(*provider, *which, *every, *back, *lag))
	}

	path := *file
	if path == "" {
		path = paths.OtelTelemetry()
	}

	if *list || *once {
		os.Exit(report(path, *which, *list))
	}
	os.Exit(watch(path, *which))
}

func report(path, which string, listing bool) int {
	spans, err := otlp.ReadAll(path)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	return show(spans, path, which, listing)
}

func reportProvider(p source.Provider, back time.Duration, which string, listing bool) int {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	spans, err := p.Fetch(ctx, back)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	return show(spans, p.Name, which, listing)
}

// show is the non-interactive half of both sources, so a provider prints the
// same list and the same tree the file does.
func show(spans []otlp.Span, from, which string, listing bool) int {
	store := session.NewStore()
	store.Add(spans)

	if listing {
		fmt.Fprintf(os.Stderr, "reel: %d spans from %s\n", len(spans), from)
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

func watch(path, which string) int {
	stop := make(chan struct{})
	batches := make(chan []otlp.Span, 32)
	go otlp.Follow(path, 400*time.Millisecond, batches, stop)
	return run(batches, stop, which, path)
}

func watchProvider(p source.Provider, which string, every, back, lag time.Duration) int {
	stop := make(chan struct{})
	batches := make(chan []otlp.Span, 32)
	go source.Follow(p, every, back, lag, batches, stop)
	return run(batches, stop, which, p.Name)
}

// run owns the program either way. Follow owns its own goroutine, so the spans
// arrive as messages rather than as a blocking read inside Update.
func run(batches chan []otlp.Span, stop chan struct{}, which, from string) int {
	program := tea.NewProgram(
		ui.New(session.NewStore(), which, from),
		tea.WithAltScreen(),
	)
	go func() {
		for batch := range batches {
			program.Send(ui.SpansMsg(batch))
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
