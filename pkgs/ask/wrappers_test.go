package main

import (
	"os"
	"slices"
	"strings"
	"testing"

	"github.com/roshbhatia/sysinit/pkgs/ask/internal/provider"
)

// wanted derives the wrapper names from the provider registry: the bare pair
// that runs whichever agent the settings or $ASK_PROVIDER name, then a pair per
// provider short name.
func wanted() []string {
	names := []string{"_", "_j"}
	for _, one := range provider.Known() {
		names = append(names, "_"+one.Short, "_"+one.Short+"j")
	}
	slices.Sort(names)
	return names
}

func listed(t *testing.T) []string {
	t.Helper()
	raw, err := os.ReadFile("wrappers.txt")
	if err != nil {
		t.Fatalf("read wrappers.txt: %v", err)
	}
	names := []string{}
	for _, line := range strings.Split(string(raw), "\n") {
		if trimmed := strings.TrimSpace(line); trimmed != "" {
			names = append(names, trimmed)
		}
	}
	slices.Sort(names)
	return names
}

// overlays/ask.nix symlinks one name per line of wrappers.txt, and nothing else
// checks that list against the providers the binary actually dispatches on. Add
// a provider without editing the file and its `_xxx` wrapper is never created,
// which presents as "command not found" rather than as a missing provider.
func TestWrappersCoverEveryProvider(t *testing.T) {
	want, got := wanted(), listed(t)
	if !slices.Equal(want, got) {
		t.Errorf("wrappers.txt is out of step with the provider registry\n want: %v\n  got: %v", want, got)
	}
}

// Every name the overlay symlinks has to be one the binary answers to, or the
// wrapper runs and then reports that it cannot tell which agent to use.
func TestEveryWrapperResolves(t *testing.T) {
	for _, name := range listed(t) {
		short, _, known := wrapper(name)
		if !known {
			t.Errorf("%s: the binary does not recognise this name", name)
			continue
		}
		if short == "" {
			continue
		}
		if _, found := provider.Lookup(short); !found {
			t.Errorf("%s: resolves to unknown provider %q", name, short)
		}
	}
}
