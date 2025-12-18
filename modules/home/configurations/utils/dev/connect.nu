#!/usr/bin/env nu

def main [session: string] {
    if ($session | is-empty) {
        print $"Usage: connect <session-name>"
        exit 1
    }

    ^wezterm connect $session err> /dev/null out> /dev/null &
}
