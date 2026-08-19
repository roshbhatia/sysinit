package cmd

import (
	"fmt"
	"strings"

	"github.com/roshbhatia/seshy/internal/session"
	"github.com/roshbhatia/seshy/internal/ui"
	"github.com/spf13/cobra"
)

const version = "4.0.0"

var greedyQuery string

var rootCmd = &cobra.Command{
	Use:     "sy",
	Short:   "Session manager for multi-repo development",
	Version: version,
	// Runs after argument and flag validation, so usage still prints for a
	// malformed invocation but not for a runtime failure like "session not found".
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		cmd.SilenceUsage = true
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		sessions, err := session.List()
		if err != nil {
			return fmt.Errorf("failed to list sessions: %w", err)
		}

		if greedyQuery != "" {
			match := greedyMatch(greedyQuery, sessions)
			if match == nil {
				return fmt.Errorf("no session matches %q", greedyQuery)
			}
			fmt.Println(match.Path)
			return nil
		}

		// Default: show list (same as `sy list`)
		return printSessionList(sessions, "", noSessionsMessage())
	},
}

// noSessionsMessage is shown when the sessions table is empty.
func noSessionsMessage() string {
	return "No sessions yet. Create one with " + ui.AccentBold("sy new <name>")
}

// printSessionList renders sessions in the requested format. empty is the
// message shown when the list has no entries and the format is the human table.
func printSessionList(sessions []session.Session, format, empty string) error {
	switch format {
	case "json":
		return printSessionsJSON(sessions)
	case "names":
		for _, s := range sessions {
			fmt.Println(s.Name)
		}
		return nil
	case "paths":
		for _, s := range sessions {
			fmt.Println(s.Path)
		}
		return nil
	}

	// Default: human-readable table
	if len(sessions) == 0 {
		fmt.Println(ui.Info(empty))
		return nil
	}

	// Calculate column widths
	nameW, reposW := len("SESSION"), len("REPOS")
	rows := make([]struct{ name, repos, modified string }, len(sessions))
	for i, s := range sessions {
		rows[i].name = s.Name
		rows[i].repos = fmt.Sprintf("%d", s.RepoCount)
		rows[i].modified = formatRelativeTime(s.LastModified)
		if len(rows[i].name) > nameW {
			nameW = len(rows[i].name)
		}
		if len(rows[i].repos) > reposW {
			reposW = len(rows[i].repos)
		}
	}

	// Pad before coloring. ANSI escapes have no display width, so a %-Ns verb
	// applied to an already-colored string counts the escape bytes and drops
	// the padding, which is what threw the header out of line with the rows.
	fmt.Printf("%s  %s  %s\n",
		ui.StdoutColor(ui.ColorPurple, pad("SESSION", nameW)),
		ui.StdoutColor(ui.ColorPurple, pad("REPOS", reposW)),
		ui.StdoutColor(ui.ColorPurple, "MODIFIED"))
	for _, r := range rows {
		fmt.Printf("%s  %s  %s\n", pad(r.name, nameW), pad(r.repos, reposW), ui.StdoutFaint(r.modified))
	}
	return nil
}

// pad right-pads s with spaces to width w.
func pad(s string, w int) string {
	if n := w - len(s); n > 0 {
		return s + strings.Repeat(" ", n)
	}
	return s
}

// greedyMatch returns the best session matching query: exact > prefix > substring (case-insensitive).
func greedyMatch(query string, sessions []session.Session) *session.Session {
	q := strings.ToLower(query)
	for i, s := range sessions {
		if strings.ToLower(s.Name) == q {
			return &sessions[i]
		}
	}
	for i, s := range sessions {
		if strings.HasPrefix(strings.ToLower(s.Name), q) {
			return &sessions[i]
		}
	}
	for i, s := range sessions {
		if strings.Contains(strings.ToLower(s.Name), q) {
			return &sessions[i]
		}
	}
	return nil
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	rootCmd.SetVersionTemplate(fmt.Sprintf("sy version %s\n", version))
	rootCmd.Flags().StringVar(&greedyQuery, "greedy", "", "Fuzzy-match a session name and print its path")
}
