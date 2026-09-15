package forward

import (
	"fmt"
	"os"
	"path/filepath"
	"syscall"
)

func Command(variable, name string) func([]string) int {
	return func(args []string) int {
		binary := os.Getenv(variable)
		if !filepath.IsAbs(binary) {
			fmt.Fprintf(os.Stderr, "%s: %s must name an absolute executable path\n", name, variable)
			return 1
		}
		if err := syscall.Exec(binary, append([]string{name}, args...), os.Environ()); err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", name, err)
			return 1
		}
		return 0
	}
}
