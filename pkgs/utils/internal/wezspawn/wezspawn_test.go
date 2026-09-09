package wezspawn

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"testing"
)

func TestDelegatePreservesProcessIOAndExitStatus(t *testing.T) {
	binary, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	command := exec.Command(binary, "-test.run=TestDelegateProcess")
	command.Env = append(os.Environ(), "WEZSPAWN_TEST_MODE=delegate", "SYSINIT_WEZSPAWN="+binary)
	command.Stdin = strings.NewReader("input forwarded")
	var stderr strings.Builder
	command.Stderr = &stderr
	output, err := command.Output()
	exit, ok := err.(*exec.ExitError)
	if !ok || exit.ExitCode() != 7 {
		t.Fatalf("exit = %v; want 7", err)
	}
	if string(output) != "first|two words|input forwarded" || stderr.String() != "error forwarded" {
		t.Fatalf("stdout = %q; stderr = %q", output, stderr.String())
	}
}

func TestDelegateRejectsRelativeExecutable(t *testing.T) {
	t.Setenv("SYSINIT_WEZSPAWN", "wezspawn")
	if Run(nil) != 1 {
		t.Fatal("relative executable was accepted")
	}
}

func TestDelegateProcess(t *testing.T) {
	switch os.Getenv("WEZSPAWN_TEST_MODE") {
	case "delegate":
		if err := os.Setenv("WEZSPAWN_TEST_MODE", "target"); err != nil {
			t.Fatal(err)
		}
		os.Exit(Run([]string{"-test.run=TestDelegateProcess", "--", "first", "two words"}))
	case "target":
		input, err := io.ReadAll(os.Stdin)
		if err != nil {
			os.Exit(9)
		}
		fmt.Print(strings.Join(os.Args[3:], "|") + "|" + string(input))
		fmt.Fprint(os.Stderr, "error forwarded")
		os.Exit(7)
	}
}
