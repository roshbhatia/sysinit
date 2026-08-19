package main

import (
	"os"

	"github.com/roshbhatia/sysinit/pkgs/seshy/cmd"
	"github.com/roshbhatia/sysinit/pkgs/seshy/internal/config"
)

func main() {
	// Ensure sessions root directory exists
	if err := config.EnsureSessionsRoot(); err != nil {
		os.Exit(1)
	}

	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}
