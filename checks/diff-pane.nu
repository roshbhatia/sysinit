use std/assert

def main [script: path, fixture: path, ty: path] {
    let script = $script | path expand --strict

    let fixture = $fixture | path expand --strict

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    let bin = $root | path join bin

    let project = $root | path join project

    let plain = $root | path join 'plain directory'

    let ty_command = [
        'exec'
        ($nu.current-exe | to json --raw)
        '--no-config-file'
        ($ty | path expand --strict | to json --raw)
        '"$@"'
    ] | str join ' '

    mkdir $bin $project $plain

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
        with-env {PATH: ($env.PATH | prepend $bin), REVIEW_FIXTURE: $root, DIFF_ROOT: $project, WEZTERM_PANE: '7', XDG_STATE_HOME: ($root | path join state)} {
            ^git -C $project init --quiet '--template='
            [{pane_id: 7, tab_id: 2}] | to json | save ($root | path join panes.json)
            let opened = ^$nu.current-exe --no-config-file $script --cwd $project | complete
            assert equal $opened.exit_code 0 $opened.stderr
            assert ($opened.stdout | str starts-with Opened)
            let split = open ($root | path join split.json)
            assert equal ($split | last) DiffviewOpen
            assert ($split | window 2 | any {|pair| $pair == [--percent '45'] })
            assert ('--cmd' not-in $split)
            let reused = ^$nu.current-exe --no-config-file $script --cwd $project | complete
            assert equal $reused.exit_code 0 $reused.stderr
            assert ($reused.stdout | str starts-with Reused)
            assert ($root | path join refreshed | path exists)
            assert ($root | path join activation.json | path exists)
            open ($root | path join panes.json) | update 1 {pane_id: 8, tab_id: 3} | to json | save --force ($root | path join panes.json)
            let refused = ^$nu.current-exe --no-config-file $script --cwd $project | complete
            assert ($refused.exit_code != 0)
            assert ($refused.stderr | str contains 'outside this tab')
            let index = ($split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($split | get $index)

            let linked = $project | path join "linked file.lua"

            'before' | save $linked

            ^git -C $project add -- 'linked file.lua'

            ^git -C $project -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m fixture

            [{pane_id: 7, tab_id: 2}] | to json | save --force ($root | path join panes.json)

            let clean_link = ^$nu.current-exe --no-config-file $script --cwd $project --allow-directory --file $linked --line 2 --column 3 | complete
            assert equal $clean_link.exit_code 0 $clean_link.stderr

            let clean_split = open ($root | path join split.json)
            assert equal ($clean_split | last) $linked
            let clean_index = ($clean_split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($clean_split | get $clean_index)

            'after' | save --force $linked

            [{pane_id: 7, tab_id: 2}] | to json | save --force ($root | path join panes.json)

            let changed_link = ^$nu.current-exe --no-config-file $script --cwd $project --allow-directory --file $linked | complete
            assert equal $changed_link.exit_code 0 $changed_link.stderr

            let changed_split = open ($root | path join split.json)
            let diff_args = $changed_split | where {|arg| $arg | str starts-with 'SYSINIT_DIFFVIEW_ARGS=' } | first | str replace 'SYSINIT_DIFFVIEW_ARGS=' '' | from json
            assert equal $diff_args [HEAD -- ':(top,literal)linked file.lua']
            assert (($changed_split | last) | str ends-with '/source-view.lua')
            let changed_index = ($changed_split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($changed_split | get $changed_index)

            [{pane_id: 7, tab_id: 2}] | to json | save --force ($root | path join panes.json)
            let directory = with-env {DIFF_ROOT: $plain} {
                ^$nu.current-exe --no-config-file $script --pane-id 7 --cwd $plain --allow-directory | complete
            }
            assert equal $directory.exit_code 0 $directory.stderr
            let directory_split = open ($root | path join split.json)
            assert equal ($directory_split | last) $plain
            assert ('DiffviewOpen' not-in $directory_split)
            assert ($directory_split | any {|arg| $arg | str contains 'vim.cmd.Oil(vim.fn.getcwd())'})
            let socket_index = ($directory_split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($directory_split | get $socket_index)
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
