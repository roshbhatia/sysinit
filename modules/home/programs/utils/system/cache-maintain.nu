#!/usr/bin/env nu

# Allocated bytes under a cache directory. `du -P` charges each inode once and does
# not follow links, so a symlinked cache cannot select data outside its own tree.
export def allocated-bytes [directory: path] {
    match ($directory | path type) {
        null => 0
        "dir" => {
            (
                ^du -s -k -P $directory
                | split row "\t"
                | first
                | into int
            ) * 1024
        }
        _ => { error make {msg: "cache path must be a directory, not a file or symlink"} }
    }
}

# Run the cache's native cleanup command with a three-minute limit.
def prune [policy: record] {
    let result = (
        with-env ($policy.env? | default {}) { ^timeout 180 ...$policy.command | complete }
    )
    if $result.exit_code != 0 {
        let output = $"($result.stdout)($result.stderr)" | str substring 0..4095 | str trim
        error make {msg: $"exit status ($result.exit_code): ($output)"}
    }
}

export def maintain [policy: record, apply: bool, run: closure] {
    let base = {
        name: ($policy.name? | default "")
        directory: ($policy.directory? | default "")
        max_bytes: ($policy.max_bytes? | default 0)
        before_bytes: 0
        after_bytes: 0
        status: "error"
    }
    let command = $policy.command? | default []
    let valid = ($base.name | is-not-empty) and ($base.directory | str starts-with "/") and $base.max_bytes > 0 and ($command | is-not-empty) and ($command | first | str starts-with "/")
    if not $valid {
        return ($base | insert error "invalid cache policy")
    }
    let before = (
        try { allocated-bytes $base.directory } catch {|error| return ($base | insert error $error.msg) }
    )
    let measured = $base | update before_bytes $before | update after_bytes $before
    if $before <= $base.max_bytes {
        return ($measured | update status "within-limit")
    }
    if not $apply {
        return ($measured | update status "would-prune")
    }
    let failure = (try {
        do $run $policy
        null
    } catch {|error|
        $error.msg
    })
    if $failure != null {
        let status = if $base.name == "uv" and ($failure | str contains "when waiting for lock") { "busy" } else { "error" }
        return ($measured | update status $status | insert error $failure)
    }
    let after = (
        try { allocated-bytes $base.directory } catch {|error| return ($measured | insert error $error.msg) }
    )
    $measured | update after_bytes $after | update status (if $after > $base.max_bytes { "retained-by-tool" } else { "pruned" })
}

# Measure managed caches against their limits; --apply runs each cache's own cleanup above its limit.
def main [--config: path, --apply, --report: path] {
    let policies = open --raw $config | from json
    let results = $policies | each {|policy| maintain $policy $apply {|p| prune $p } }
    let text = (
        {
            time: (
                date now
                | date to-timezone UTC
                | format date "%Y-%m-%dT%H:%M:%S%.fZ"
            )
            results: $results
        }
        | to json --indent 2
    )
    if $report != null {
        mkdir ($report | path dirname)
        chmod 700 ($report | path dirname)
        $text | save --force $"($report).tmp"
        chmod 600 $"($report).tmp"
        mv --force $"($report).tmp" $report
    }
    print $text
    if ($results | any {|result| $result.status == "error" }) {
        print -e "cache-maintain: cache maintenance failed; inspect the report"
        exit 1
    }
}
