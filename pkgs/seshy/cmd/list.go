package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"time"

	"github.com/roshbhatia/seshy/internal/session"
	"github.com/roshbhatia/seshy/internal/ui"
	"github.com/spf13/cobra"
)

var (
	listJSON     bool
	listNames    bool
	listPaths    bool
	listArchived bool
)

var listCmd = &cobra.Command{
	Use:     "list",
	Short:   "List all sessions",
	Aliases: []string{"ls"},
	RunE: func(cmd *cobra.Command, args []string) error {
		flagCount := 0
		if listJSON {
			flagCount++
		}
		if listNames {
			flagCount++
		}
		if listPaths {
			flagCount++
		}
		if flagCount > 1 {
			return fmt.Errorf("--json, --names, and --paths are mutually exclusive")
		}

		list, empty := session.List, noSessionsMessage()
		if listArchived {
			list, empty = session.ListArchived, "No archived sessions. Archive one with "+ui.AccentBold("sy archive <name>")
		}

		sessions, err := list()
		if err != nil {
			return fmt.Errorf("failed to list sessions: %w", err)
		}

		format := ""
		if listJSON {
			format = "json"
		} else if listNames {
			format = "names"
		} else if listPaths {
			format = "paths"
		}
		return printSessionList(sessions, format, empty)
	},
}

type sessionJSON struct {
	Name         string `json:"name"`
	Path         string `json:"path"`
	RepoCount    int    `json:"repoCount"`
	LastModified string `json:"lastModified"`
}

func printSessionsJSON(sessions []session.Session) error {
	out := make([]sessionJSON, len(sessions))
	for i, s := range sessions {
		out[i] = sessionJSON{
			Name:         s.Name,
			Path:         s.Path,
			RepoCount:    s.RepoCount,
			LastModified: s.LastModified.Format(time.RFC3339),
		}
	}
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "  ")
	return enc.Encode(out)
}

func formatRelativeTime(t time.Time) string {
	d := time.Since(t)
	switch {
	case d < time.Minute:
		return "just now"
	case d < time.Hour:
		m := int(d.Minutes())
		if m == 1 {
			return "1 minute ago"
		}
		return fmt.Sprintf("%d minutes ago", m)
	case d < 24*time.Hour:
		h := int(d.Hours())
		if h == 1 {
			return "1 hour ago"
		}
		return fmt.Sprintf("%d hours ago", h)
	case d < 7*24*time.Hour:
		days := int(d.Hours() / 24)
		if days == 1 {
			return "1 day ago"
		}
		return fmt.Sprintf("%d days ago", days)
	default:
		return t.Format("Jan 2, 2006")
	}
}

func init() {
	listCmd.Flags().BoolVar(&listJSON, "json", false, "Output JSON")
	listCmd.Flags().BoolVar(&listNames, "names", false, "Output session names only")
	listCmd.Flags().BoolVar(&listPaths, "paths", false, "Output session paths only")
	listCmd.Flags().BoolVar(&listArchived, "archived", false, "List archived sessions instead of active ones")
	rootCmd.AddCommand(listCmd)
}
