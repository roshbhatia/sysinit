package forward

import (
	"os"
	"os/exec"
	"testing"
)

func TestForwardHelper(t *testing.T) {
	if os.Getenv("FORWARD_TEST_CHILD") == "1" {
		os.Exit(Command("FORWARD_TEST_EXECUTABLE", "alias")([]string{"-c", "printf '%s' \"$0:$1\"; exit 23", "child", "two words"}))
	}
}

func TestArgumentsAndExitCode(t *testing.T) {
	shell, err := exec.LookPath("sh")
	if err != nil {
		t.Fatal(err)
	}
	cmd := exec.Command(os.Args[0], "-test.run=^TestForwardHelper$")
	cmd.Env = append(os.Environ(), "FORWARD_TEST_CHILD=1", "FORWARD_TEST_EXECUTABLE="+shell)
	output, err := cmd.CombinedOutput()
	exit, ok := err.(*exec.ExitError)
	if !ok || exit.ExitCode() != 23 || string(output) != "child:two words" {
		t.Fatalf("output=%q error=%v", output, err)
	}
}

func TestRejectRelativeExecutable(t *testing.T) {
	for _, path := range []string{"", "bin/worker"} {
		t.Setenv("FORWARD_TEST_EXECUTABLE", path)
		if Command("FORWARD_TEST_EXECUTABLE", "worker")(nil) != 1 {
			t.Fatal("accepted relative executable")
		}
	}
}

func TestMissingExecutable(t *testing.T) {
	t.Setenv("FORWARD_TEST_EXECUTABLE", t.TempDir()+"/missing")
	if Command("FORWARD_TEST_EXECUTABLE", "worker")(nil) != 1 {
		t.Fatal("missing executable succeeded")
	}
}
