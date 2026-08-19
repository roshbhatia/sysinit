package main

import (
	"os"

	"github.com/roshbhatia/sysinit/pkgs/specutil/internal/cli"
)

var version = "dev"

func main() {
	if err := cli.NewRootCmd(version).Execute(); err != nil {
		if cli.IsDependencyCycle(err) {
			os.Exit(2)
		}
		os.Exit(1)
	}
}
