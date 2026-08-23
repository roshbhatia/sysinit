// reel shows an agent run as a folding trace tree, live, from the OTLP JSON
// the local collector writes. It attaches to a session that is already running,
// the way you would attach to a log.
package main

import (
	"flag"
	"fmt"
	"os"
	"time"

	tea "github.com/charmbracelet/bubbletea"

	"github.com/roshbhatia/sysinit/pkgs/internal/paths"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/otlp"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/session"
	"github.com/roshbhatia/sysinit/pkgs/reel/internal/ui"
)

func main() {
	file := flag.String("file", "", "OTLP JSON file to read (default: the collector's)")
	which := flag.String("session", "", "attach to this session, by id or prefix")
	list := flag.Bool("list", false, "list the sessions and exit")
	once := flag.Bool("once", false, "print the tree once and exit")
	flag.Parse()

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
	store := session.NewStore()
	store.Add(spans)

	if listing {
		for _, one := range store.Sessions() {
			fmt.Printf("%-12s %-40s %5d spans  %s\n",
				one.Service, one.Title(), one.Count, one.Last.Format("15:04:05"))
		}
		return 0
	}

	found := pick(store, which)
	if found == nil {
		fmt.Fprintln(os.Stderr, "reel: no session in "+path)
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

	program := tea.NewProgram(
		ui.New(session.NewStore(), which, path),
		tea.WithAltScreen(),
	)
	// Follow owns its own goroutine, so the spans arrive as messages rather
	// than as a blocking read inside Update.
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
