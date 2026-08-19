package cmd

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/roshbhatia/seshy/internal/session"
	"github.com/roshbhatia/seshy/internal/tmpl"
	"github.com/roshbhatia/seshy/internal/ui"
	"github.com/spf13/cobra"
)

var forceRemove bool

var removeCmd = &cobra.Command{
	Use:   "remove <session> <repo>",
	Short: "Remove a repository from a session",
	Args:  cobra.ExactArgs(2),
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		switch len(args) {
		case 0:
			sessions, _ := session.List()
			names := make([]string, len(sessions))
			for i, s := range sessions {
				names[i] = s.Name
			}
			return names, cobra.ShellCompDirectiveNoFileComp
		case 1:
			sessionPath, err := session.GetPath(args[0])
			if err != nil {
				return nil, cobra.ShellCompDirectiveNoFileComp
			}
			repos := session.GetSessionRepoInfos(sessionPath)
			names := make([]string, len(repos))
			for i, r := range repos {
				names[i] = r.Name
			}
			return names, cobra.ShellCompDirectiveNoFileComp
		}
		return nil, cobra.ShellCompDirectiveNoFileComp
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		name, repoName := args[0], args[1]

		if !session.Exists(name) {
			return fmt.Errorf("session %s not found", ui.AccentBold(name))
		}

		sessionPath, err := session.GetPath(name)
		if err != nil {
			return err
		}

		if !forceRemove {
			fmt.Fprintf(os.Stderr, "Remove repo %s from session %s? [y/N] ", ui.AccentBold(repoName), ui.AccentBold(name))
			reader := bufio.NewReader(os.Stdin)
			answer, _ := reader.ReadString('\n')
			answer = strings.TrimSpace(strings.ToLower(answer))
			if answer != "y" && answer != "yes" {
				fmt.Fprintln(os.Stderr, ui.Info("Cancelled."))
				return nil
			}
		}

		if err := session.RemoveRepoEntry(sessionPath, repoName, forceRemove); err != nil {
			return fmt.Errorf("failed to remove repo: %w", err)
		}

		// Re-render session templates with updated repo list (non-fatal)
		allRepos := session.GetSessionRepoInfos(sessionPath)
		data := session.BuildTemplateData(name, sessionPath, allRepos)
		sessionTmplDir := filepath.Join(config.ConfigDir(), "templates", "session")
		tmpl.RenderSessionDir(sessionTmplDir, sessionPath, data)

		fmt.Fprintln(os.Stderr, ui.Successf("Removed %s from session %s", ui.AccentBold(repoName), ui.AccentBold(name)))
		return nil
	},
}

func init() {
	removeCmd.Flags().BoolVarP(&forceRemove, "force", "f", false, "Skip confirmation prompt")
	rootCmd.AddCommand(removeCmd)
}
