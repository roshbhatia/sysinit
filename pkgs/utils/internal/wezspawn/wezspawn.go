package wezspawn

import (
	"fmt"
	"os"
	"path/filepath"
	"syscall"
)

const Summary = "open a WezTerm window in the focused workspace and directory"

func Run(args []string) int {
	binary := os.Getenv("SYSINIT_WEZSPAWN")
	if !filepath.IsAbs(binary) {
		fmt.Fprintln(os.Stderr, "wezspawn: SYSINIT_WEZSPAWN must name the installed absolute executable path")
		return 1
	}
	if err := syscall.Exec(binary, append([]string{"wezspawn"}, args...), os.Environ()); err != nil {
		fmt.Fprintf(os.Stderr, "wezspawn: %v\n", err)
		return 1
	}
	return 0
}
