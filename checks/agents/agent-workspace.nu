use std/assert

def main [script: path, fixture: path, ty: path] {
    let script = $script | path expand --strict

    let fixture = $fixture | path expand --strict

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    let bin = $root | path join bin

    let ty_command = [
        'exec'
        ($nu.current-exe | to json --raw)
        '--no-config-file'
        ($ty | path expand --strict | to json --raw)
        '"$@"'
    ] | str join ' '

    let config = $root | path join config

    let project = $root | path join 'plain folder'

    let state = $root | path join state

    mkdir $bin ($config | path join sysinit) ($config | path join nushell) $project

    $"#!/bin/sh\n($ty_command)\n" | save ($bin | path join ty)

    $"#!/bin/sh\nexec ($nu.current-exe) --no-config-file --stdin ($fixture) wezterm \"\$@\"\n" | save ($bin | path join wezterm)

    "#!/bin/sh\nexit 0\n" | save ($bin | path join fake-agent)

    chmod +x ($bin | path join wezterm) ($bin | path join ty) ($bin | path join fake-agent)

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
            let invalid_id = random uuid
            let invalid = $state | path join agent-workspace $invalid_id
            mkdir $invalid
            'invalid JSON' | save ($invalid | path join workspace.json)
            let invalid_only = ^$nu.current-exe --no-config-file $script list | complete
            assert equal $invalid_only.exit_code 0
            assert equal ($invalid_only.stdout | from json --strict) []

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

            let listed = ^$nu.current-exe --no-config-file $script list | complete
            assert equal $listed.exit_code 0
            assert equal ($listed.stdout | from json --strict | get id | sort) ([$id $attached.id] | sort)
            assert ($listed.stderr | str contains $invalid_id)
            let invalid_show = ^$nu.current-exe --no-config-file $script show $invalid_id | complete
            assert ($invalid_show.exit_code != 0)

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

    print 'Registry launch, review notes, workspace listing, pane attachment, and exact conversation resume passed'
}
