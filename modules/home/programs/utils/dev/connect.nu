#!/usr/bin/env nu

# Connect to a Wezterm session
def main [
    session: string  # Session name to connect to
] {
    if ($session | is-empty) {
        print "Usage: connect <session-name>"
        exit 1
    }

    nohup wezterm connect $session out+err> /dev/null
}
