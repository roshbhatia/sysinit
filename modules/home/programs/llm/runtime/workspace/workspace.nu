use ../agents/catalog.nu agent-catalog
use ../diff/wezterm-mux.nu [wezterm-socket wezterm-mux-identity]

const runtime = path self | path dirname
const client = $runtime | path join codex.ts
const observer = $runtime | path join observe.ts

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

    let saved = open --raw ($directory | path join workspace.json) | from json --strict

    let workspace = {
        cwd: $saved.root
        review: git
        agent: null
        conversation: null
        launch_args: []
        watch: false
    } | merge $saved

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
    $in | checked wezterm cli --no-auto-start ...$args | str trim
}

def panes [] {
    checked ty panes | from json --strict | get panes
}

def require-mux [] {
    let socket = wezterm-socket

    let identity = wezterm-mux-identity $socket

    if $identity == null {
        error make {
            msg: 'Cannot identify the WezTerm mux. Run from a WezTerm pane or specify WEZTERM_UNIX_SOCKET.'
        }
    }

    {mux: $socket, mux_identity: $identity}
}

def workspace-pane-live [workspace: record] {
    let identity = wezterm-mux-identity (wezterm-socket)

    if $identity == null or $identity != $workspace.mux_identity? { return false }

    panes | any {|pane| $pane.pane_id == $workspace.pane_id and $pane.tab_id == $workspace.tab_id }
}

def directory [path: path] {
    let resolved = $path | path expand --strict

    if ($resolved | path type) != dir {
        error make {msg: $"Expected a directory: ($resolved)"}
    }

    $resolved
}

def inside [path: string, root: string] {
    let relative = try {
        $path | path relative-to $root
    }

    $relative != null and (($relative | path split | get 0?) | default '') != '..'
}

def workspace-directory [session, cwd] {
    if $session == null { return (directory ($cwd | default $env.PWD)) }

    let selected = checked sy status $session --format json | from json --strict

    let repos = $selected.repos | each {|repo| directory $repo.path }

    let session_root = directory $selected.path

    if $cwd == null {
        return (
            if ($repos | length) == 1 {
                $repos | first
            } else {
                $session_root
            }
        )
    }

    let resolved = directory $cwd

    if not (inside $resolved $session_root) and not ($repos | any {|repo| inside $resolved $repo }) {
        error make {msg: 'The directory is outside the selected seshy session.'}
    }

    $resolved
}

def agents [] {
    agent-catalog | get agents
}

def launch-plan [
    name: string
    conversation
    args: list<string>
    --new
] {
    let matches = agents | where {|entry| $entry.name == $name or $entry.command == $name }

    if ($matches | is-empty) { error make {msg: $"Unknown agent ($name). Run agent-workspace agents."} }

    let agent = $matches | first

    if not $agent.available { error make {msg: $"Agent command ($agent.command) is unavailable."} }

    let create = $agent.launch.newSessionArgs? | default []

    let resume = $agent.launch.resumeArgs? | default []

    if $conversation != null and (($resume | is-empty) or ($conversation | str starts-with '-') or ($conversation | is-empty)) {
        error make {
            msg: 'This agent needs a supported native conversation ID. To use its own syntax, pass the entire command after --.'
        }
    }

    let binding = if $new and $conversation == null and ($create | is-not-empty) {
        {
            id: (random uuid)
            flags: $create
        }
    } else if $conversation != null {
        {id: $conversation, flags: $resume}
    } else {
        {
            id: null
            flags: ($agent.launch.startArgs? | default [])
        }
    }

    let native = if $binding.id == null {
        $binding.flags
    } else {
        $binding.flags | append $binding.id
    }

    {
        agent: $agent.name
        conversation: $binding.id
        argv: ([$agent.command] | append $native | append $args)
    }
}

def "main agents" [--all] {
    agents | where {|entry| $all or $entry.available } | select name label command available launch | to json --raw
}

def "main list" [] {
    glob --no-dir (state-dir | path join '*' workspace.json) | each {|file|
        let id = $file | path dirname | path basename
        try {
            load-workspace $id | select id cwd root review agent conversation session task pane_id tab_id codex
        } catch {
            print --stderr $"agent-workspace: skipped invalid record ($file)"
            null
        }
    } | compact | to json --raw
}

def socket-path [socket] {
    let codex_home = $env.CODEX_HOME? | default ($env.HOME | path join .codex)

    $socket | default ($codex_home | path join app-server-control app-server-control.sock) | path expand --no-symlink
}

def ensure-client [] {
    if (checked ty clients | from json --strict | get clients | is-empty) {
        error make {msg: 'No attached WezTerm client.'}
    }
}

def spawn-agent [workspace: record, parent] {
    let connection = require-mux

    let target = $parent | default $env.WEZTERM_PANE?

    let args = if $target == null {
        []
    } else {
        [
            --pane-id
            ($target | into string)
        ]
    }

    let command = if $workspace.codex == null and not $workspace.watch {
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

    let pane = with-env {WEZTERM_UNIX_SOCKET: $connection.mux} {
        let pane_id = mux spawn ...$args --cwd $workspace.cwd -- ...$command | into int

        panes | where pane_id == $pane_id | first
    }

    let updated = $workspace | merge $connection | merge {pane_id: $pane.pane_id, tab_id: $pane.tab_id}

    save-workspace $updated

    $updated
}

def workspace-context [
    session
    cwd
    base
    directory: bool
] {
    let cwd = workspace-directory $session $cwd

    let repository = if not $directory {
        try {
            checked git -C $cwd rev-parse --show-toplevel | str trim
        }
    }

    if $base != null and $repository == null {
        error make {
            msg: '--base requires a Git worktree. Use refresh --against to compare ordinary directories.'
        }
    }

    let revision = if $repository != null {
        let ref = $base | default HEAD

        if $base == null {
            try {
                checked git -C $repository rev-parse --verify HEAD | str trim
            }
        } else {
            (checked
                git
                -C
                $repository
                rev-parse
                --verify
                --end-of-options
                $'($ref)^{commit}'
            ) | str trim
        }
    }

    {
        version: 'sysinit.agent-workspace/v1'
        id: (random uuid)
        cwd: $cwd
        root: ($repository | default $cwd)
        review: (if $repository == null { 'directory' } else { 'git' })
        base: $revision
        session: $session
        task: null
        mux: $env.WEZTERM_UNIX_SOCKET?
        pane_id: null
        tab_id: null
        agent: null
        conversation: null
        argv: []
        watch: false
        launch_args: []
        codex: null
    }
}

def create-workspace [workspace: record] {
    let directory = record-path $workspace.id

    mkdir $directory

    chmod 700 $directory

    save-workspace $workspace
}

def "main open" [
    --session: string
    --cwd: path
    --task: string
    --pane-id: int
    --agent: string
    --conversation: string
    --base: string
    --directory
    --watch
    --no-watch
    --adapter: string
    --thread: string
    --socket: path
    ...command: string
] {
    if $watch and $no_watch { error make {msg: 'Choose either --watch or --no-watch.'} }

    let name = $agent | default $env.SYSINIT_WORKSPACE_AGENT?

    let adapter = if $thread != null or $socket != null {
        $adapter | default codex
    } else {
        $adapter
    }

    if $adapter != null and $adapter != codex { error make {msg: $"Unknown workspace adapter: ($adapter)"} }

    let plan = if $adapter == codex {
        if ($agent != null and $agent != codex) or ($command | is-not-empty) {
            error make {
                msg: 'The Codex adapter uses the native Codex TUI. Remove other launch arguments or select the generic launcher.'
            }
        }

        {
            agent: codex
            conversation: null
            argv: []
        }
    } else if $agent != null or (($command | is-empty) and $name != null) {
        launch-plan $name $conversation $command --new
    } else if ($command | is-not-empty) and $conversation == null {
        {agent: null, conversation: null, argv: $command}
    } else {
        error make {
            msg: 'Choose --agent from agent-workspace agents, set SYSINIT_WORKSPACE_AGENT, or supply a command after --.'
        }
    }

    ensure-client

    let context = workspace-context $session $cwd $base $directory

    let codex = if $adapter == codex {
        let endpoint = socket-path $socket

        let thread_id = (checked
            bun
            $client
            bind
            $endpoint
            $context.cwd
            ($thread | default ($conversation | default ''))
        ) | from json --strict | get thread_id

        {socket: $endpoint, thread_id: $thread_id}
    }

    let workspace = $context | merge $plan | merge {
        task: $task
        watch: ($codex == null and not $no_watch and ($watch or $context.review == git))
        launch_args: $command
        codex: $codex
    }

    create-workspace $workspace

    spawn-agent $workspace $pane_id | to json --raw
}

def "main attach" [
    --pane-id: int
    --cwd: path
    --session: string
    --task: string
    --base: string
    --directory
] {
    ensure-client

    let connection = require-mux

    let owner = $pane_id | default (
        try {
            $env.WEZTERM_PANE | into int
        }
    )

    if $owner == null { error make {msg: 'Select an existing pane with --pane-id.'} }

    let tab = with-env {WEZTERM_UNIX_SOCKET: $connection.mux} {
        panes | where pane_id == $owner | get 0?
    }

    if $tab == null { error make {msg: 'The selected pane is no longer live.'} }

    let path = if $cwd != null {
        $cwd
    } else if ($tab.cwd? | default '') starts-with 'file://' {
        $tab.cwd | url parse | get path | url decode
    } else {
        error make {msg: 'The pane has no local directory. Supply --cwd.'}
    }

    let workspace = workspace-context $session $path $base $directory | merge $connection | merge {
        task: $task
        pane_id: $owner
        tab_id: $tab.tab_id
    }

    create-workspace $workspace

    $workspace | to json --raw
}

def "main show" [id: string] {
    let active = record-path $id | path join active-turn.json

    let turn_id = try {
        open --raw $active | from json --strict | get turn_id
    }

    load-workspace $id | merge {active_turn_id: $turn_id} | to json --raw
}

def with-mux [workspace: record, action: closure] {
    let socket = $workspace.mux?

    if $socket != null and ($socket | path exists) {
        with-env {WEZTERM_UNIX_SOCKET: $socket} { do $action }
    } else {
        do $action
    }
}

def "main resume" [
    id: string
    --pane-id: int
    --conversation: string
    --restart
] {
    let workspace = load-workspace $id

    if $restart and $conversation != null {
        error make {msg: 'Choose either --restart or --conversation.'}
    }

    with-mux $workspace {||
        ensure-client

        if (workspace-pane-live $workspace) {
            if $restart or $conversation != null {
                error make {msg: 'The existing workspace pane is still live.'}
            }

            checked ty pane focus ($workspace.pane_id | into string) | ignore

            return ($workspace | to json --raw)
        }

        let updated = if $workspace.codex != null {
            let thread = if $restart {
                ''
            } else {
                $conversation | default ($workspace.codex.thread_id | default '')
            }

            checked bun $client bind $workspace.codex.socket $workspace.cwd $thread | ignore

            if $restart or $conversation != null {
                let binding = record-path $id | path join thread.json

                if ($binding | path exists) { rm $binding }
            }

            $workspace | update codex ($workspace.codex | update thread_id ($thread | default --empty null))
        } else if $workspace.agent != null and ($conversation != null or $workspace.conversation != null or $restart) {
            let native = if $restart {
                null
            } else {
                $conversation | default $workspace.conversation
            }

            $workspace | merge (launch-plan $workspace.agent $native $workspace.launch_args --new)
        } else if $restart and ($workspace.argv | is-not-empty) {
            $workspace
        } else {
            error make {
                msg: 'The pane closed. Supply --conversation for a native saved session, or --restart to launch a fresh process.'
            }
        }

        save-workspace $updated

        spawn-agent $updated $pane_id | to json --raw
    }
}

def "main refresh" [
    id: string
    --focus
    --against: path
    --file: string
] {
    let workspace = load-workspace $id

    if $against != null and $file == null {
        error make {msg: '--against also requires --file.'}
    }

    with-mux $workspace {||
        if not (workspace-pane-live $workspace) {
            error make {
                msg: 'The recorded workspace pane is unavailable. Resume or attach the workspace first.'
            }
        }

        let owner = $workspace.pane_id | into string

        let focus_flags = if $focus { [] } else { [--background] }

        let args = if $workspace.review == directory or $against != null or $file != null {
            let file_flags = if $file == null { [] } else { [--file $file] }

            let baseline = if $against == null { [] } else { [--against $against] }

            [
                --directory
                --note-session
                $id
                --note-command
                $env.SYSINIT_AGENT_WORKSPACE_BIN
                ...$file_flags
                ...$baseline
            ]
        } else {
            let status = checked git -C $workspace.root status --porcelain

            let base = $workspace.base

            let commits = if $base != null {
                checked git -C $workspace.root diff --name-only $base HEAD
            } else {
                ''
            }

            let base_flags = if $base == null {
                []
            } else {
                [--base $base --note-session $id]
            }

            let visibility = if not $focus and ($status | is-empty) and ($commits | is-empty) {
                [--if-open]
            } else {
                []
            }

            [...$base_flags ...$visibility]
        }

        (checked
            agent-diff
            --cwd
            $workspace.root
            --pane-id
            $owner
            --json
            ...$focus_flags
            ...$args
        ) | str trim
    }
}

def "main run" [id: string] {
    let workspace = load-workspace $id

    if $workspace.codex != null {
        ^bun $client run $workspace.codex.socket $workspace.cwd ($workspace.codex.thread_id | default '') (record-path $id) $env.SYSINIT_AGENT_WORKSPACE_BIN $id
    } else {
        ^bun $observer $workspace.root $workspace.review (record-path $id) $env.SYSINIT_AGENT_WORKSPACE_BIN $id ...$workspace.argv
    }
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
    --working-file
] {
    let workspace = load-workspace $id

    if $working_file or $workspace.base == null {
        let root = $workspace.root

        let target = $root | path join $file | path expand --strict

        if not (inside $target $root) or ($target | path type) != file {
            error make {msg: 'Select a file inside the workspace.'}
        }

        if $side != right or $line < 1 or ($start_line != null and ($start_line < 1 or $start_line > $line)) or ($message | str trim | is-empty) {
            error make {msg: 'Specify a valid working-file line range and nonempty note.'}
        }

        let note = {
            id: (random uuid)
            origin: 'user'
            session: $id
            summary: $message
            anchor: {
                path: ($target | path relative-to $root)
                side: 'RIGHT'
                line: $line
                startLine: $start_line
            }
        }

        let directory = record-path $id | path join notes

        mkdir $directory

        $note | to json --raw | save ($directory | path join $'($note.id).json')

        return ($note | to json --raw)
    }

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

def "main feedback" [
    id: string
    --paste
    --send
    --steer: string
] {
    let workspace = load-workspace $id

    if $steer != null and not $send { error make {msg: '--steer requires --send.'} }

    if $paste and $send { error make {msg: 'Choose either --paste or --send.'} }

    let file_notes = glob --no-dir (record-path $id | path join notes '*.json') | each {|path| open --raw $path | from json --strict }

    let notes = if $workspace.base != null {
        cd $workspace.root

        let git_notes = checked changes note list -provider local-notes -json -from $workspace.base | from json --strict | get notes | where {|note|
            $note.session? == $id and $note.origin == user
        }

        $file_notes | append $git_notes
    } else {
        $file_notes
    }

    if not $send and not $paste {
        return ({
            version: 'sysinit.agent-feedback/v1'
            workspace: $id
            root: $workspace.root
            base: $workspace.base
            notes: $notes
        } | to json --raw)
    }

    if ($notes | is-empty) { error make {msg: 'No review notes were recorded for this workspace.'} }

    let comments = $notes | each {|note|
        {anchor: $note.anchor, placement: $note.placement?, summary: $note.summary, rationale: $note.rationale?}
    }

    let instruction = 'Address the following user review notes for this workspace. Verify the current lines before editing.'

    if $paste {
        return (with-mux $workspace {||
            if not (workspace-pane-live $workspace) {
                error make {msg: 'The recorded workspace pane is unavailable. Resume or attach the workspace first.'}
            }
            let text = [$instruction ($comments | to json --raw)] | str join ' '
            $text | mux send-text --pane-id ($workspace.pane_id | into string) | ignore
            {pane_id: $workspace.pane_id} | to json --raw
        })
    }

    if $workspace.codex == null {
        error make {msg: 'Use --paste for this agent, or pipe the feedback JSON to its own input interface.'}
    }

    if $workspace.codex.thread_id == null {
        error make {msg: 'The Codex TUI has not attached to a thread yet.'}
    }

    let text = [
        $instruction
        ($comments | to json)
    ] | str join "\n\n"

    $text | (checked
        bun
        $client
        feedback
        $workspace.codex.socket
        $workspace.cwd
        $workspace.codex.thread_id
        ($steer | default '')
    ) | str trim
}

def main [] {
    help main
}
