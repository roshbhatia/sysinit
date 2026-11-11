# Drives the ty script against stub sy and wezterm executables that log their argv.
def main [script: path] {
    let root = (mktemp -d)
    let log = $root | path join "calls.log"
    let stub = {|name, body|
        let path = $root | path join $name
        $"#!/bin/sh\nprintf '%s\\n' \"($name) $*\" >> '($log)'\n($body)\n" | save $path
        chmod +x $path
        $path
    }
    let plan = $root | path join "plan.json"
    '{"version":"seshy.open/v1","id":"seshy:feature","cwd":"/repo","command":[],"environment":{}}' | save $plan
    let sy = (do $stub sy ([
        'case "$1" in'
        '  list) echo "[{\"id\":\"seshy:feature\"}]";;'
        $'  open) if [ "$2" = bad ]; then echo "{\\"version\\":\\"other\\"}"; else cat "($plan)"; fi;;'
        'esac'
    ] | str join "\n"))
    let wezterm = (do $stub wezterm ([
        'case "$*" in'
        '  *"list --format json"*) echo "[{\"pane_id\":7,\"workspace\":\"feature\"}]";;'
        '  *spawn*) echo 41;;'
        '  *split-pane*) echo 42;;'
        '  *get-text*) printf "raw\\ntext";;'
        '  *activate-pane*"--pane-id 99"*) echo "no such pane" >&2; exit 1;;'
        '  *send-text*) cat > /dev/null;;'
        'esac'
    ] | str join "\n"))
    let ty = {|args|
        with-env {SYSINIT_TY_SY: $sy SYSINIT_TY_WEZTERM: $wezterm SYSINIT_TY_ENV: "/usr/bin/env"} { ^nu --no-config-file $script ...$args | complete }
    }
    let calls = {
        open $log | lines
    }
    let reset = {
        "" | save --force $log
    }
    let check = {|condition, message|
        if not $condition { error make {msg: $"ty: ($message)"} }
    }

    do $reset
    let catalog = (do $ty [catalog])
    do $check (
        $catalog.exit_code == 0 and ($catalog.stdout | from json) == {
            version: "sysinit.ty/v1"
            sessions: [
                {id: "seshy:feature"}
            ]
            panes: [
                {pane_id: 7, workspace: feature}
            ]
        }
    ) $"catalog output ($catalog)"

    do $reset
    let sessions = (do $ty [sessions])
    do $check (
        (
            $sessions.stdout
            | from json
            | get sessions
            | length
        ) == 1 and (do $calls | all {|c| $c | str starts-with "sy " })
    ) "sessions contacted wezterm"

    do $reset
    let opened = (do $ty [session open feature])
    do $check (
        ($opened.stdout | from json) == {
            version: "sysinit.ty/v1"
            action: "session.open"
            session_id: "seshy:feature"
            workspace: feature
            cwd: "/repo"
            pane_id: "41"
            opened: true
        }
    ) $"open result ($opened)"
    do $check (
        (do $calls | last) == "wezterm cli --no-auto-start spawn --new-window --workspace feature --cwd /repo"
    ) "open spawned with the wrong arguments"

    do $reset
    let invalid = (do $ty [session open bad])
    do $check (
        $invalid.exit_code == 1 and not (do $calls | any {|c| $c | str contains spawn })
    ) "an unsupported plan spawned a window"

    do $reset
    let switched = (do $ty [session switch feature])
    do $check (
        ($switched.stdout | from json | get pane_id) == "7" and (
            do $calls
            | any {|c| $c == "wezterm cli --no-auto-start activate-pane --pane-id 7" }
        )
    ) $"switch result ($switched)"

    do $reset
    let sent = "typed text" | do $ty [pane send 3]
    do $check (
        ($sent.stdout | from json) == {version: "sysinit.ty/v1", action: "pane.send", pane_id: "3"} and not (do $calls | any {|c| $c | str contains "--no-paste" })
    ) $"send without submit ($sent)"
    do $reset
    let submitted = (do $ty [
        pane
        send
        --submit
        3
        hello
        world
    ])
    # `lines` drops a trailing carriage return, so check the raw log for it.
    do $check (
        (
            do $calls
            | last
            | str starts-with "wezterm cli --no-auto-start send-text --no-paste --pane-id 3"
        ) and (open --raw $log | str contains "--pane-id 3 \r")
    ) "submit did not press Enter"

    let read = (do $ty [pane read 5])
    (do
        $check
        ($read.stdout == "raw\ntext")
        $"read altered the pane text: ($read.stdout)"
    )

    do $reset
    let split = (do $ty [
        pane
        split
        5
        --direction
        right
        --cwd
        /tmp
    ])
    do $check (
        ($split.stdout | from json) == {version: "sysinit.ty/v1", action: "pane.split", pane_id: "42"} and (do $calls | last) == "wezterm cli --no-auto-start split-pane --pane-id 5 --right --cwd /tmp"
    ) $"split ($split)"
    do $reset
    let spawned = (do $ty [
        pane
        spawn
        5
        --direction
        down
        --
        echo
        "two words"
    ])
    do $check (
        (do $calls | last) == "wezterm cli --no-auto-start split-pane --pane-id 5 --bottom -- echo two words" and ($spawned.stdout | from json | get action) == "pane.spawn"
    ) $"spawn ($spawned)"

    for usage in [
        [pane read]
        [pane read -1]
        [pane focus x]
        [pane split 5 --direction left]
        [pane spawn 5 --direction right]
        [session open]
        [nonsense]
    ] {
        let result = (do $ty $usage)
        (do
            $check
            ($result.exit_code == 2)
            $"($usage | str join ' ') exited ($result.exit_code), want 2"
        )
    }
    let operational = (do $ty [pane focus 99])
    do $check (
        $operational.exit_code == 1 and ($operational.stderr | str contains "no such pane")
    ) $"operational error ($operational)"
    rm -rf $root
    print "ty passed"
}
