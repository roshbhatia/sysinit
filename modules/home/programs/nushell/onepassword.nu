def account-args [account: string] {
    if ($account | is-empty) { [] } else { [--account $account] }
}

# Find item metadata without retrieving secret fields.
export def op-find [query: string = "", --vault: string = "", --account: string = ""] {
    let args = (account-args $account)
    let vault_args = if ($vault | is-empty) { [] } else { [--vault $vault] }
    let result = (^op item list --format json ...$args ...$vault_args | complete)
    if $result.exit_code != 0 { error make {msg: $result.stderr} }
    let needle = $query | str lowercase
    $result.stdout | from json | where {|item|
        ($item.title | str lowercase | str contains $needle) or $item.id == $query
    } | select id title vault category
}

def choose-item [query: string, vault: string, account: string] {
    let items = (op-find $query --vault $vault --account $account)
    if ($items | is-empty) { error make {msg: "No matching 1Password items"} }
    if ($items | length) == 1 { return ($items | first) }
    let selected = (
        $items
        | input list --fuzzy --display {|item| $"($item.title) [($item.vault.name)]"} "Choose a 1Password item:"
    )
    if $selected == null { error make {msg: "Canceled"} }
    $selected
}

# Return a stable reference for configuration files, without reading its value.
export def op-ref [
    query: string = ""
    --field: string = "password"
    --vault: string = ""
    --account: string = ""
] {
    let item = (choose-item $query $vault $account)
    $"op://($item.vault.id)/($item.id)/($field)"
}

# Copy a field or current OTP without printing it into terminal scrollback.
export def op-copy [
    query: string = ""
    --field: string = "password"
    --otp
    --vault: string = ""
    --account: string = ""
] {
    let clipboard = if (which pbcopy | is-not-empty) { [pbcopy] } else if (which wl-copy | is-not-empty) { [wl-copy --type text/plain] } else if (which xclip | is-not-empty) { [xclip -selection clipboard] } else { error make {msg: "Install pbcopy, wl-copy, or xclip to copy secrets"} }
    let field = if $otp { "one-time password?attribute=otp" } else { $field }
    let reference = (op-ref $query --field $field --vault $vault --account $account)
    let args = (account-args $account)
    let result = (^op read $reference --no-newline ...$args | complete)
    if $result.exit_code != 0 { error make {msg: "1Password could not read the selected field; check the field name and sign-in"} }
    let copied = $result.stdout | ^($clipboard | first) ...($clipboard | skip 1) | complete
    if $copied.exit_code != 0 { error make {msg: "Clipboard write failed"} }
    print "Copied to clipboard."
}

# Resolve secret references only for the child process; keep op's output masking.
export def --wrapped op-with [env_file: path, ...command: string] {
    if ($command | is-empty) { error make {msg: "Usage: op-with <env-file> <command> [args...]"} }
    ^op run --env-file $env_file -- ...$command
}
