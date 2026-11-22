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

    mkdir $bin

    $"#!/bin/sh\n($ty_command)\n" | save ($bin | path join ty)

    chmod +x ($bin | path join ty)

    for tool in [wezterm nvim] {
        let command = [
            'exec'
            ($nu.current-exe | to json --raw)
            '--no-config-file --stdin'
            ($fixture | to json --raw)
            $tool
            '"$@"'
        ] | str join ' '

        $"#!/bin/sh\n($command)\n" | save ($bin | path join $tool)

        chmod +x ($bin | path join $tool)
    }

    try {
        with-env {PATH: ($env.PATH | prepend $bin), REVIEW_FIXTURE: $root, DIFF_ROOT: $root, WEZTERM_PANE: '7', XDG_STATE_HOME: ($root | path join state)} {
            ^git -C $root init --quiet '--template='
            [{pane_id: 7, tab_id: 2}] | to json | save ($root | path join panes.json)
            let opened = ^$nu.current-exe --no-config-file $script --cwd $root | complete
            assert equal $opened.exit_code 0 $opened.stderr
            assert ($opened.stdout | str starts-with Opened)
            let split = open ($root | path join split.json)
            assert equal ($split | last) DiffviewOpen
            assert ('--cmd' not-in $split)
            let reused = ^$nu.current-exe --no-config-file $script --cwd $root | complete
            assert equal $reused.exit_code 0 $reused.stderr
            assert ($reused.stdout | str starts-with Reused)
            assert ($root | path join refreshed | path exists)
            assert ($root | path join activation.json | path exists)
            open ($root | path join panes.json) | update 1 {pane_id: 8, tab_id: 3} | to json | save --force ($root | path join panes.json)
            let refused = ^$nu.current-exe --no-config-file $script --cwd $root | complete
            assert ($refused.exit_code != 0)
            assert ($refused.stderr | str contains 'outside this tab')
            let index = ($split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($split | get $index)
        }
    } catch {|failure|
        # Remove only this fixture's recorded socket, never other active editors.
        if ($root | path join split.json | path exists) {
            let split = open ($root | path join split.json)

            let index = (
                $split
                | enumerate
                | where item == --listen
                | first
                | get index
            ) + 1

            rm --force ($split | get $index)
        }

        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'Diff creation, native flock, headless RPC, reuse, unborn HEAD and tab isolation passed'
}
