#!/usr/bin/env nu

export def flush [os: string] {
    match $os {
        macos => {
            ^sudo dscacheutil -flushcache
            if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
            ^sudo killall -HUP mDNSResponder
            exit $env.LAST_EXIT_CODE
        }
        linux => {
            ^sudo resolvectl flush-caches
            exit $env.LAST_EXIT_CODE
        }
        _ => { error make {msg: $"Unsupported OS: ($os)"} }
    }
}

def main [] { flush $nu.os-info.name }
