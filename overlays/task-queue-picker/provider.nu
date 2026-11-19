def command-output [program: string, arguments: list<string>] {
    let result = ^timeout 4s $program ...$arguments | complete
    if $result.exit_code != 0 { error make {msg: $'($program) exited ($result.exit_code): ($result.stderr)'} }
    $result.stdout
}

# Each attachable attempt runs in its own workspace on the persistent WezTerm mux.
def terminal-live [wezterm: string, terminal: string] {
    let socket = $env.TASK_QUEUE_WEZTERM_SOCKET? | default ($env.HOME | path join .local state wezterm mux.sock)
    let panes = with-env {WEZTERM_UNIX_SOCKET: $socket} {
        command-output $wezterm [cli --prefer-mux --no-auto-start list --format json]
    }
    $panes | from json | any {|pane| $pane.workspace == $terminal }
}

def attempt [job: record] {
    let label = $job.label? | default ''
    if not ($label | str starts-with 'task-queue:') { return {} }
    let compact = $label
    | str replace 'task-queue:' ''
    | str replace --all 'urn:' ''
    | str replace --all 'uuid:' ''
    | str replace --regex '^[{}]+' ''
    | str replace --regex '[{}]+$' ''
    | str replace --all '-' ''
    | str lowercase
    if $compact !~ '^[0-9a-f]{32}$' { error make {msg: 'invalid task-queue attempt UUID'} }
    let identifier = [
        ($compact | str substring 0..7)
        ($compact | str substring 8..11)
        ($compact | str substring 12..15)
        ($compact | str substring 16..19)
        ($compact | str substring 20..31)
    ] | str join '-'
    let state = $env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)
    let path = $state | path join task-queue ($identifier + '.json')
    if not ($path | path exists) { return {} }
    open --raw $path | from json
}

def status [job: record] {
    let value = $job.status
    if ($value | describe) == string { return $value }
    let name = $value | columns | first
    if $name == Done {
        let result = $value | get $name | get result
        if ($result | describe) == string {
            $result
        } else {
            $result | columns | first
        }
    } else { $name }
}

def respond [request: record, wezterm: string, viewer: string] {
    if ($request.version? | default '') != provider/v1 or ($request.kind? | default '') != request {
        error make {msg: 'expected a provider/v1 request'}
    }
    let capability = $request.capability
    if $capability == picker.describe {
        return {title: 'Task queue · terminals and logs', icon: md_checklist}
    }
    let snapshot = command-output pueue [status --json] | from json | get tasks
    if $capability == provider.validate { return {ok: true} }
    if $capability == picker.list {
        let ordered = $snapshot | transpose id job | each {|row|
            $row | merge {inactive: ((status $row.job) not-in [Running Paused Queued Stashed]), order: (0 - ($row.id | into int))}
        } | sort-by inactive order
        let items = $ordered | each {|row|
            let record = attempt $row.job
            let arguments = $record.argv? | default [] | str join ' '
            let command = $arguments | default --empty $row.job.original_command
            let name = $record.session? | default --empty $row.job.group
            let folder = $row.job.path | path basename
            let thread = $record.thread? | default ''
            let linked = if $thread == '' { '' } else { $' · thread ($thread | str substring (-8)..)' }
            let target = if ($record.terminal? | default '') == '' { 'logs' } else { 'terminal/logs' }
            let summary = $command | str replace --all --regex '\s+' ' ' | str trim | split chars --code-points | take 160 | str join ''
            let detail = $'($folder) · ($target)($linked) · ($summary)'
            {
                id: $row.id
                search: ([$name $detail $row.job.path ($record.task? | default '') $thread $command] | str join ' ')
                segments: [
                    {text: $'#($row.id) (status $row.job) ($name)', role: name}
                    {text: $detail, role: detail}
                ]
            }
        }
        return {items: $items}
    }
    if $capability == picker.open {
        let identifier = $request.input.id
        if ($identifier | describe) != string or $identifier not-in $snapshot {
            error make {msg: 'Pueue task no longer exists'}
        }
        let job = $snapshot | get $identifier
        let record = attempt $job
        let terminal = $record.terminal? | default ''
        # The launcher switches to an existing workspace named by the label and spawns only for a new one.
        let label = if $terminal != '' and (terminal-live $wezterm $terminal) { $terminal } else { $'Pueue #($identifier)' }
        let command = [
            $viewer
            $identifier
            (if (status $job) == Running { 'follow' } else { 'log' })
        ]
        let cwd = if ($job.path | path expand | path type) == dir { $job.path } else { $env.HOME }
        return {
            kind: spawn
            label: $label
            cwd: $cwd
            command: $command
            environment: {}
        }
    }
    error make {msg: $'unsupported capability: ($capability)'}
}

def main [wezterm: string = 'wezterm', viewer: string = 'pueue-task-view'] {
    let input = $in
    let parsed = try {
        $input | from json
    } catch {
        null
    }
    let request = if ($parsed | describe | str starts-with record) { $parsed } else { {} }
    let result = try {
        {
            status: ok
            output: (respond $request $wezterm $viewer)
        }
    } catch {|failure|
        {status: error, message: $failure.msg}
    }
    $result | merge {version: provider/v1, kind: result, requestId: ($request.requestId? | default invalid)} | to json | print
}
