use ./wezterm-mux.nu wezterm-socket

const script = path self
const directory_notes = path self | path dirname | path join directory-notes.lua
const source_view = path self | path dirname | path join source-view.lua
const diffview_ready = 'luaeval("(function() local ok, lib = pcall(require, \x27diffview.lib\x27); local view = ok and lib.get_current_view(); return view and view.ready and 1 or 0 end)()")'

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

def panes [] {
    command-output [ty panes] | from json --strict | get panes
}

def restore-focus [previous: record, owner: record, review_pane: string] {
    let selected = panes | where {|item|
        $item.tab_id == $owner.tab_id and $item.is_active? == true
    } | get -o 0.pane_id

    if $selected == null or $selected == $previous.pane_id { return }

    if $selected == $owner.pane_id or ($selected | into string) == $review_pane {
        command-output [
            ty
            pane
            focus
            ($previous.pane_id | into string)
        ] | ignore
    }
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

def select-review [socket: path, refresh: bool] {
    let lua = 'dofile(_A.script).select_review(_A.refresh)'

    let args = {script: $source_view, refresh: $refresh} | to json --raw | str replace --all "'" "''"

    rpc $socket ("luaeval('" + $lua + "', json_decode('" + $args + "'))")
}

def jump-to-source [socket: path, position: record, review: bool] {
    let lua = 'dofile(_A.script).jump(_A.position, _A.review) and 1 or 0'

    let args = {script: $source_view, position: $position, review: $review} | to json --raw | str replace --all "'" "''"

    let expression = "luaeval('" + $lua + "', json_decode('" + $args + "'))"

    let result = rpc $socket $expression

    if $result.exit_code != 0 or ($result.stdout | str trim) != '1' {
        error make {msg: $"The review editor could not open ($position.file)."}
    }
}

def review-file [root: path, file: string] {
    let target = $root | path join $file | path expand --strict

    let relative = $target | path relative-to $root

    if ($relative | path split | get 0?) == '..' or ($target | path type) != file {
        error make {msg: $"Expected a file inside ($root): ($file)"}
    }

    $target
}

def resolve-target [options: record] {
    let git_root = if not $options.directory {
        run-command [git -C $options.cwd rev-parse --show-toplevel]
    }

    let directory_mode = $options.directory or (
        ($options.allow_directory or $options.file == null) and $options.base == null and $git_root.exit_code? != 0
    )

    if $options.against != null and $options.file == null { error make {msg: '--against also requires --file.'} }

    let root = if $directory_mode {
        let resolved = $options.cwd | path expand --strict

        if ($resolved | path type) != dir { error make {msg: 'Expected a directory.'} }

        $resolved
    } else {
        if $git_root.exit_code != 0 { error make {msg: 'The current directory is not a Git worktree.'} }

        $git_root.stdout | str trim | path expand
    }

    let target = if $options.file != null { review-file $root $options.file } else { $root }

    let pathspec = if $options.file != null and not $directory_mode {
        $target | path relative-to $root | prepend ':(top,literal)' | str join
    }

    let unchanged_file = if $pathspec != null and $options.allow_directory and $options.base == null {
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

    let review = if ($options.review or $options.file == null or $options.allow_directory) and not $directory and $options.base == null and $options.note_session == null {
        (run-command [
            git
            -C
            $root
            rev-parse
            --verify
            HEAD
        ]).exit_code == 0
    } else {
        false
    }

    if $options.note_session != null and ((not $directory and $options.base == null) or $options.note_session !~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$') {
        error make {
            msg: 'Review notes require a workspace UUID and Git review also requires an explicit base.'
        }
    }

    if $directory and $options.base != null { error make {msg: '--base requires Git review.'} }

    if ($directory and $options.note_session != null) != ($options.note_command != null) {
        error make {msg: 'Directory notes require both --note-session and --note-command.'}
    }

    if $options.against != null and not $directory { error make {msg: '--against requires directory review.'} }

    let baseline = if $options.against != null { review-file ($options.against | path expand --strict) $options.file }

    let position = if $options.file != null {
        {
            file: $target
            line: (if ($options.line | default 0) > 0 { $options.line })
            column: ([$options.column 1] | compact | math max)
        }
    }

    {
        root: $root
        target: $target
        pathspec: $pathspec
        directory: $directory
        review: $review
        baseline: $baseline
        position: $position
    }
}

def editor-command [
    target: record
    socket: path
    state_home: path
    revision: string
    note_session
    note_command
] {
    let nvim = [nvim --cmd 'let g:sysinit_pr_review = v:true' --listen $socket]

    if $target.review {
        [
            ...$nvim
            -c
            ('lua dofile(' + ($source_view | to json --raw) + ').open_review()')
        ]
    } else if $target.directory {
        let comparison = if $target.baseline == null {
            if $target.position == null {
                [
                    -c
                    "lua if vim.fn.exists(':Oil') == 2 then vim.cmd.Oil(vim.fn.getcwd()) end"
                    --
                    $target.target
                ]
            } else {
                [-- $target.target]
            }
        } else {
            [-d -- $target.baseline $target.target]
        }

        if $note_session == null {
            [...$nvim ...$comparison]
        } else {
            [
                env
                $"XDG_STATE_HOME=($state_home)"
                $"SYSINIT_REVIEW_NOTE_COMMAND=($note_command)"
                $"SYSINIT_REVIEW_NOTE_WORKSPACE=($note_session)"
                ...$nvim
                -S
                $directory_notes
                ...$comparison
            ]
        }
    } else {
        let head = run-command [
            git
            -C
            $target.root
            rev-parse
            --verify
            $revision
        ]

        let diff_args = (
            if $head.exit_code == 0 { [$revision] } else { [] }
        ) | append (if $target.pathspec != null { [-- $target.pathspec] } else { [] })

        let diff = if $target.pathspec == null {
            [
                -c
                ($diff_args | prepend DiffviewOpen | str join ' ')
            ]
        } else {
            [-S $source_view]
        }

        let source_env = if $target.pathspec != null {
            [$"SYSINIT_DIFFVIEW_ARGS=($diff_args | to json --raw)"]
        } else {
            []
        }

        if $note_session == null {
            if $target.pathspec == null {
                [...$nvim ...$diff]
            } else {
                [
                    env
                    ...$source_env
                    ...$nvim
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
                ...$nvim
                -c
                $configure
                ...$diff
            ]
        }
    }
}

def main [
    --cwd: path = '.'
    --pane-id: string
    --base: string
    --directory
    --allow-directory
    --review
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

    let request = resolve-target {
        cwd: $cwd
        directory: $directory
        allow_directory: $allow_directory
        base: $base
        review: $review
        file: $file
        line: $line
        column: $column
        against: $against
        note_session: $note_session
        note_command: $note_command
    }

    let root = $request.root

    let target = $request.target

    let directory = $request.directory

    let review = $request.review

    let baseline = $request.baseline

    let position = $request.position

    let connection = wezterm-socket

    if $connection != '' {
        $env.WEZTERM_UNIX_SOCKET = $connection
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

    let state = ($env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)) | path join agent-diff

    mkdir $state

    let key_parts = [
        $root
        $parent
        $connection
    ]

    let key_parts = if $review {
        $key_parts | append reviewr
    } else if $directory {
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
            | append (if $review { [--review] } else { [] })
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
            } else if $review {
                select-review $socket true
            } else {
                let visible = rpc $socket $diffview_ready

                if $visible.exit_code != 0 or ($visible.stdout | str trim) != '1' {
                    error make {msg: 'The diff editor has no active Diffview tab.'}
                }

                rpc $socket "execute('checktime | DiffviewRefresh')"
            }

            if $refresh.exit_code != 0 or ($review and $position == null and ($refresh.stdout | str trim) != '1') {
                error make {msg: 'The diff editor could not refresh yet. Run /diff again.'}
            }

            if $position != null { jump-to-source $socket $position $review }

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

    let editor = editor-command $request $socket $state_home $revision $note_session $note_command

    let pane = (command-output [
        ty
        pane
        spawn
        $parent
        --direction
        right
        --percent
        '45'
        --cwd
        $root
        --
        ...$editor
    ]) | from json --strict | get pane_id

    if not $background {
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
            } else if $review {
                select-review $socket false
            } else {
                rpc $socket $diffview_ready
            }

            let expected = if $directory { $root } else { '1' }

            if $ready.exit_code == 0 and ($ready.stdout | str trim) == $expected {
                if $background and $active != null { restore-focus $active $owner $pane }

                if $position != null { jump-to-source $socket $position $review }

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

    if $background and $active != null { restore-focus $active $owner $pane }

    error make {msg: 'The split opened, but Neovim did not expose its socket yet. Run /diff again.'}
}
