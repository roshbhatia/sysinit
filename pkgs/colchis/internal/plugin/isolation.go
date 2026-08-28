package plugin

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sort"
	"strings"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
)

type IsolationProfile struct {
	Executable          string            `json:"executable"`
	Arguments           []string          `json:"arguments"`
	WorkingDirectory    string            `json:"workingDirectory"`
	HomeDirectory       string            `json:"homeDirectory"`
	ReadPaths           []string          `json:"readPaths"`
	WritePaths          []string          `json:"writePaths"`
	Environment         map[string]string `json:"environment"`
	SecretNames         []string          `json:"secretNames"`
	NetworkEndpoints    []string          `json:"networkEndpoints"`
	LocalSocketPaths    []string          `json:"localSocketPaths"`
	DangerouslyAllowAll bool              `json:"dangerouslyAllowAll"`
}

type LaunchPlan struct {
	Executable       string
	Arguments        []string
	WorkingDirectory string
	Environment      []string
	cleanup          func() error
}

func (plan LaunchPlan) Cleanup() error {
	if plan.cleanup == nil {
		return nil
	}
	return plan.cleanup()
}

type IsolationBackend interface {
	Prepare(context.Context, IsolationProfile) (LaunchPlan, error)
}

type PlatformIsolation struct{}

func (PlatformIsolation) Prepare(_ context.Context, profile IsolationProfile) (LaunchPlan, error) {
	if err := validateIsolationProfile(profile); err != nil {
		return LaunchPlan{}, err
	}
	profile, err := canonicalIsolationProfile(profile)
	if err != nil {
		return LaunchPlan{}, err
	}
	environment, err := isolatedEnvironment(profile)
	if err != nil {
		return LaunchPlan{}, err
	}
	if profile.DangerouslyAllowAll {
		return LaunchPlan{
			Executable: profile.Executable, Arguments: append([]string(nil), profile.Arguments...),
			WorkingDirectory: profile.WorkingDirectory, Environment: environment,
		}, nil
	}
	switch runtime.GOOS {
	case "darwin":
		return prepareDarwinSandbox(profile, environment)
	case "linux":
		return prepareLinuxSandbox(profile, environment)
	default:
		return LaunchPlan{}, &domain.Error{
			Code: domain.ErrorCodeUnsupportedVersion, Op: "prepare isolation", Resource: runtime.GOOS,
			Message: "operating system has no configured plugin isolation backend",
		}
	}
}

func canonicalIsolationProfile(profile IsolationProfile) (IsolationProfile, error) {
	canonical := profile
	var err error
	canonical.Executable, err = canonicalIsolationPath(profile.Executable)
	if err != nil {
		return IsolationProfile{}, err
	}
	canonical.WorkingDirectory, err = canonicalIsolationPath(profile.WorkingDirectory)
	if err != nil {
		return IsolationProfile{}, err
	}
	if profile.HomeDirectory != "" {
		canonical.HomeDirectory, err = canonicalIsolationPath(profile.HomeDirectory)
		if err != nil {
			return IsolationProfile{}, err
		}
	}
	canonical.ReadPaths = make([]string, len(profile.ReadPaths))
	for index, path := range profile.ReadPaths {
		canonical.ReadPaths[index], err = canonicalIsolationPath(path)
		if err != nil {
			return IsolationProfile{}, err
		}
	}
	canonical.WritePaths = make([]string, len(profile.WritePaths))
	for index, path := range profile.WritePaths {
		canonical.WritePaths[index], err = canonicalIsolationPath(path)
		if err != nil {
			return IsolationProfile{}, err
		}
	}
	canonical.LocalSocketPaths = make([]string, len(profile.LocalSocketPaths))
	for index, path := range profile.LocalSocketPaths {
		canonical.LocalSocketPaths[index], err = canonicalIsolationPath(path)
		if err != nil {
			return IsolationProfile{}, err
		}
	}
	return canonical, nil
}

func canonicalIsolationPath(path string) (string, error) {
	canonical, err := filepath.EvalSymlinks(path)
	if err != nil {
		return "", invalidIsolation(path, "plugin path scope cannot be resolved")
	}
	return canonical, nil
}

func validateIsolationProfile(profile IsolationProfile) error {
	if profile.Executable == "" || !filepath.IsAbs(profile.Executable) {
		return invalidIsolation(profile.Executable, "plugin executable must be an absolute path")
	}
	if profile.WorkingDirectory == "" || !filepath.IsAbs(profile.WorkingDirectory) {
		return invalidIsolation(profile.WorkingDirectory, "plugin working directory must be an absolute path")
	}
	if profile.HomeDirectory != "" &&
		(!filepath.IsAbs(profile.HomeDirectory) || filepath.Clean(profile.HomeDirectory) != profile.HomeDirectory) {
		return invalidIsolation(profile.HomeDirectory, "plugin home directory must be a clean absolute path")
	}
	for _, paths := range [][]string{profile.ReadPaths, profile.WritePaths, profile.LocalSocketPaths} {
		for _, path := range paths {
			if path == "" || !filepath.IsAbs(path) || filepath.Clean(path) != path {
				return invalidIsolation(path, "plugin path scope must be a clean absolute path")
			}
		}
	}
	if err := validateUniqueStrings(profile.SecretNames, "plugin secret names"); err != nil {
		return err
	}
	if len(profile.SecretNames) != 0 {
		return invalidIsolation(
			profile.SecretNames[0], "plugin-wide secrets require operation-scoped authority",
		)
	}
	if err := validateUniqueStrings(profile.NetworkEndpoints, "plugin network endpoints"); err != nil {
		return err
	}
	if err := validateUniqueStrings(profile.LocalSocketPaths, "plugin local socket paths"); err != nil {
		return err
	}
	return nil
}

func isolatedEnvironment(profile IsolationProfile) ([]string, error) {
	if len(profile.SecretNames) != 0 {
		return nil, invalidIsolation(
			profile.SecretNames[0], "plugin-wide secrets require operation-scoped authority",
		)
	}
	values := map[string]string{
		"HOME": "/var/empty", "LANG": "C.UTF-8", "LC_ALL": "C.UTF-8",
		"COLCHIS_PLUGIN_ISOLATION": "confined",
	}
	if profile.DangerouslyAllowAll {
		values["COLCHIS_PLUGIN_ISOLATION"] = "dangerously-allow-all"
	}
	if profile.HomeDirectory != "" {
		values["HOME"] = profile.HomeDirectory
	}
	for key, value := range profile.Environment {
		if !validEnvironmentName(key) || reservedEnvironmentName(key) {
			return nil, invalidIsolation(key, "plugin environment name is invalid or reserved")
		}
		values[key] = value
	}
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	environment := make([]string, 0, len(keys))
	for _, key := range keys {
		environment = append(environment, key+"="+values[key])
	}
	return environment, nil
}

func validEnvironmentName(name string) bool {
	if name == "" {
		return false
	}
	for index, character := range name {
		if character >= 'A' && character <= 'Z' || character == '_' ||
			index > 0 && character >= '0' && character <= '9' {
			continue
		}
		return false
	}
	return true
}

func reservedEnvironmentName(name string) bool {
	upper := strings.ToUpper(name)
	for _, fragment := range []string{
		"HOME", "SSH_AUTH_SOCK", "GIT_ASKPASS", "GITHUB_TOKEN", "GH_TOKEN", "AWS_",
		"GOOGLE_APPLICATION_CREDENTIALS", "LD_", "DYLD_",
	} {
		if upper == fragment || strings.HasPrefix(upper, fragment) {
			return true
		}
	}
	return false
}

func prepareDarwinSandbox(profile IsolationProfile, environment []string) (LaunchPlan, error) {
	sandboxExecutable, err := exec.LookPath("sandbox-exec")
	if err != nil {
		return LaunchPlan{}, invalidIsolation("sandbox-exec", "Darwin sandbox backend is unavailable")
	}
	directory, err := os.MkdirTemp("", "colchis-plugin-sandbox-")
	if err != nil {
		return LaunchPlan{}, invalidIsolation("sandbox profile", err.Error())
	}
	cleanup := func() error { return os.RemoveAll(directory) }
	profilePath := filepath.Join(directory, "profile.sb")
	contents := darwinSandboxProfile(profile)
	if err := os.WriteFile(profilePath, []byte(contents), 0o600); err != nil {
		return LaunchPlan{}, errors.Join(invalidIsolation(profilePath, err.Error()), cleanup())
	}
	arguments := []string{"-f", profilePath, "--", profile.Executable}
	arguments = append(arguments, profile.Arguments...)
	return LaunchPlan{
		Executable: sandboxExecutable, Arguments: arguments,
		WorkingDirectory: profile.WorkingDirectory, Environment: environment, cleanup: cleanup,
	}, nil
}

func darwinSandboxProfile(profile IsolationProfile) string {
	lines := []string{
		"(version 1)", "(deny default)", "(allow process-exec)", "(allow process-fork)",
		"(deny process-info-setcontrol)",
		"(allow signal (target self))", "(allow sysctl-read)", "(allow mach-lookup)",
		"(allow file-read-metadata)",
		"(allow file-read-data (literal \"/\") (literal \"/dev/dtracehelper\") (literal \"/dev/null\"))",
		"(allow file-read-data (literal \"/dev/random\") (literal \"/dev/urandom\"))",
		"(allow file-write-data (literal \"/dev/null\"))",
		"(allow file-read* (subpath \"/usr\") (subpath \"/System\") (subpath \"/nix/store\"))",
		"(allow file-read* (subpath \"/private/var/db/timezone\"))",
	}
	readPaths := append([]string{profile.Executable}, profile.ReadPaths...)
	readPaths = append(readPaths, profile.WorkingDirectory)
	for _, path := range uniqueSortedPaths(readPaths) {
		lines = append(lines, fmt.Sprintf("(allow file-read* (subpath %q))", path))
	}
	for _, path := range uniqueSortedPaths(profile.WritePaths) {
		lines = append(lines, fmt.Sprintf("(allow file-write* (subpath %q))", path))
	}
	for _, endpoint := range profile.NetworkEndpoints {
		lines = append(lines, fmt.Sprintf("(allow network-outbound (remote tcp %q))", endpoint))
	}
	if len(profile.LocalSocketPaths) != 0 {
		lines = append(lines, "(allow system-socket (socket-domain AF_UNIX))")
	}
	for _, path := range uniqueSortedPaths(profile.LocalSocketPaths) {
		lines = append(lines, fmt.Sprintf(
			"(allow network-outbound (remote unix-socket (literal %q)))", path,
		))
	}
	return strings.Join(lines, "\n") + "\n"
}

func prepareLinuxSandbox(profile IsolationProfile, environment []string) (LaunchPlan, error) {
	if len(profile.NetworkEndpoints) != 0 {
		return LaunchPlan{}, invalidIsolation(
			"networkEndpoints", "Linux endpoint isolation requires a configured external backend",
		)
	}
	bubblewrap, err := exec.LookPath("bwrap")
	if err != nil {
		return LaunchPlan{}, invalidIsolation("bwrap", "Linux sandbox backend is unavailable")
	}
	arguments := []string{
		"--die-with-parent", "--new-session", "--unshare-all", "--proc", "/proc", "--dev", "/dev",
		"--tmpfs", "/tmp", "--ro-bind", "/nix/store", "/nix/store",
	}
	for _, path := range uniqueSortedPaths(profile.LocalSocketPaths) {
		arguments = append(arguments, "--ro-bind", path, path)
	}
	readPaths := append([]string{profile.Executable, profile.WorkingDirectory}, profile.ReadPaths...)
	for _, path := range uniqueSortedPaths(readPaths) {
		arguments = append(arguments, "--ro-bind", path, path)
	}
	for _, path := range uniqueSortedPaths(profile.WritePaths) {
		arguments = append(arguments, "--bind", path, path)
	}
	arguments = append(arguments, "--chdir", profile.WorkingDirectory, "--", profile.Executable)
	arguments = append(arguments, profile.Arguments...)
	return LaunchPlan{
		Executable: bubblewrap, Arguments: arguments,
		WorkingDirectory: profile.WorkingDirectory, Environment: environment,
	}, nil
}

func uniqueSortedPaths(paths []string) []string {
	seen := make(map[string]struct{}, len(paths))
	for _, path := range paths {
		seen[path] = struct{}{}
	}
	result := make([]string, 0, len(seen))
	for path := range seen {
		result = append(result, path)
	}
	sort.Strings(result)
	return result
}

func invalidIsolation(resource string, message string) error {
	return &domain.Error{
		Code: domain.ErrorCodeUnauthorized, Op: "prepare isolation", Resource: resource,
		Message: message,
	}
}
