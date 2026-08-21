package cmd

import (
	"fmt"
	"os"

	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/session"
	"github.com/spf13/cobra"
)

var (
	currentPath  bool
	currentQuiet bool
)

var currentCmd = &cobra.Command{
	Use:     "current",
	Short:   "Print the session holding the working directory",
	Aliases: []string{"cur"},
	Long: `Print the session that holds the working directory.

Nothing records an "active session", so this resolves it from the working
directory. Use it from a prompt, a status line or a pane widget instead of
each one re-deriving the answer from a path.

Exits non-zero when the working directory is outside every session.`,
	Args: cobra.NoArgs,
	RunE: func(cmd *cobra.Command, args []string) error {
		dir, err := os.Getwd()
		if err != nil {
			return err
		}
		found, ok := session.Containing(dir)
		if !ok {
			if currentQuiet {
				cmd.SilenceErrors = true
			}
			return fmt.Errorf("not inside a session")
		}
		if currentPath {
			fmt.Println(found.Path)
			return nil
		}
		fmt.Println(found.Name)
		return nil
	},
}

func init() {
	currentCmd.Flags().BoolVar(&currentPath, "path", false, "Print the session path instead of its name")
	currentCmd.Flags().BoolVarP(&currentQuiet, "quiet", "q", false, "Print nothing when outside a session")
	rootCmd.AddCommand(currentCmd)
}
