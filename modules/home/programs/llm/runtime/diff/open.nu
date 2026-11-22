const script = path self

def run-command [arguments: list<string>] {
    let program = $arguments | first

    ^timeout 8s $program ...($arguments | skip 1) | complete
}

def --wrapped wez [...arguments: string] {
    let result = run-command ([wezterm cli --no-auto-start] | append $arguments)

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default 'WezTerm command failed')
        }
    }

    $result.stdout | str trim
}

def rpc [socket: path, expression: string] {
    run-command [
        nvim
        --headless
        --clean
        --server
        $socket
        --remote-expr
        $expression
    ]
}

def main [
    --cwd: path = '.'
    --pane-id: string
    --base: string
    --note-session: string
    --background
    --if-open
    --json
    --lock-held
] {
    let parent = $pane_id | default ($env.WEZTERM_PANE? | default '')

    if $parent !~ '^\d+$' { error make {msg: 'No WezTerm pane. Run agent-diff from a WezTerm session.'} }

    if $note_session != null and ($base == null or $note_session !~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
        error make {msg: 'Diff notes require an explicit base and a workspace UUID.'}
    }

    let git_root = run-command [git -C $cwd rev-parse --show-toplevel]

    if $git_root.exit_code != 0 { error make {msg: 'The current directory is not a Git worktree.'} }

    let root = $git_root.stdout | str trim | path expand

    let clients = wez list-clients --format json | from json --strict

    if ($clients | is-empty) { error make {msg: 'No attached WezTerm client.'} }

    let revision = if $base == null {
        'HEAD'
    } else {
        let resolved = run-command [
            git
            -C
            $root
            rev-parse
            --verify
            --end-of-options
            $'($base)^{commit}'
        ]

        if $resolved.exit_code != 0 { error make {msg: 'The diff base is not a commit.'} }

        $resolved.stdout | str trim
    }

    let panes = wez list --format json | from json --strict

    let owners = $panes | where {|pane| ($pane.pane_id | into string) == $parent}

    if ($owners | is-empty) { error make {msg: 'The invoking pane is no longer live.'} }

    let owner = $owners | first

    let active = $panes | where {|pane|
        $pane.tab_id == $owner.tab_id and $pane.is_active? == true and $pane.is_floating? != true
    } | get 0?

    let anchor = if $background and $active != null {
        $active.pane_id | into string
    } else {
        $parent
    }

    let state = ($env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)) | path join agent-diff

    mkdir $state

    let key_parts = [
        $root
        $parent
        ($env.WEZTERM_UNIX_SOCKET? | default '')
    ]

    let key_parts = if $base == null {
        $key_parts
    } else {
        $key_parts | append [
            $revision
            ($note_session | default '')
        ]
    }

    let key = $key_parts | str join '|' | hash sha256 | str substring 0..19

    let record = $state | path join $'($key).json'

    # Keep the socket below the Unix-domain path limit, even with a long XDG path.
    let uid = ^id -u | str trim

    let socket_dir = '/tmp' | path join $'sysinit-diff-($uid)'

    if not ($socket_dir | path exists) {
        mkdir $socket_dir

        chmod 700 $socket_dir
    }

    let symlink = ^test -L $socket_dir | complete

    let ownership = ^stat -c '%u:%a' $socket_dir | complete

    if $symlink.exit_code == 0 or $ownership.exit_code != 0 or ($ownership.stdout | str trim) !~ $'^($uid):[0-7]?00$' {
        error make {msg: 'The diff socket directory is not private.'}
    }

    let socket = $socket_dir | path join $'($key).sock'

    if not $lock_held {
        let args = (
            [--cwd $root --pane-id $parent --lock-held]
            | append (if $base != null { [--base $revision] } else { [] })
            | append (if $note_session != null { [--note-session $note_session] } else { [] })
            | append (if $background { [--background] } else { [] })
            | append (if $if_open { [--if-open] } else { [] })
            | append (if $json { [--json] } else { [] })
        )

        exec flock --exclusive ($state | path join $'($key).lock') $nu.current-exe --no-config-file $script ...$args
    }

    let saved = try {
        open --raw $record | from json --strict
    } catch {
        {}
    }

    let live = wez list --format json | from json --strict | where {|pane| $pane.pane_id == $saved.pane? and $pane.tab_id == $owner.tab_id}

    if ($live | is-not-empty) and ($socket | path exists) {
        let probe = rpc $socket 'getcwd()'

        if $probe.exit_code == 0 and ($probe.stdout | str trim | path expand) == $root {
            let refresh = rpc $socket "execute('checktime | DiffviewRefresh')"

            if $refresh.exit_code != 0 { error make {msg: 'The diff editor could not refresh yet. Run /diff again.'} }

            if not $background {
                wez activate-pane --pane-id ($live.0.pane_id | into string) | ignore
            }

            if $json {
                {pane_id: $live.0.pane_id, socket: $socket, reused: true} | to json --raw | print
            } else {
                print 'Reused the Neovim diff pane.'
            }

            return
        }
    }

    if $if_open { return }

    if ($socket | path exists) {
        if (rpc $socket 'getpid()').exit_code == 0 {
            error make {msg: 'A live diff editor exists outside this tab; close it before opening another.'}
        }

        rm $socket
    }

    let head = run-command [
        git
        -C
        $root
        rev-parse
        --verify
        $revision
    ]

    let action = if $head.exit_code == 0 { $"DiffviewOpen ($revision)" } else { 'DiffviewOpen' }

    let editor = if $note_session == null {
        [nvim --listen $socket -c $action]
    } else {
        let state_home = $state | path dirname

        let provider_directory = $env.CHANGES_PROVIDERS_DIRECTORY?

        let variables = [$"XDG_STATE_HOME=($state_home)"]
        | append (
            if $provider_directory != null { [$"CHANGES_PROVIDERS_DIRECTORY=($provider_directory)"] } else { [] }
        )

        let options = {provider: 'local-notes', from: $revision, session: $note_session} | to json --raw | to json --raw

        let configure = 'lua require("changes.notes").setup(vim.json.decode(' + $options + '))'

        [
            env
            ...$variables
            nvim
            --listen
            $socket
            -c
            $configure
            -c
            $action
        ]
    }

    let pane = (wez
        split-pane
        --pane-id
        $anchor
        --right
        --percent
        45
        --cwd
        $root
        --
        ...$editor
    )

    if $background and $active != null {
        let selection = wez list --format json | from json --strict | where {|item|
            $item.tab_id == $owner.tab_id and $item.is_active? == true
        } | get 0?

        if $selection != null and ($selection.pane_id | into string) == $pane and (wez get-pane-direction --pane-id $pane Left) == $anchor {
            wez activate-pane-direction --pane-id $pane Left | ignore
        }
    } else if not $background {
        wez activate-pane --pane-id $pane | ignore
    }

    {
        pane: ($pane | into int)
        root: $root
    } | to json | save --force $record

    let deadline = (date now) + 4sec

    while (date now) < $deadline {
        if ($socket | path exists) {
            let ready = rpc $socket "exists(':DiffviewRefresh')"

            if $ready.exit_code == 0 and ($ready.stdout | str trim) == '2' {
                if $json {
                    {
                        pane_id: ($pane | into int)
                        socket: $socket
                        reused: false
                    } | to json --raw | print
                } else {
                    print 'Opened the Neovim diff pane.'
                }

                return
            }
        }

        sleep 50ms
    }

    error make {msg: 'The split opened, but Neovim did not expose its socket yet. Run /diff again.'}
}
