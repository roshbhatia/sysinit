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
		// A missing lock entry is a distinguishable, non-fatal outcome (exit 3)
		// so `lock get` callers can branch on "absent" vs a real error.
		if cli.IsNoMapping(err) {
			os.Exit(3)
		}
		// A `next` that cannot schedule pending work is a cycle, not a crash, and
		// a runner loop must be able to tell the two apart.
		if cli.IsDependencyCycle(err) {
			os.Exit(2)
		}
		os.Exit(1)
	}
}
