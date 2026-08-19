package cmd

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/spf13/cobra"
)

var configEditCmd = &cobra.Command{
	Use:   "edit",
	Short: "Open config file in editor",
	RunE: func(cmd *cobra.Command, args []string) error {
		path := config.ConfigPath()

		// Create default config if missing
		if _, err := os.Stat(path); os.IsNotExist(err) {
			if err := config.WriteDefault(); err != nil {
				return fmt.Errorf("creating default config: %w", err)
			}
		}

		editor := os.Getenv("EDITOR")
		if editor == "" {
			editor = "vi"
		}

		c := exec.Command(editor, path)
		c.Stdin = os.Stdin
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		return c.Run()
	},
}

func init() {
	configCmd.AddCommand(configEditCmd)
}
