const client = path self | path dirname | path join codex.ts

def --wrapped checked [program: string, ...args: string] {
    let result = $in | ^$program ...$args | complete

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default --empty $"($program) failed")
        }
    }

    $result.stdout
}

def state-dir [] {
    ($env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)) | path join agent-workspace
}

def record-path [id: string] {
    if $id !~ '^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$' {
        error make {msg: 'Expected an agent workspace UUID.'}
    }

    state-dir | path join $id
}

def load-workspace [id: string] {
    let directory = record-path $id

    let workspace = open --raw ($directory | path join workspace.json) | from json --strict

    let binding = $directory | path join thread.json

    if $workspace.codex != null and ($binding | path exists) {
        $workspace | update codex {|record|
            $record.codex | merge (open --raw $binding | from json --strict)
        }
    } else {
        $workspace
    }
}

def save-workspace [workspace: record] {
    let directory = record-path $workspace.id

    let temporary = mktemp --tmpdir-path $directory

    $workspace | to json --raw | save --force $temporary

    mv --force $temporary ($directory | path join workspace.json)
}

def --wrapped mux [...args: string] {
    checked wezterm cli --no-auto-start ...$args | str trim
}

def panes [] {
    mux list --format json | from json --strict
}

def canonical [directory: path] {
    checked git -C $directory rev-parse --show-toplevel | str trim
}

def find-root [session, cwd] {
    if $session == null { return (canonical ($cwd | default $env.PWD)) }

    let selected = checked sy status $session --format json | from json --strict

    let repos = $selected.repos | each {|repo| $repo.path }

    if $cwd == null and ($repos | length) != 1 {
        error make {msg: 'Select a repository in the seshy session with --cwd.'}
    }

    let root = canonical (
        if $cwd == null {
            $repos | first
        } else {
            $cwd
        }
    )

    if not ($repos | any {|repo| (canonical $repo) == $root }) {
        error make {msg: 'The worktree is outside the selected seshy session.'}
    }

    $root
}

def socket-path [socket] {
    let codex_home = $env.CODEX_HOME? | default ($env.HOME | path join .codex)

    $socket | default ($codex_home | path join app-server-control app-server-control.sock) | path expand --no-symlink
}

def ensure-client [] {
    if (mux list-clients --format json | from json --strict | is-empty) {
        error make {msg: 'No attached WezTerm client.'}
    }
}

def spawn-agent [workspace: record, parent] {
    let target = $parent | default $env.WEZTERM_PANE?

    let args = if $target == null {
        []
    } else {
        [
            --pane-id
            ($target | into string)
        ]
    }

    let command = if $workspace.codex == null {
        $workspace.argv
    } else {
        let state_home = state-dir | path dirname

        [
            env
            $"XDG_STATE_HOME=($state_home)"
            ($env.SYSINIT_AGENT_WORKSPACE_BIN | path expand)
            run
            $workspace.id
        ]
    }

    let pane_id = mux spawn ...$args --cwd $workspace.root -- ...$command | into int

    let pane = panes | where pane_id == $pane_id | first

    let updated = $workspace | merge {pane_id: $pane_id, tab_id: $pane.tab_id}

    save-workspace $updated

    $updated
}

def "main open" [
    --session: string
    --cwd: path
    --task: string
    --pane-id: int
    --base: string = HEAD
    --thread: string
    --socket: path
    ...command: string
] {
    ensure-client

    let root = find-root $session $cwd

    let revision = checked git -C $root rev-parse --verify --end-of-options $'($base)^{commit}' | str trim

    let codex = if ($command | is-empty) {
        let endpoint = socket-path $socket

        let thread_id = checked bun $client bind $endpoint $root ($thread | default '') | from json --strict | get thread_id

        {socket: $endpoint, thread_id: $thread_id}
    } else {
        if $thread != null or $socket != null {
            error make {msg: 'Use --thread or --socket with the default Codex launcher.'}
        }

        null
    }

    let workspace = {
        version: 'sysinit.agent-workspace/v1'
        id: (random uuid)
        root: $root
        base: $revision
        session: $session
        task: $task
        mux: $env.WEZTERM_UNIX_SOCKET?
        pane_id: null
        tab_id: null
        argv: $command
        codex: $codex
    }

    let directory = record-path $workspace.id

    mkdir $directory

    chmod 700 $directory

    save-workspace $workspace

    spawn-agent $workspace $pane_id | to json --raw
}

def "main show" [id: string] {
    let active = record-path $id | path join active-turn.json

    let turn_id = try {
        open --raw $active | from json --strict | get turn_id
    }

    load-workspace $id | merge {active_turn_id: $turn_id} | to json --raw
}

def with-mux [workspace: record, action: closure] {
    with-env {WEZTERM_UNIX_SOCKET: $workspace.mux} { do $action }
}

def "main resume" [id: string, --pane-id: int] {
    let workspace = load-workspace $id

    with-mux $workspace {||
        ensure-client

        if (panes | any {|pane| $pane.pane_id == $workspace.pane_id and $pane.tab_id == $workspace.tab_id }) {
            mux activate-pane --pane-id ($workspace.pane_id | into string) | ignore

            $workspace | to json --raw
        } else if $workspace.codex != null {
            (checked
                bun
                $client
                bind
                $workspace.codex.socket
                $workspace.root
                ($workspace.codex.thread_id | default '')
            ) | ignore

            spawn-agent $workspace $pane_id | to json --raw
        } else {
            error make {msg: 'The original pane closed. Relaunch the command using its own resume interface.'}
        }
    }
}

def "main refresh" [id: string, --focus] {
    let workspace = load-workspace $id

    let status = checked git -C $workspace.root status --porcelain

    let commits = checked git -C $workspace.root diff --name-only $workspace.base HEAD

    with-mux $workspace {||
        if not (panes | any {|pane| $pane.pane_id == $workspace.pane_id and $pane.tab_id == $workspace.tab_id }) {
            error make {msg: 'The agent pane is no longer in its recorded tab.'}
        }

        let flags = if $focus {
            []
        } else if ($status | is-empty) and ($commits | is-empty) {
            [--background --if-open]
        } else {
            [--background]
        }

        (checked
            agent-diff
            --cwd
            $workspace.root
            --pane-id
            ($workspace.pane_id | into string)
            --base
            $workspace.base
            --note-session
            $id
            --json
            ...$flags
        ) | str trim
    }
}

def "main run" [id: string] {
    let workspace = load-workspace $id

    if $workspace.codex == null { error make {msg: 'This workspace does not use the Codex adapter.'} }

    ^bun $client run $workspace.codex.socket $workspace.root ($workspace.codex.thread_id | default '') (record-path $id) $env.SYSINIT_AGENT_WORKSPACE_BIN $id
}

def "main last-turn" [id: string, --patch] {
    let turn = open --raw (record-path $id | path join last-turn.json) | from json --strict

    if $patch {
        $turn.diff
    } else {
        $turn | to json --raw
    }
}

def "main note" [
    id: string
    file: string
    line: int
    message: string
    --start-line: int
    --side: string = right
] {
    let workspace = load-workspace $id

    cd $workspace.root

    let range = if $start_line == null {
        []
    } else {
        [
            -start-line
            ($start_line | into string)
        ]
    }

    (checked
        changes
        note
        add
        -provider
        local-notes
        -from
        $workspace.base
        -session
        $id
        -file
        $file
        -line
        ($line | into string)
        -side
        $side
        -message
        $message
        -json
        ...$range
    ) | str trim
}

def "main feedback" [id: string, --send, --steer: string] {
    let workspace = load-workspace $id

    if $steer != null and not $send { error make {msg: '--steer requires --send.'} }

    cd $workspace.root

    let notes = (checked changes note list -provider local-notes -json -from $workspace.base | from json --strict | get notes | where {|note|
        $note.session? == $id and $note.origin == user
    })

    if not $send {
        return ({
            version: 'sysinit.agent-feedback/v1'
            workspace: $id
            root: $workspace.root
            base: $workspace.base
            notes: $notes
        } | to json --raw)
    }

    if ($notes | is-empty) { error make {msg: 'No review notes were recorded for this workspace.'} }

    if $workspace.codex == null {
        error make {msg: 'Use the feedback JSON with the chosen agent’s input interface.'}
    }

    if $workspace.codex.thread_id == null {
        error make {msg: 'The Codex TUI has not attached to a thread yet.'}
    }

    let comments = $notes | each {|note|
        {
            anchor: $note.anchor
            placement: $note.placement?
            summary: $note.summary
            rationale: $note.rationale?
        }
    }

    let text = ([
        'Address the following user review notes for this worktree. Verify the current lines before editing.'
        ($comments | to json)
    ] | str join "\n\n")

    $text | (checked
        bun
        $client
        feedback
        $workspace.codex.socket
        $workspace.root
        $workspace.codex.thread_id
        ($steer | default '')
    ) | str trim
}

def main [] {
    help main
}
