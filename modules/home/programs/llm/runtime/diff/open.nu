const script = path self
const directory_notes = path self | path dirname | path join directory-notes.lua
const source_view = path self | path dirname | path join source-view.lua

def run-command [arguments: list<string>] {
    let program = $arguments | first

    ^timeout 8s $program ...($arguments | skip 1) | complete
}

def command-output [arguments: list<string>] {
    let result = run-command $arguments

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default 'WezTerm command failed')
        }
    }

    $result.stdout | str trim
}

def --wrapped wez [...arguments: string] {
    command-output ([wezterm cli --no-auto-start] | append $arguments)
}

def panes [] {
    command-output [ty panes] | from json --strict | get panes
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

def jump-to-source [socket: path, position: record] {
    let lua = 'dofile(_A.script).jump(_A.position)'

    let args = {script: $source_view, position: $position} | to json --raw | str replace --all "'" "''"

    let expression = "luaeval('" + $lua + "', json_decode('" + $args + "'))"

    rpc $socket $expression | ignore
}

def review-file [root: path, file: string] {
    let target = $root | path join $file | path expand --strict

    let relative = $target | path relative-to $root

    if ($relative | path split | get 0?) == '..' or ($target | path type) != file {
        error make {msg: $"Expected a file inside ($root): ($file)"}
    }

    $target
}

def main [
    --cwd: path = '.'
    --pane-id: string
    --base: string
    --directory
    --allow-directory
    --file: string
    --line: int
    --column: int
    --against: path
    --note-session: string
    --note-command: path
    --background
    --if-open
    --json
    --lock-held
] {
    let parent = $pane_id | default ($env.WEZTERM_PANE? | default '')

    if $parent !~ '^\d+$' { error make {msg: 'No WezTerm pane. Run agent-diff from a WezTerm session.'} }

    let git_root = if not $directory {
        run-command [git -C $cwd rev-parse --show-toplevel]
    }

    let directory_mode = $directory or ($allow_directory and $base == null and $git_root.exit_code? != 0)

    if $against != null and $file == null { error make {msg: '--against also requires --file.'} }

    let root = if $directory_mode {
        let resolved = $cwd | path expand --strict

        if ($resolved | path type) != dir { error make {msg: 'Expected a directory.'} }

        $resolved
    } else {
        if $git_root.exit_code != 0 { error make {msg: 'The current directory is not a Git worktree.'} }

        $git_root.stdout | str trim | path expand
    }

    let target = if $file != null { review-file $root $file } else { $root }

    let pathspec = if $file != null and not $directory_mode {
        $target | path relative-to $root | prepend ':(top,literal)' | str join
    }

    let unchanged_file = if $pathspec != null and $allow_directory and $base == null {
        let status = run-command [
            git
            -C
            $root
            status
            --porcelain
            --untracked-files=all
            --
            $pathspec
        ]

        $status.exit_code == 0 and ($status.stdout | is-empty)
    } else {
        false
    }

    let directory = $directory_mode or $unchanged_file

    if $note_session != null and ((not $directory and $base == null) or $note_session !~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
        error make {
            msg: 'Review notes require a workspace UUID and Git review also requires an explicit base.'
        }
    }

    if $directory and $base != null { error make {msg: '--base requires Git review.'} }

    if ($directory and $note_session != null) != ($note_command != null) {
        error make {msg: 'Directory notes require both --note-session and --note-command.'}
    }

    if $against != null and not $directory { error make {msg: '--against requires directory review.'} }

    let baseline = if $against != null { review-file ($against | path expand --strict) $file }

    let position = if $file != null and ($line | default 0) > 0 {
        {
            file: $target
            line: $line
            column: ([$column 1] | compact | math max)
        }
    }

    let clients = command-output [ty clients] | from json --strict | get clients

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

    let panes = panes

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

    let key_parts = if $directory {
        $key_parts | append [
            directory
            $target
            ($baseline | default '')
            ($note_session | default '')
        ]
    } else if $base == null {
        $key_parts | append (if $file != null { [$target] } else { [] })
    } else {
        $key_parts | append [
            $revision
            ($note_session | default '')
        ] | append (if $file != null { [$target] } else { [] })
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
            | append (if $directory { [--directory] } else { [] })
            | append (if $file != null { [$"--file=($target)"] } else { [] })
            | append (if $line != null { [--line ($line | into string)] } else { [] })
            | append (if $column != null { [--column ($column | into string)] } else { [] })
            | append (if $against != null { [--against ($against | path expand --strict)] } else { [] })
            | append (if $note_session != null { [--note-session $note_session] } else { [] })
            | append (if $note_command != null { [--note-command ($note_command | path expand --strict)] } else { [] })
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

    let live = panes | where {|pane| $pane.pane_id == $saved.pane? and $pane.tab_id == $owner.tab_id}

    if ($live | is-not-empty) and ($socket | path exists) {
        let probe = rpc $socket 'getcwd()'

        if $probe.exit_code == 0 and ($probe.stdout | str trim | path expand) == $root {
            let refresh = if $directory {
                rpc $socket "execute('checktime | redraw')"
            } else {
                rpc $socket "execute('checktime | DiffviewRefresh')"
            }

            if $refresh.exit_code != 0 { error make {msg: 'The diff editor could not refresh yet. Run /diff again.'} }

            if $position != null { jump-to-source $socket $position }

            if not $background {
                command-output [
                    ty
                    pane
                    focus
                    ($live.0.pane_id | into string)
                ] | ignore
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

    let state_home = $state | path dirname

    let editor = if $directory {
        let comparison = if $baseline == null {
            [-- $target]
        } else {
            [-d -- $baseline $target]
        }

        if $note_session == null {
            [nvim --listen $socket ...$comparison]
        } else {
            [
                env
                $"XDG_STATE_HOME=($state_home)"
                $"SYSINIT_REVIEW_NOTE_COMMAND=($note_command)"
                $"SYSINIT_REVIEW_NOTE_WORKSPACE=($note_session)"
                nvim
                --listen
                $socket
                -S
                $directory_notes
                ...$comparison
            ]
        }
    } else {
        let head = run-command [
            git
            -C
            $root
            rev-parse
            --verify
            $revision
        ]

        let diff_args = (
            if $head.exit_code == 0 { [$revision] } else { [] }
        ) | append (if $pathspec != null { [-- $pathspec] } else { [] })

        let diff = if $pathspec == null {
            [
                -c
                ($diff_args | prepend DiffviewOpen | str join ' ')
            ]
        } else {
            [-S $source_view]
        }

        let source_env = if $pathspec != null {
            [$"SYSINIT_DIFFVIEW_ARGS=($diff_args | to json --raw)"]
        } else {
            []
        }

        if $note_session == null {
            if $pathspec == null {
                [nvim --listen $socket ...$diff]
            } else {
                [
                    env
                    ...$source_env
                    nvim
                    --listen
                    $socket
                    ...$diff
                ]
            }
        } else {
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
                ...$source_env
                nvim
                --listen
                $socket
                -c
                $configure
                ...$diff
            ]
        }
    }

    let pane = (command-output [
        ty
        pane
        spawn
        $anchor
        --direction
        right
        --percent
        '45'
        --cwd
        $root
        --
        ...$editor
    ]) | from json --strict | get pane_id

    if $background and $active != null {
        let selection = panes | where {|item|
            $item.tab_id == $owner.tab_id and $item.is_active? == true
        } | get 0?

        if $selection != null and ($selection.pane_id | into string) == $pane and (wez get-pane-direction --pane-id $pane Left) == $anchor {
            command-output [ty pane focus $anchor] | ignore
        }
    } else if not $background {
        command-output [ty pane focus $pane] | ignore
    }

    {
        pane: ($pane | into int)
        root: $root
    } | to json | save --force $record

    let deadline = (date now) + 4sec

    while (date now) < $deadline {
        if ($socket | path exists) {
            let ready = if $directory {
                rpc $socket 'getcwd()'
            } else {
                rpc $socket "exists(':DiffviewRefresh')"
            }

            let expected = if $directory { $root } else { '2' }

            if $ready.exit_code == 0 and ($ready.stdout | str trim) == $expected {
                if $position != null { jump-to-source $socket $position }

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
