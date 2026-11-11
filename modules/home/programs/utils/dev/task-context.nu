#!/usr/bin/env nu

const schema = "task-context-backup/v1"
const uuid_pattern = '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'

def fail [message: string] {
    print -e $"task-context: ($message)"
    exit 1
}

def task-output [task: string, ...args: string] {
    let result = (
        ^$task rc.context:none rc.verbose:nothing rc.json.array:on ...$args
        | complete
    )
    if $result.exit_code != 0 {
        error make {
            msg: $"($task) exited ($result.exit_code): ($result.stderr | str trim)"
        }
    }
    $result.stdout
}

# Writes through a private temporary file in the same folder, so a reader never
# sees a partial snapshot.
def atomic-save [path: path, text: string] {
    let directory = $path | path dirname
    mkdir $directory
    chmod 700 $directory
    let staged = (mktemp --tmpdir-path $directory .task-context-XXXXXX)
    try {
        $text | save --force $staged
        mv --force $staged $path
    } catch {|error|
        rm --force $staged
        error make {msg: $error.msg}
    }
}

# Export every task and the active configuration, then keep the newest `keep` snapshots.
export def backup [task: string, directory: path, keep: int] {
    if $keep < 1 {
        error make {msg: "retention must be positive"}
    }
    let tasks = task-output $task export | from json
    let config = (task-output $task _show)
    let now = date now | date to-timezone UTC
    let snapshot = {
        schema: $schema
        created: ($now | format date "%Y-%m-%dT%H:%M:%SZ")
        config: $config
        tasks: $tasks
    }
    let name = (
        $directory
        | path join $"task-($now | format date '%Y%m%dT%H%M%S.%9fZ').json"
    )
    atomic-save $name ($snapshot | to json --raw)
    let files = glob ($directory | path join "task-*.json") | sort
    let excess = ($files | length) - $keep
    if $excess > 0 {
        for old in ($files | first $excess) {
            let recognized = (
                try { (open --raw $old | from json | get schema) == $schema } catch { false }
            )
            if not $recognized {
                error make {msg: "refusing to prune an unrecognized backup"}
            }
            rm $old
        }
    }
    $name
}

# Import a snapshot into a new, separate Taskwarrior data directory.
export def restore [task: string, source: path, destination: path] {
    let snapshot = open --raw $source | from json
    if ($snapshot.schema? | default "") != $schema or ($snapshot.tasks? | describe) !~ '^(list|table)' {
        error make {msg: "invalid backup"}
    }
    let target = $destination | path expand
    if ($target | path exists) {
        error make {msg: "restore requires a new directory"}
    }
    mkdir $target
    chmod 700 $target
    let rc = $target | path join "taskrc"
    let data = $target | path join "data"
    # Drop settings that point at the original data, hooks, sync server, or context.
    let settings = (
        $snapshot.config
        | lines
        | where {|line|
            let key = $line | split row "=" | first
            ($line | str contains "=") and not ($key | str starts-with "sync.") and not ($key | str starts-with "taskd.") and $key not-in ["data.location" "hooks.location" "context"]
        }
        | append [$"data.location=($data)" "hooks=off" "context=" "confirmation=off"]
    )
    $settings | str join "\n" | $in + "\n" | save $rc
    chmod 600 $rc
    with-env {TASKRC: $rc TASKDATA: $data} {
        $snapshot.tasks | to json --raw | ^$task $"rc:($rc)" rc.context:none rc.hooks:off rc.confirmation:off import -
    }
}

def open-attribute [
    task: string
    field: string
    uuid: string
    directory: bool
] {
    if $uuid !~ $uuid_pattern {
        fail "expected a task UUID"
    }
    let tasks = task-output $task $uuid export | from json
    if ($tasks | length) != 1 {
        fail "select exactly one task"
    }
    let value = $tasks.0 | get -o $field | default ""
    if ($value | describe) != "string" or ($value | is-empty) {
        fail $"task has no ($field)"
    }
    if $directory {
        if ($value | path type) != "dir" or not ($value | str starts-with "/") {
            fail "repository path must be an absolute directory"
        }
    } else {
        let parsed = (
            try {
                $value | url parse
            } catch {
                {scheme: "", host: ""}
            }
        )
        if $parsed.scheme not-in ["http" "https"] or ($parsed.host | is-empty) {
            fail "task URL must be HTTP or HTTPS"
        }
    }
    if $nu.os-info.name == "macos" { ^open $value } else { ^xdg-open $value }
}

# Back up, restore, or open Taskwarrior context: backup | restore SNAPSHOT NEW_DIRECTORY | repo [REPORT] | open-url UUID | open-repo UUID.
def main [
    command: string
    --task: string = "taskwarrior"
    --directory: string = ""
    --keep: int = 14
    --field: string = "url"
    ...args: string
] {
    match $command {
        "backup" => {
            if ($directory | is-empty) { fail "backup requires --directory" }
            try { print (backup $task $directory $keep) } catch {|error| fail $error.msg }
        }
        "restore" => {
            if ($args | length) != 2 { fail "restore requires SNAPSHOT NEW_DIRECTORY" }
            try { restore $task $args.0 $args.1 } catch {|error| fail $error.msg }
        }
        "open-url" | "open-repo" => {
            if ($args | length) != 1 { fail "open requires one UUID" }
            (open-attribute
                $task
                $field
                $args.0
                ($command == "open-repo")
            )
        }
        "repo" => {
            let root = (^git rev-parse --show-toplevel | str trim)
            ^$task rc.context:none $"repo:($root)" ($args | get -o 0 | default "focus")
        }
        _ => { fail "unknown task-context command" }
    }
}
