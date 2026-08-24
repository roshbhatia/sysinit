// reel shows an agent run as a folding trace tree, live, from the OTLP JSON
// the local collector writes. It attaches to a session that is already running,
// the way you would attach to a log.
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"
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
	mock := flag.Bool("mockup", false, "browse the candidate layouts over a fixed fixture")
	fromObserve := flag.Bool("observe", false, "read spans back from Observe instead of the collector file")
	email := flag.String("email", "", "with -observe, whose spans to read (default: git user.email)")
	back := flag.Duration("since", 2*time.Hour, "with -observe, how far back the first read reaches")
	every := flag.Duration("poll", 15*time.Second, "with -observe, how often to re-read")
	flag.Parse()

	if *mock {
		if _, err := tea.NewProgram(ui.Mockup(), tea.WithAltScreen(), tea.WithMouseCellMotion()).Run(); err != nil {
			fmt.Fprintf(os.Stderr, "reel: %v\n", err)
			os.Exit(1)
		}
		return
	}
	if *fromObserve {
		src := otlp.Observe{
			Email:   accountEmail(*email),
			Session: *which,
		}
		if *list || *once {
			os.Exit(reportObserve(src, *back, *list))
		}
		os.Exit(watchObserve(src, *which, *every, *back))
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

// The datastream is shared across the organization, so a read with no owner
// would draw other people's sessions. The spans carry the Claude Code account's
// email, which ~/.claude.json already records; the git email is a different
// identity and in a personal repository it is the wrong one.
func accountEmail(given string) string {
	if given != "" {
		return given
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	blob, err := os.ReadFile(filepath.Join(home, ".claude.json"))
	if err != nil {
		return ""
	}
	var held struct {
		OAuthAccount struct {
			EmailAddress string `json:"emailAddress"`
		} `json:"oauthAccount"`
	}
	if json.Unmarshal(blob, &held) != nil {
		return ""
	}
	return strings.TrimSpace(held.OAuthAccount.EmailAddress)
}

func reportObserve(src otlp.Observe, back time.Duration, listing bool) int {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Minute)
	defer cancel()

	spans, err := src.Fetch(ctx, back)
	if err != nil {
		fmt.Fprintf(os.Stderr, "reel: %v\n", err)
		return 1
	}
	store := session.NewStore()
	store.Add(spans)

	if listing {
		fmt.Fprintf(os.Stderr, "reel: %d spans from %s\n", len(spans), otlp.ObserveDataset)
		for _, one := range store.Sessions() {
			fmt.Printf("%-12s %-40s %5d spans  %s\n",
				one.Service, one.Title(), one.Count, one.Last.Format("15:04:05"))
		}
		return 0
	}

	found := pick(store, src.Session)
	if found == nil {
		fmt.Fprintln(os.Stderr, "reel: no session in "+otlp.ObserveDataset)
		return 1
	}
	ui.Print(os.Stdout, found)
	return 0
}

func watchObserve(src otlp.Observe, which string, every, back time.Duration) int {
	stop := make(chan struct{})
	batches := make(chan []otlp.Span, 32)
	go otlp.FollowObserve(src, every, back, batches, stop)

	program := tea.NewProgram(
		ui.New(session.NewStore(), which, otlp.ObserveDataset),
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
