package cmd

import (
	"fmt"
	"os"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/roshbhatia/seshy/internal/session"
	"github.com/roshbhatia/seshy/internal/ui"
	"github.com/spf13/cobra"
)

var archiveCmd = &cobra.Command{
	Use:   "archive [name]",
	Short: "Move a session into the archive",
	Long: `Move a session into the archive.

Archiving keeps worktrees, branches, and uncommitted work intact. It only moves
the session out of the way. Archived sessions no longer appear in "sy list".

List them with "sy list --archived". Restore one with "sy unarchive <name>".
Archiving does not prompt for confirmation, because nothing is destroyed.`,
	Args:              cobra.MaximumNArgs(1),
	ValidArgsFunction: completeSessionNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("loading config: %w", err)
		}

		sessions, err := session.List()
		if err != nil {
			return fmt.Errorf("listing sessions: %w", err)
		}
		if len(args) == 0 && len(sessions) == 0 {
			fmt.Fprintln(os.Stderr, ui.Info("No sessions to archive."))
			return nil
		}

		name, err := selectSessionName(args, cfg.SessionPicker, sessionNames(sessions))
		if err != nil {
			return err
		}
		if name == "" {
			return nil
		}

		archivePath, err := session.Archive(name)
		if err != nil {
			return err
		}

		fmt.Fprintln(os.Stderr, ui.Successf("Archived session %s", ui.AccentBold(name)))
		fmt.Fprintf(os.Stderr, "  %s %s\n", ui.Faint("path:"), archivePath)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(archiveCmd)
}
