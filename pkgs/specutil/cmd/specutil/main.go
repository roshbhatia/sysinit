// Command specutil projects spec-framework change artifacts into other artifacts
// and visualizations. It performs no network I/O.
package main

import (
	"os"

	"github.com/roshbhatia/specutil/internal/cli"
)

// version is set at build time via -ldflags "-X main.version=<tag>".
var version = "dev"

func main() {
	if err := cli.NewRootCmd(version).Execute(); err != nil {
		// A `next` that cannot schedule pending work is a cycle, not a crash, and
		// a runner loop must be able to tell the two apart.
		if cli.IsDependencyCycle(err) {
			os.Exit(2)
		}
		os.Exit(1)
	}
}
