package cmd

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

// resolve matches a query the same way the shell wrapper's --greedy path does:
// exact, then prefix, then substring. Both routes call this, so a name that
// works in one works in the other.
func resolveSession(query string) (session.Session, error) {
	// An empty query substring-matches every name, so without this it silently
	// resolves to whichever session sorts first.
	if strings.TrimSpace(query) == "" {
		return session.Session{}, fmt.Errorf("session name is empty")
	}
	sessions, err := session.List()
	if err != nil {
		return session.Session{}, fmt.Errorf("failed to list sessions: %w", err)
	}
	match := greedyMatch(query, sessions)
	if match == nil {
		return session.Session{}, fmt.Errorf("no session matches %s", ui.AccentBold(query))
	}
	return *match, nil
}

var switchName bool

var switchCmd = &cobra.Command{
	Use:     "switch <name>",
	Short:   "Resolve a session and print its path",
	Aliases: []string{"sw"},
	Long: `Resolve a session by fuzzy name and print its path.

A process cannot change its parent shell's directory, so this prints the path
and the shell integration from "sy init" does the cd. The name is matched
exactly, then by prefix, then by substring.`,
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeSessionNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		found, err := resolveSession(args[0])
		if err != nil {
			return err
		}
		if switchName {
			fmt.Println(found.Name)
			return nil
		}
		fmt.Println(found.Path)
		return nil
	},
}

type attachJSON struct {
	Name  string       `json:"name"`
	Path  string       `json:"path"`
	Repos []attachRepo `json:"repos"`
}

type attachRepo struct {
	Name   string `json:"name"`
	Path   string `json:"path"`
	Branch string `json:"branch"`
}

var attachCmd = &cobra.Command{
	Use:     "attach <name>",
	Short:   "Print the record a multiplexer needs to enter a session",
	Aliases: []string{"at"},
	Long: `Print the resolved session as JSON, for a multiplexer to act on.

seshy cannot attach anything itself: a wezterm workspace switch happens inside
wezterm, and a tmux one inside tmux. So this resolves the name and reports what
the caller needs, and the caller performs the switch. That keeps one matcher and
one source of session names behind every UI.`,
	Args:              cobra.ExactArgs(1),
	ValidArgsFunction: completeSessionNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		found, err := resolveSession(args[0])
		if err != nil {
			return err
		}
		repos := session.GetSessionRepoInfos(found.Path)
		out := attachJSON{Name: found.Name, Path: found.Path, Repos: make([]attachRepo, len(repos))}
		for i, repo := range repos {
			out.Repos[i] = attachRepo{Name: repo.Name, Path: repo.Path, Branch: repo.Branch}
		}
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		return enc.Encode(out)
	},
}

func init() {
	switchCmd.Flags().BoolVar(&switchName, "name", false, "Print the resolved name instead of the path")
	rootCmd.AddCommand(switchCmd)
	rootCmd.AddCommand(attachCmd)
}
