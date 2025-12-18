#!/usr/bin/env nu

def main [session: string] {
    if ($session | is-empty) {
        print $"Usage: connect <session-name>"
        exit 1
    }

    nohup wezterm connect $session o> /dev/null e> /dev/null &
    exit 0
}
