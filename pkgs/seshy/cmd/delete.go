package cmd

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/hook"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

var (
	forceDelete    bool
	deleteArchived bool
)

var deleteCmd = &cobra.Command{
	Use:     "delete [name]",
	Short:   "Delete a session",
	Aliases: []string{"rm"},
	Args:    cobra.MaximumNArgs(1),
	ValidArgsFunction: func(cmd *cobra.Command, args []string, toComplete string) ([]string, cobra.ShellCompDirective) {
		if deleteArchived {
			return completeArchivedNames(cmd, args, toComplete)
		}
		return completeSessionNames(cmd, args, toComplete)
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("loading config: %w", err)
		}

		list, exists := session.List, session.Exists
		if deleteArchived {
			list, exists = session.ListArchived, session.ArchivedExists
		}

		sessions, err := list()
		if err != nil {
			return fmt.Errorf("listing sessions: %w", err)
		}
		if len(args) == 0 && len(sessions) == 0 {
			fmt.Fprintln(os.Stderr, ui.Info("No sessions to delete."))
			return nil
		}

		name, err := selectSessionName(args, cfg.SessionPicker, sessionNames(sessions))
		if err != nil {
			return err
		}
		if name == "" {
			return nil
		}

		if !exists(name) {
			return fmt.Errorf("session %s not found", ui.AccentBold(name))
		}

		if !forceDelete {
			fmt.Fprintf(os.Stderr, "Delete session %s and its worktrees/branches? [y/N] ", ui.AccentBold(name))
			reader := bufio.NewReader(os.Stdin)
			answer, _ := reader.ReadString('\n')
			answer = strings.TrimSpace(strings.ToLower(answer))
			if answer != "y" && answer != "yes" {
				fmt.Fprintln(os.Stderr, ui.Info("Cancelled."))
				return nil
			}
		}

		if deleteArchived {
			if err := session.DeleteArchived(name, forceDelete); err != nil {
				return reportDeleteResult(name, err)
			}
		} else {
			// Run pre-delete hooks with full repo info
			sessionPath, _ := session.GetPath(name)
			repoInfos := session.GetSessionRepoInfos(sessionPath)
			data := session.BuildTemplateData(name, sessionPath, repoInfos)
			hook.Run("pre-delete", cfg.Hooks.PreDelete, data, sessionPath)

			if err := session.Delete(name, forceDelete); err != nil {
				return reportDeleteResult(name, err)
			}
		}

		fmt.Fprintln(os.Stderr, ui.Successf("Deleted session %s", ui.AccentBold(name)))
		return nil
	},
}

// reportDeleteResult turns a delete error into either a hard failure or, when
// --force already removed the session, a warning plus success.
func reportDeleteResult(name string, err error) error {
	if !errors.Is(err, session.ErrCleanupIncomplete) {
		return fmt.Errorf("failed to delete session: %w", err)
	}
	fmt.Fprintln(os.Stderr, ui.Warningf("Deleted session %s, but some worktrees or branches were left behind:", ui.AccentBold(name)))
	fmt.Fprintf(os.Stderr, "  %v\n", err)
	return nil
}

func init() {
	deleteCmd.Flags().BoolVarP(&forceDelete, "force", "f", false, "Skip confirmation and delete even if worktree cleanup fails")
	deleteCmd.Flags().BoolVar(&deleteArchived, "archived", false, "Delete an archived session instead of an active one")
	rootCmd.AddCommand(deleteCmd)
}
