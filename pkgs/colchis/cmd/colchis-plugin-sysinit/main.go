package main

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"path/filepath"
	"syscall"

	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/activity"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/ask"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/nix"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/note"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/openspec"
	piadapter "github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/pi"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/adapter/seshy"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/domain"
	"github.com/roshbhatia/sysinit/pkgs/colchis/internal/plugin"
)

const maxAdapterOutputBytes uint64 = 64 << 20

func main() {
	if err := run(); err != nil {
		_, _ = fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	directory, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("get plugin working directory: %w", err)
	}
	runtimeDirectory, err := prepareRuntimeDirectory()
	if err != nil {
		return err
	}
	multiplexer, piAdapter, err := newMultiplexer(directory, runtimeDirectory)
	if err != nil {
		return err
	}
	if piAdapter != nil {
		defer piAdapter.Close()
	}
	server, err := plugin.NewServer(plugin.ServerConfig{
		PluginID: "sysinit", Adapters: multiplexer.Manifests(),
		Invoke: multiplexer.Invoke, Reconcile: multiplexer.Reconcile,
	})
	if err != nil {
		return fmt.Errorf("create sysinit plugin server: %w", err)
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()
	if err := server.Serve(ctx, os.Stdin, os.Stdout); err != nil {
		return fmt.Errorf("serve sysinit plugin: %w", err)
	}
	return nil
}

func newMultiplexer(
	directory string,
	runtimeDirectory string,
) (*plugin.Multiplexer, *piadapter.Adapter, error) {
	registrations := make([]plugin.AdapterRegistration, 0)
	if executableAvailable("openspec") {
		runner, err := openspec.NewCLIRunner("", directory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		adapter, err := openspec.New(runner)
		if err != nil {
			return nil, nil, err
		}
		manifest, err := openspec.Manifest()
		if err != nil {
			return nil, nil, err
		}
		registrations = append(registrations, plugin.AdapterRegistration{
			Manifest: manifest,
			Invoke: func(ctx context.Context, envelope plugin.OperationEnvelope, _ plugin.EventEmitter) (plugin.OperationResult, error) {
				output, invokeErr := adapter.Invoke(ctx, envelope.Operation, envelope.Input)
				return plugin.OperationResult{ID: envelope.ID, State: domain.OperationStateSucceeded, Output: output}, invokeErr
			},
		})
	}
	if executableAvailable("sy") {
		adapter, err := seshy.NewLocal(directory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		manifests, err := seshy.Manifests()
		if err != nil {
			return nil, nil, err
		}
		for _, manifest := range manifests {
			registration := plugin.AdapterRegistration{Manifest: manifest, Invoke: adapter.Invoke}
			if manifest.ID == seshy.WorkspaceAdapterID {
				registration.Reconcile = adapter.Reconcile
			}
			registrations = append(registrations, registration)
		}
	}
	if executableAvailable("nix") {
		adapter, err := nix.NewLocal(directory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		manifest, err := nix.Manifest()
		if err != nil {
			return nil, nil, err
		}
		registrations = append(registrations, plugin.AdapterRegistration{
			Manifest: manifest, Invoke: adapter.Invoke, Reconcile: adapter.Reconcile,
		})
	}
	if executableAvailable("ask") {
		adapter, err := ask.NewLocal(directory, runtimeDirectory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		manifest, err := ask.Manifest()
		if err != nil {
			return nil, nil, err
		}
		registrations = append(registrations, plugin.AdapterRegistration{
			Manifest: manifest, Invoke: adapter.Invoke, Reconcile: adapter.Reconcile,
		})
	}
	if executableAvailable("traces") && executableAvailable("agent-edit-event") {
		adapter, err := activity.NewLocal(directory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		manifest, err := activity.Manifest()
		if err != nil {
			return nil, nil, err
		}
		registrations = append(registrations, plugin.AdapterRegistration{Manifest: manifest, Invoke: adapter.Invoke})
	}
	if executableAvailable("utils") {
		adapter, err := note.NewLocal(directory, maxAdapterOutputBytes)
		if err != nil {
			return nil, nil, err
		}
		manifest, err := note.Manifest()
		if err != nil {
			return nil, nil, err
		}
		registrations = append(registrations, plugin.AdapterRegistration{Manifest: manifest, Invoke: adapter.Invoke})
	}
	var piAdapter *piadapter.Adapter
	if executableAvailable("pi") {
		piSessionDirectory := filepath.Join(runtimeDirectory, "pi-sessions")
		if err := os.MkdirAll(piSessionDirectory, 0o700); err != nil {
			return nil, nil, fmt.Errorf("create Pi session directory: %w", err)
		}
		var err error
		piAdapter, err = piadapter.NewLocal(
			directory, piSessionDirectory, os.Getenv("COLCHIS_PI_OFFLINE") == "1", maxAdapterOutputBytes,
		)
		if err != nil {
			return nil, nil, err
		}
		manifests, err := piadapter.Manifests()
		if err != nil {
			_ = piAdapter.Close()
			return nil, nil, err
		}
		for _, manifest := range manifests {
			registration := plugin.AdapterRegistration{Manifest: manifest, Invoke: piAdapter.Invoke}
			if manifest.ID == piadapter.RuntimeAdapterID {
				registration.Reconcile = piAdapter.Reconcile
			}
			registrations = append(registrations, registration)
		}
	}
	if len(registrations) == 0 {
		return nil, nil, fmt.Errorf("no sysinit adapter dependencies are available")
	}
	multiplexer, err := plugin.NewMultiplexer(registrations)
	if err != nil {
		_ = piAdapter.Close()
		return nil, nil, err
	}
	return multiplexer, piAdapter, nil
}

func executableAvailable(name string) bool {
	_, err := exec.LookPath(name)
	return err == nil
}

func prepareRuntimeDirectory() (string, error) {
	configured := os.Getenv("COLCHIS_RUNTIME_DIRECTORY")
	if configured == "" {
		cacheDirectory, err := os.UserCacheDir()
		if err != nil {
			return "", fmt.Errorf("resolve user cache directory: %w", err)
		}
		configured = filepath.Join(cacheDirectory, "colchis", "runtime")
	}
	absolute, err := filepath.Abs(configured)
	if err != nil {
		return "", fmt.Errorf("resolve configured runtime directory: %w", err)
	}
	if err := os.MkdirAll(absolute, 0o700); err != nil {
		return "", fmt.Errorf("create plugin runtime directory: %w", err)
	}
	return absolute, nil
}
