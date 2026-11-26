use std/assert

def seed [root: path, statuses: list<string>] {
    $statuses | enumerate | each {|row|
        let pane = $row.index | into string
        {pane: $pane, status: $row.item, repo: '/repo with spaces', agent: codex, since: 1}
            | to json | save --force ($root | path join panes ($pane + '.json'))
        {pane_id: $row.index, workspace: 'session with spaces', is_active: ($row.index == 0)}
    } | to json
}

def status [script: path] {
    let result = ^bash $script | complete

    assert equal $result.exit_code 0 $result.stderr

    $result.stdout | from json
}

def main [
    source: path
    reducer: path
    review: path
    fixture: path
] {
    for case in [review mixed discovery malformed] {
        let root = mktemp --directory | path expand --strict

        try {
            mkdir ($root | path join panes) ($root | path join bin)

            for name in [wezterm sy] {
                let path = $root | path join bin $name

                (
                    $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.AGENT_SESSION_TEST_COMMAND = "($name)"' + "\n" + (open --raw $fixture)
                ) | save $path

                ^chmod 700 $path
            }

            let script = $root | path join run.sh

            (
                'sysinit_path() { if [ "$1" = agentPanes ]; then echo "$FIXTURE/panes"; else echo "$FIXTURE"; fi; }' + "\n" + (
                    open --raw $source
                    | str replace --all '@agentSessionsReducer@' $reducer
                )
            ) | save $script

            {
                selected: 'session with spaces'
                heartbeat: (date now | into int | $in // 1_000_000_000)
            }
            | to json
            | save ($root | path join selected.json)

            with-env {PATH: ($env.PATH | prepend ($root | path join bin)), FIXTURE: $root, LIVE: '[]'} {
                match $case {
                    review => {
                        let repository = $root | path join repo
                        ^git init -q $repository
                        let result = ^bash $review $repository | complete
                        assert ($result.exit_code in [0 1]) $result.stderr
                        assert equal (open ($root | path join wezterm-args.json)) [cli --no-auto-start list --format json]
                    }
                    mixed => {
                        for expected in [
                            {statuses: [working done], status: working, blocked: 0, attention: 1}
                            {statuses: [working waiting], status: waiting, blocked: 1, attention: 1}
                        ] {
                            with-env {LIVE: (seed $root $expected.statuses)} {
                                let payload = status $script
                                let session = $payload.sessions | first
                                assert equal ($session | select status blocked attention) ($expected | select status blocked attention)
                                assert equal $session.repo '/repo with spaces'
                                assert equal ($payload.agents | get status) $expected.statuses
                                assert equal ($payload.agents | get pane_id) [0 1]
                            }
                        }
                    }
                    discovery => {
                        with-env {LIVE: (seed $root [working])} {
                            status $script | ignore
                            with-env {PROBE_EXIT: '1'} {
                                let payload = status $script
                                assert equal $payload.discovery_state unavailable
                                assert equal $payload.selection_state stale
                            }
                            with-env {LIVE: '[]', PROBE_EXIT: '0'} {
                                assert (status $script | get sessions | all {|row| $row.panes == 0})
                            }
                        }
                    }
                    malformed => {
                        with-env {LIVE: (seed $root [working])} {
                            'interrupted write' | save ($root | path join panes bad.json)
                            assert equal (status $script | get sessions | first | get panes) 1
                            with-env {LIVE: invalid} {
                                assert equal (status $script | get discovery_state) unavailable
                            }
                        }
                    }
                }
            }
        } catch {|failure|
            rm --recursive --force $root

            error make $failure
        }

        rm --recursive --force $root
    }

    print 'Agent session aggregation, failed discovery, malformed records, and review inspection checks passed'
}
