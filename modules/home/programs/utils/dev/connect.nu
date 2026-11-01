#!/usr/bin/env nu

def main [session: string] {
    ^ssh -t $session tmux new-session -A -s main
    exit $env.LAST_EXIT_CODE
}
