package cmd

import (
	"fmt"
	"os"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

var unarchiveCmd = &cobra.Command{
	Use:     "unarchive [name]",
	Short:   "Restore an archived session",
	Aliases: []string{"restore"},
	Long: `Restore an archived session back into the sessions directory.

Unarchiving does not prompt for confirmation, because nothing is destroyed.`,
	Args:              cobra.MaximumNArgs(1),
	ValidArgsFunction: completeArchivedNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("loading config: %w", err)
		}

		archived, err := session.ListArchived()
		if err != nil {
			return fmt.Errorf("listing archived sessions: %w", err)
		}
		if len(args) == 0 && len(archived) == 0 {
			fmt.Fprintln(os.Stderr, ui.Info("No archived sessions."))
			return nil
		}

		name, err := selectSessionName(args, cfg.SessionPicker, sessionNames(archived))
		if err != nil {
			return err
		}
		if name == "" {
			return nil
		}

		sessionPath, err := session.Unarchive(name)
		if err != nil {
			return err
		}

		fmt.Fprintln(os.Stderr, ui.Successf("Restored session %s", ui.AccentBold(name)))
		fmt.Fprintf(os.Stderr, "  %s %s\n", ui.Faint("path:"), sessionPath)
		return nil
	},
}

func init() {
	rootCmd.AddCommand(unarchiveCmd)
}
