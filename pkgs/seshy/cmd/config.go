package cmd

import (
	"fmt"

	"github.com/roshbhatia/seshy/internal/config"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
)

var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Show effective configuration",
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := config.Load()
		if err != nil {
			return err
		}
		out, err := yaml.Marshal(cfg)
		if err != nil {
			return fmt.Errorf("marshalling config: %w", err)
		}
		fmt.Print(string(out))
		return nil
	},
}

func init() {
	rootCmd.AddCommand(configCmd)
}
