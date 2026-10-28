def threads-pick [rows: list<record>, prompt: string] {
    let choice = ($rows
        | enumerate
        | each {|row|
            let label = $row.item.label | str replace --all --regex '[\x00-\x1f\x7f]' ' '
            $"($row.index)\t($label)"
        }
        | str join (char newline)
        | ^fzf --height=8 --layout=reverse --no-preview --delimiter="\t" --with-nth=2.. --prompt $prompt
        | complete)
    if $choice.exit_code in [1 130] { return null }
    if $choice.exit_code != 0 {
        error make {msg: $"Thread picker failed: ($choice.stderr | str trim)"}
    }
    let index = $choice.stdout | str trim | split row (char tab) | first | into int
    $rows | get $index
}

# Pick a local agent thread and action; arguments retain the native Atuin interface.
export def --wrapped threads [
    --print # Print the resume command; native fork/conversion still writes a new session.
    ...arguments: string
] {
    if not ($arguments | is-empty) {
        let flags = if $print { [--print] } else { [] }
        ^atuin threads ...$arguments ...$flags
    } else {
        let action = threads-pick [
            {name: resume, label: 'Resume in original harness'}
            {name: continue, label: 'Continue in another harness'}
            {name: fork, label: 'Fork into a new session'}
            {name: inspect, label: 'Inspect conversation'}
        ] 'action> '
        if $action == null { return }

        let sessions = ^atuin threads list --style json | from json
        if ($sessions | is-empty) {
            print -e 'No captured threads yet.'
            return
        }
        let candidates = $sessions | each {|session|
            $session | insert label $"[($session.harness)] ($session.preview | str substring 0..160)  ($session.cwd)"
        }
        let thread = threads-pick $candidates 'thread> '
        if $thread == null { return }

        if $action.name == inspect {
            ^atuin threads show $thread.atuin_id
        } else {
            mut flags = if $print { [--print] } else { [] }
            if $action.name == continue {
                let registry = $env.XDG_CONFIG_HOME?
                | default ($nu.home-dir | path join '.config')
                | path join sysinit agents.json
                let harnesses = open $registry
                | get agents
                | where {|agent| $agent.name in [claude codex opencode pi omp] and not (which $agent.command | is-empty) }
                if ($harnesses | is-empty) {
                    error make {
                        msg: 'No installed harness supports Atuin thread conversion.'
                    }
                }
                let harness = threads-pick $harnesses 'harness> '
                if $harness == null { return }
                $flags = $flags | append [--in $harness.name]
            } else if $action.name == fork {
                $flags = $flags | append '--fork'
            } else {
                $flags = $flags | append '--as-is'
            }
            ^atuin resume $thread.atuin_id ...$flags
        }
    }
}
