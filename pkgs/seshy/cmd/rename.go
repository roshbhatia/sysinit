package cmd

import (
	"fmt"
	"os"

	"github.com/roshbhatia/sysinit/pkgs/internal/ui"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

var renameCmd = &cobra.Command{
	Use:               "rename <old-name> <new-name>",
	Short:             "Rename a session",
	Args:              cobra.ExactArgs(2),
	ValidArgsFunction: completeSessionNames,
	RunE: func(cmd *cobra.Command, args []string) error {
		oldName, newName := args[0], args[1]

		if err := session.RenameSession(oldName, newName); err != nil {
			return fmt.Errorf("failed to rename session: %w", err)
		}

		newPath, _ := session.GetPath(newName)
		fmt.Fprintln(os.Stderr, ui.Successf("Renamed %s to %s", ui.AccentBold(oldName), ui.AccentBold(newName)))
		fmt.Fprintf(os.Stderr, "  %s %s\n", ui.Faint("path:"), newPath)
		fmt.Fprintln(os.Stderr, ui.Info("Note: branch names are not changed automatically."))
		return nil
	},
}

func init() {
	rootCmd.AddCommand(renameCmd)
}
