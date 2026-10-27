def attribution-json [arguments: list<string>] {
    let result = (^git-ai ...$arguments | complete)
    if $result.exit_code != 0 { error make {msg: $"git-ai failed: ($result.stderr | str trim)"} }
    $result.stdout | from json
}

# Inspect the current repository's daemon, Trace2 target, and working attribution.
export def "attribution status" [] {
    let root = (^git rev-parse --show-toplevel | complete)
    if $root.exit_code != 0 {
        error make {
            msg: ($root.stderr | str trim)
        }
    }
    let trace = (^git config --get trace2.eventTarget | complete)
    let daemon = attribution-json [
        bg
        status
        --repo
        ($root.stdout | str trim)
    ]
    if not $daemon.ok {
        error make {
            msg: ($daemon.error? | default "Git AI daemon is unavailable")
        }
    }
    {
        repository: ($root.stdout | str trim)
        trace2: ($trace.stdout | str trim)
        repository_status: $daemon.data
        daemon: $daemon.daemon
        working: (attribution-json [status --json --diff-only])
    }
}

# Read line attribution totals for one commit.
export def "attribution stats" [revision: string = HEAD] {
    attribution-json [stats $revision --json]
}

# Inspect the duplicated-event retention policy without changing its database.
export def "attribution storage" [] {
    let result = (^git-ai-maintain | complete)
    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim)
        }
    }
    $result.stdout | from json
}

# Read attributed changes for a commit or revision range.
export def "attribution diff" [revision: string = HEAD] {
    attribution-json [diff $revision --json]
}

# Read attribution through Changes, preserving its review notes.
export def "attribution notes" [--commit: string, --staged] {
    if $staged and $commit != null { error make {msg: "choose --staged or --commit"} }
    let target = if $commit != null { [--commit $commit] } else if $staged { [--staged] } else { [] }
    let result = (^changes note list --provider git-ai --json ...$target | complete)
    if $result.exit_code != 0 { error make {msg: $"changes failed: ($result.stderr | str trim)"} }
    $result.stdout | from json | get notes
}

# Find originating session IDs for use with traces --all --session <id>.
export def "attribution sessions" [--commit: string, --staged] {
    attribution notes --commit $commit --staged=$staged
    | get -o session
    | default []
    | compact
    | uniq
}
