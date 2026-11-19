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

def main [--cwd: path = '.', --lock-held] {
    let parent = $env.WEZTERM_PANE? | default ''

    if $parent !~ '^\d+$' { error make {msg: 'No WezTerm pane. Run agent-diff from a WezTerm session.'} }

    let git_root = run-command [git -C $cwd rev-parse --show-toplevel]

    if $git_root.exit_code != 0 { error make {msg: 'The current directory is not a Git worktree.'} }

    let root = $git_root.stdout | str trim | path expand

    if (wez list-clients --format json | from json --strict | is-empty) { error make {msg: 'No attached WezTerm client.'} }

    let panes = wez list --format json | from json --strict

    let owners = $panes | where {|pane| ($pane.pane_id | into string) == $parent}

    if ($owners | is-empty) { error make {msg: 'The invoking pane is no longer live.'} }

    let owner = $owners | first

    let state = ($env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)) | path join agent-diff

    mkdir $state

    let key = $'($root)|($parent)|($env.WEZTERM_UNIX_SOCKET? | default "")' | hash sha256 | str substring 0..19

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
        exec flock --exclusive ($state | path join $'($key).lock') $nu.current-exe --no-config-file $script --cwd $root --lock-held
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
            let refresh = rpc $socket "execute('checktime | Review refresh')"

            if $refresh.exit_code != 0 { error make {msg: 'The diff editor could not refresh yet. Run /diff again.'} }

            (wez
                activate-pane
                --pane-id
                ($live.0.pane_id | into string)
            ) | ignore

            print 'Reused the Neovim diff pane.'

            return
        }
    }

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
        HEAD
    ]

    let action = if $head.exit_code == 0 { 'DiffviewOpen HEAD' } else { 'DiffviewOpen' }

    let pane = (wez
        split-pane
        --pane-id
        $parent
        --right
        --percent
        45
        --cwd
        $root
        --
        nvim
        --listen
        $socket
        --cmd
        $"let g:harness_pane = '($parent)'"
        -c
        $action
    )

    {
        pane: ($pane | into int)
        root: $root
    } | to json | save --force $record

    let deadline = (date now) + 4sec

    while (date now) < $deadline {
        if ($socket | path exists) {
            let ready = rpc $socket "exists(':Review')"

            if $ready.exit_code == 0 and ($ready.stdout | str trim) == '2' {
                print 'Opened the Neovim diff pane.'

                return
            }
        }

        sleep 50ms
    }

    error make {msg: 'The split opened, but Neovim did not expose its socket yet. Run /diff again.'}
}
