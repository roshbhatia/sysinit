use std/assert

def notify [script: path, arguments: list<string>] {
    let result = ^bash -euo pipefail $script ...$arguments | complete

    assert equal $result.exit_code 0 $result.stderr

    {
        output: ($result.stdout | str trim)
        arguments: (open $env.NOTIFIER_ARGUMENTS)
    }
}

def main [source: path, fixture: path] {
    let root = mktemp --directory

    try {
        let backend = $root | path join backend

        let focus = $root | path join 'focus handler'

        for entry in [
            {path: $backend, name: backend}
            {path: $focus, name: focus}
        ] {
            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.NOTIFIER_TEST_COMMAND = "($entry.name)"' + "\n" + (open --raw $fixture)
            ) | save $entry.path

            ^chmod 700 $entry.path
        }

        let script = $root | path join notify.sh

        (
            $'NOTIFICATION_EXE=($backend | to json --raw)' + "\n" + (open --raw $source)
        ) | save $script

        let context = $root | path join focus.json

        with-env {NOTIFIER_ARGUMENTS: ($root | path join arguments.json), NOTIFIER_CONTEXT: $context} {
            hide-env --ignore-errors AGENT_NOTIFY_FOCUS_EXE AGENT_NOTIFY_PANE AGENT_NOTIFY_SESSION
            let basic = notify $script [--title '[Codex]' --message 'Tests passed' --app-icon /icons/codex.png --timeout '5']
            assert equal $basic.output '@ACTIONCLICKED'
            let title = $basic.arguments | enumerate | where item == '-title' | first | get index
            let image = $basic.arguments | enumerate | where item == '-contentImage' | first | get index
            assert equal ($basic.arguments | get ($title + 1)) '\[Codex]'
            assert equal ($basic.arguments | get ($image + 1)) '\/icons/codex.png'
            let session = "project's task\nnext line"
            with-env {AGENT_NOTIFY_FOCUS_EXE: $focus, AGENT_NOTIFY_PANE: '42', AGENT_NOTIFY_SESSION: $session, WEZTERM_UNIX_SOCKET: '/tmp/mux socket'} {
                let focused = notify $script [--title Codex --message Done --timeout '5']
                assert ('-action' not-in $focused.arguments)
                assert ('-execute' in $focused.arguments)
                assert equal (open $context) {args: ['42' $session], socket: '/tmp/mux socket'}
            }
            assert equal (notify $script [--remove agent:42] | get arguments) [-remove '\agent:42']
        }
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'Notification image, encoding, click context, and removal checks passed'
}
