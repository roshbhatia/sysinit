# Work with WezTerm pane and session records in Nushell. Subcommands match ty.
export def --wrapped nuwez [...arguments: string] {
    let args = if ($arguments | is-empty) { [panes] } else { $arguments }

    let result = $in | ^ty ...$args | complete

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default --empty "ty failed")
        }
    }

    if ($args | first 2) == [pane read] or $args in [
        [--help]
        [-h]
        [help]
    ] {
        return $result.stdout
    }

    $result.stdout | from json --strict
}
