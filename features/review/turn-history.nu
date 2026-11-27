const namespace = 'refs/worktree/sysinit/turn-reviews'
const retention = 30day

def metadata-directory [state: path, checkout: path] {
    $state | path join retention ($checkout | hash sha256)
}

export def retain-turn [
    state: path
    checkout: path
    before: string
    after: string
] {
    let turn = [$before $after] | str join ':' | hash sha256 | str substring 0..<16

    let ref = $'($namespace)/($turn)'

    let updated = $"update ($ref)/before ($before)\nupdate ($ref)/after ($after)\n" | ^git -C $checkout update-ref --stdin | complete

    if $updated.exit_code != 0 {
        error make {
            msg: ($updated.stderr | str trim)
        }
    }

    let metadata = metadata-directory $state $checkout

    mkdir $metadata

    (date now | format date '%+') | save --force ($metadata | path join $turn)

    $turn
}

export def read-turn [checkout: path, turn: string] {
    [before after] | each {|side|
        let resolved = ^git -C $checkout rev-parse --verify $'($namespace)/($turn)/($side)^{tree}' | complete

        if $resolved.exit_code != 0 {
            error make {msg: 'The recorded turn diff is unavailable.'}
        }

        $resolved.stdout | str trim
    }
}

export def prune-turns [state: path, checkout: path, --force] {
    let metadata = metadata-directory $state $checkout

    if not ($metadata | path exists) { return }

    let now = date now

    let stamp = $metadata | path join last-pruned

    let last_pruned = try {
        open --raw $stamp | into datetime
    }

    if not $force and $last_pruned != null and ($now - $last_pruned) < 1day { return }

    let cutoff = $now - $retention

    let expired = ls $metadata | where {|entry|
        if $entry.type != file or ($entry.name | path basename) !~ '^[0-9a-f]{16}$' { return false }

        let created = try { open --raw $entry.name | into datetime }
        $created != null and $created < $cutoff
    }

    if ($expired | is-not-empty) {
        let instructions = $expired | each {|entry|
            let ref = $'($namespace)/($entry.name | path basename)'
            $"delete ($ref)/before\ndelete ($ref)/after\n"
        } | str join

        let removed = $instructions | ^git -C $checkout update-ref --stdin | complete

        if $removed.exit_code != 0 {
            error make {
                msg: ($removed.stderr | str trim)
            }
        }

        rm --force ...$expired.name
    }

    ($now | format date '%+') | save --force $stamp
}
