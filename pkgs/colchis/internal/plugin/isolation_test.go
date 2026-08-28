package plugin

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

func TestIsolationRejectsAmbientCredentials(t *testing.T) {
	t.Parallel()

	_, err := isolatedEnvironment(IsolationProfile{
		Environment: map[string]string{"SSH_AUTH_SOCK": "/tmp/agent.sock"},
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("isolatedEnvironment() error = %v", err)
	}
}

func TestIsolationRejectsPluginWideSecrets(t *testing.T) {
	t.Parallel()

	_, err := isolatedEnvironment(IsolationProfile{SecretNames: []string{"MODEL_TOKEN"}})
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("isolatedEnvironment() error = %v", err)
	}
}

func TestIsolationRejectsLoaderInjection(t *testing.T) {
	t.Parallel()

	_, err := isolatedEnvironment(IsolationProfile{
		Environment: map[string]string{"DYLD_INSERT_LIBRARIES": "/tmp/injected.dylib"},
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("isolatedEnvironment() error = %v", err)
	}
}

func TestIsolationEnvironmentContainsOnlyDeclaredValues(t *testing.T) {
	t.Parallel()

	environment, err := isolatedEnvironment(IsolationProfile{
		Environment: map[string]string{"FIXTURE_VALUE": "declared"},
	})
	if err != nil {
		t.Fatalf("isolatedEnvironment() returned %v", err)
	}
	joined := strings.Join(environment, "\n")
	for _, expected := range []string{
		"COLCHIS_PLUGIN_ISOLATION=confined", "FIXTURE_VALUE=declared", "HOME=/var/empty", "LANG=C.UTF-8",
	} {
		if !strings.Contains(joined, expected) {
			t.Fatalf("environment does not contain %q: %q", expected, joined)
		}
	}
	if strings.Contains(joined, "PATH=") {
		t.Fatalf("environment contains undeclared PATH: %q", joined)
	}
}

func TestIsolationRequiresExplicitDangerousOptIn(t *testing.T) {
	t.Parallel()

	directory := t.TempDir()
	plan, err := (PlatformIsolation{}).Prepare(context.Background(), IsolationProfile{
		Executable: "/bin/sh", Arguments: []string{"-c", "exit 0"}, WorkingDirectory: directory,
		DangerouslyAllowAll: true,
	})
	if err != nil {
		t.Fatalf("Prepare() returned %v", err)
	}
	if plan.Executable != "/bin/sh" || !strings.Contains(
		strings.Join(plan.Environment, "\n"), "COLCHIS_PLUGIN_ISOLATION=dangerously-allow-all",
	) {
		t.Fatalf("dangerous launch plan = %#v", plan)
	}
}

func TestIsolationEnvironmentUsesDeclaredPrivateHome(t *testing.T) {
	t.Parallel()

	environment, err := isolatedEnvironment(IsolationProfile{HomeDirectory: "/tmp/plugin-home"})
	if err != nil {
		t.Fatalf("isolatedEnvironment() returned %v", err)
	}
	if !strings.Contains(strings.Join(environment, "\n"), "HOME=/tmp/plugin-home") {
		t.Fatalf("environment = %#v", environment)
	}
}

func TestIsolationProfileRequiresCleanAbsoluteScopes(t *testing.T) {
	t.Parallel()

	err := validateIsolationProfile(IsolationProfile{
		Executable: "/bin/fixture", WorkingDirectory: "/tmp/fixture",
		ReadPaths: []string{"/tmp/fixture"}, LocalSocketPaths: []string{"relative"},
	})
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("validateIsolationProfile() error = %v", err)
	}
}

func TestLinuxIsolationRejectsEndpointClaimsItCannotEnforce(t *testing.T) {
	if runtime.GOOS != "linux" {
		t.Skip("Linux isolation policy")
	}

	_, err := prepareLinuxSandbox(IsolationProfile{
		Executable: "/bin/fixture", WorkingDirectory: "/tmp/fixture",
		NetworkEndpoints: []string{"example.invalid:443"},
	}, nil)
	if !domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
		t.Fatalf("prepareLinuxSandbox() error = %v", err)
	}
}

func TestDarwinSandboxDeclaresOnlyRequestedNetworkEndpoint(t *testing.T) {
	t.Parallel()

	profile := darwinSandboxProfile(IsolationProfile{
		Executable: "/bin/fixture", WorkingDirectory: "/tmp/fixture",
		NetworkEndpoints: []string{"example.invalid:443"},
		LocalSocketPaths: []string{"/private/var/run/nix-daemon.socket"},
	})
	if !strings.Contains(profile, `remote tcp "example.invalid:443"`) {
		t.Fatalf("sandbox profile lacks endpoint: %s", profile)
	}
	if strings.Contains(profile, "network*") {
		t.Fatalf("sandbox profile permits unrestricted network access: %s", profile)
	}
	if !strings.Contains(profile, `(subpath "/private/var/db/timezone")`) {
		t.Fatalf("sandbox profile lacks timezone data: %s", profile)
	}
	if !strings.Contains(profile, `remote unix-socket (literal "/private/var/run/nix-daemon.socket")`) ||
		strings.Contains(profile, "/private/var/run/ssh-agent.socket") {
		t.Fatalf("Darwin local socket profile = %s", profile)
	}
}

func TestDarwinIsolationPermitsNullDevice(t *testing.T) {
	if runtime.GOOS != "darwin" {
		t.Skip("Darwin sandbox policy")
	}
	workingDirectory := t.TempDir()
	plan, err := (PlatformIsolation{}).Prepare(context.Background(), IsolationProfile{
		Executable:       "/bin/sh",
		Arguments:        []string{"-c", "cat /dev/null && head -c 1 /dev/urandom >/dev/null && printf probe >/dev/null"},
		WorkingDirectory: workingDirectory, ReadPaths: []string{workingDirectory},
	})
	if err != nil {
		if domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
			t.Skipf("platform isolation backend is unavailable: %v", err)
		}
		t.Fatalf("Prepare() returned %v", err)
	}
	command := exec.Command(plan.Executable, plan.Arguments...)
	command.Dir = plan.WorkingDirectory
	command.Env = plan.Environment
	runErr := command.Run()
	cleanupErr := plan.Cleanup()
	if err := errors.Join(runErr, cleanupErr); err != nil {
		t.Fatalf("null device probe returned %v", err)
	}
}

func TestPlatformIsolationExecutesFileDenial(t *testing.T) {
	allowedDirectory := t.TempDir()
	deniedDirectory := t.TempDir()
	allowedPath := filepath.Join(allowedDirectory, "allowed.txt")
	deniedPath := filepath.Join(deniedDirectory, "denied.txt")
	if err := os.WriteFile(allowedPath, []byte("allowed"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	if err := os.WriteFile(deniedPath, []byte("denied"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	testExecutable := "/bin/cat"
	if runtime.GOOS == "linux" {
		var err error
		testExecutable, err = exec.LookPath("cat")
		if err != nil {
			t.Skip("cat executable is unavailable")
		}
	}
	allowedErr := runIsolatedReadProbe(t, testExecutable, allowedDirectory, allowedPath)
	if allowedErr != nil {
		var domainErr *domain.Error
		if errors.As(allowedErr, &domainErr) && domainErr.Code == domain.ErrorCodeUnauthorized {
			t.Skipf("platform isolation backend is unavailable: %v", allowedErr)
		}
		t.Fatalf("declared file probe returned %v", allowedErr)
	}
	if err := runIsolatedReadProbe(t, testExecutable, allowedDirectory, deniedPath); err == nil {
		t.Fatal("undeclared file probe succeeded")
	}
}

func TestDarwinIsolationDeniesSessionEscape(t *testing.T) {
	if runtime.GOOS != "darwin" {
		t.Skip("Darwin sandbox policy")
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable() returned %v", err)
	}
	workingDirectory := t.TempDir()
	deniedPath := filepath.Join(t.TempDir(), "denied.txt")
	if err := os.WriteFile(deniedPath, []byte("denied"), 0o600); err != nil {
		t.Fatalf("WriteFile() returned %v", err)
	}
	for _, role := range []string{"setsid-probe", "setpgid-probe"} {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		plan, err := (PlatformIsolation{}).Prepare(ctx, IsolationProfile{
			Executable: executable, Arguments: []string{"-test.run=^TestProcessTreeFixture$"},
			WorkingDirectory: workingDirectory, ReadPaths: []string{executable, workingDirectory},
			Environment: map[string]string{treeFixtureRole: role, treeFixtureDeny: deniedPath},
		})
		if err != nil {
			cancel()
			if domain.IsErrorCode(err, domain.ErrorCodeUnauthorized) {
				t.Skipf("platform isolation backend is unavailable: %v", err)
			}
			t.Fatalf("Prepare() returned %v", err)
		}
		command := exec.CommandContext(ctx, plan.Executable, plan.Arguments...)
		command.Dir = plan.WorkingDirectory
		command.Env = plan.Environment
		err = command.Run()
		cleanupErr := plan.Cleanup()
		cancel()
		var exitErr *exec.ExitError
		if !errors.As(err, &exitErr) || exitErr.ExitCode() != 23 || cleanupErr != nil {
			t.Fatalf("%s returned %v with cleanup %v", role, err, cleanupErr)
		}
	}
}

func runIsolatedReadProbe(
	t *testing.T,
	executable string,
	workingDirectory string,
	target string,
) error {
	t.Helper()
	plan, err := (PlatformIsolation{}).Prepare(context.Background(), IsolationProfile{
		Executable: executable, Arguments: []string{target},
		WorkingDirectory: workingDirectory, ReadPaths: []string{workingDirectory},
	})
	if err != nil {
		return err
	}
	defer plan.Cleanup()
	command := exec.Command(plan.Executable, plan.Arguments...)
	command.Dir = plan.WorkingDirectory
	command.Env = append([]string(nil), plan.Environment...)
	output, err := command.CombinedOutput()
	if err != nil {
		return fmt.Errorf("isolated probe failed: %w: %s", err, strings.TrimSpace(string(output)))
	}
	return nil
}
