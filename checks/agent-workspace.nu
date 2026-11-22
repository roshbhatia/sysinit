use std/assert

def main [script: path, fixture: path] {
    let script = $script | path expand --strict

    let fixture = $fixture | path expand --strict

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    let bin = $root | path join bin

    let config = $root | path join config

    let project = $root | path join 'plain folder'

    let state = $root | path join state

    mkdir $bin ($config | path join sysinit) ($config | path join nushell) $project

    $"#!/bin/sh\nexec ($nu.current-exe) --no-config-file --stdin ($fixture) wezterm \"\$@\"\n" | save ($bin | path join wezterm)

    "#!/bin/sh\nexit 0\n" | save ($bin | path join fake-agent)

    chmod +x ($bin | path join wezterm) ($bin | path join fake-agent)

    [
        {
            pane_id: 7
            tab_id: 2
            cwd: $"file://($project | url encode --all | str replace --all '%2F' '/')"
        }
    ] | to json | save ($root | path join panes.json)

    {
        agents: [
            {
                name: 'fixture'
                command: 'fake-agent'
                label: 'Fixture'
                launch: {
                    startArgs: [interactive]
                    resumeArgs: [interactive --resume]
                }
            }
        ]
    } | to json | save ($config | path join sysinit agents.json)

    'before' | save ($project | path join file.txt)

    try {
        with-env {
            XDG_STATE_HOME: $state
            XDG_CONFIG_HOME: $config
            REVIEW_FIXTURE: $root
            PATH: ($env.PATH | prepend $bin)
        } {
            let launched = ^$nu.current-exe --no-config-file $script open --agent fixture --cwd $project --pane-id 7 -- --model fixture-model | from json --strict
            assert equal $launched.review directory
            assert equal $launched.base null
            assert equal $launched.cwd $project
            assert equal $launched.argv [fake-agent interactive --model fixture-model]

            let id = $launched.id
            let note = ^$nu.current-exe --no-config-file $script note $id file.txt 1 'A review note.' | from json --strict
            assert equal $note.anchor.path file.txt
            let feedback = ^$nu.current-exe --no-config-file $script feedback $id | from json --strict
            assert equal ($feedback.notes | get 0.summary) 'A review note.'
            ^$nu.current-exe --no-config-file $script feedback $id --paste | ignore
            let pasted = open --raw ($root | path join paste.txt)
            assert ($pasted | str contains 'A review note.')
            assert (not ($pasted | str contains "\n"))

            let attached = ^$nu.current-exe --no-config-file $script attach --pane-id 7 | from json --strict
            assert equal $attached.cwd $project
            assert equal $attached.argv []

            open ($root | path join panes.json) | where pane_id != 9 | to json | save --force ($root | path join panes.json)
            let resumed = ^$nu.current-exe --no-config-file $script resume $id --conversation fixture-conversation --pane-id 7 | from json --strict
            assert equal $resumed.id $id
            assert equal $resumed.argv [fake-agent interactive --resume fixture-conversation --model fixture-model]
            assert equal $resumed.conversation fixture-conversation
        }
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'Registry launch, plain folder review notes, pane attachment, and exact conversation resume passed'
}
