package main

import "testing"

func TestEveryLinkNamesARegisteredCommand(t *testing.T) {
	for name, l := range links {
		if _, ok := commands[l.command]; !ok {
			t.Errorf("link %q runs %q, which is not a registered command", name, l.command)
		}
	}
}

// The overlay installs one wrapper per link, so a command reachable only by spelling a
// subcommand is one a hook cannot call without a shell.
func TestEveryCommandIsReachableByAName(t *testing.T) {
	reached := map[string]bool{}
	for _, l := range links {
		reached[l.command] = true
	}
	for name := range commands {
		if !reached[name] {
			t.Errorf("command %q has no installed name", name)
		}
	}
}
