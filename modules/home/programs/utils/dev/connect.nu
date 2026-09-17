#!/usr/bin/env nu

def main [session: string] {
    ^wezterm connect $session
    exit $env.LAST_EXIT_CODE
}
