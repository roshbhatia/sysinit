use std/assert

def main [script: path, fixture: path, ty: path] {
    let script = if ($script | path type) == dir {
        $script | path join open.nu
    } else {
        $script
    } | path expand --strict

    let fixture = $fixture | path expand --strict

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    let bin = $root | path join bin

    let project = $root | path join project

    let plain = $root | path join 'plain directory'

    let home = $root | path join home

    let runtime = $root | path join runtime

    let gui_directory = if $nu.os-info.name == macos {
        $home | path join .local share wezterm
    } else {
        $runtime | path join wezterm
    }

    let alias_name = if $nu.os-info.name == macos { 'default-org.wezfurlong.wezterm' } else { 'x11-:0-org.wezfurlong.wezterm' }

    let socket = $gui_directory | path join gui-sock-fixture

    let other_socket = $gui_directory | path join gui-sock-other

    let ty_command = [
        'exec'
        ($nu.current-exe | to json --raw)
        '--no-config-file'
        ($ty | path expand --strict | to json --raw)
        '"$@"'
    ] | str join ' '

    mkdir $bin $project $plain $gui_directory

    touch $socket $other_socket

    ^ln -s $socket ($gui_directory | path join $alias_name)

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
        with-env {
            PATH: ($env.PATH | prepend $bin)
            REVIEW_FIXTURE: $root
            DIFF_ROOT: $project
            WEZTERM_PANE: '7'
            WEZTERM_UNIX_SOCKET: ''
            HOME: $home
            XDG_RUNTIME_DIR: $runtime
            XDG_STATE_HOME: ($root | path join state)
            DISPLAY: ':0'
        } {
            ^git -C $project init --quiet '--template='
            [{pane_id: 7, tab_id: 2}] | to json | save ($root | path join panes.json)
            let opened = ^$nu.current-exe --no-config-file $script --cwd $project --review | complete
            assert equal $opened.exit_code 0 $opened.stderr
            assert ($opened.stdout | str starts-with Opened)
            let split = open ($root | path join split.json)
            assert equal ($split | last) DiffviewOpen
            assert ('--right' in $split)
            assert ($split | window 2 | any {|pair| $pair == [--percent '45'] })
            assert ($split | window 2 | any {|pair| $pair == [--cmd 'let g:sysinit_pr_review = v:true'] })
            let reused = with-env {WEZTERM_UNIX_SOCKET: $socket} {
                ^$nu.current-exe --no-config-file $script --cwd $project | complete
            }
            assert equal $reused.exit_code 0 $reused.stderr
            assert ($reused.stdout | str starts-with Reused)
            assert ($root | path join refreshed | path exists)
            assert ($root | path join activation.json | path exists)
            let other = with-env {WEZTERM_UNIX_SOCKET: $other_socket} {
                ^$nu.current-exe --no-config-file $script --cwd $project --if-open | complete
            }
            assert equal $other.exit_code 0 $other.stderr
            assert equal ($other.stdout | str trim) ''
            touch ($root | path join diffview-inactive)
            let inactive = ^$nu.current-exe --no-config-file $script --cwd $project | complete
            assert ($inactive.exit_code != 0)
            assert ($inactive.stderr | str contains 'no active Diffview tab')
            rm ($root | path join diffview-inactive)
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

            let changed_link = ^$nu.current-exe --no-config-file $script --cwd $project --allow-directory --file $linked --line 4 | complete
            assert equal $changed_link.exit_code 0 $changed_link.stderr

            let changed_split = open ($root | path join split.json)
            assert (($changed_split | last) | str ends-with '.open_review()')
            assert (open --raw ($root | path join source-jump.txt) | str contains '"line":4')

            let second = $project | path join 'untracked.lua'
            'new file' | save $second
            let second_link = ^$nu.current-exe --no-config-file $script --cwd $project --allow-directory --file $second --json | complete
            assert equal $second_link.exit_code 0 $second_link.stderr
            assert ($second_link.stdout | from json | get reused)
            assert (open --raw ($root | path join source-jump.txt) | str contains 'untracked.lua')

            let review = ^$nu.current-exe --no-config-file $script --cwd $project | complete
            assert equal $review.exit_code 0 $review.stderr
            assert ($review.stdout | str starts-with Reused)
            let review_split = open ($root | path join split.json)
            assert (($review_split | last) | str ends-with '.open_review()')
            let review_retry = ^$nu.current-exe --no-config-file $script --cwd $project --review | complete
            assert equal $review_retry.exit_code 0 $review_retry.stderr
            assert ($root | path join review-refreshed | path exists)
            let review_index = ($review_split | enumerate | where item == --listen | first | get index) + 1
            rm --force ($review_split | get $review_index)

            [{pane_id: 7, tab_id: 2}] | to json | save --force ($root | path join panes.json)
            let directory = with-env {DIFF_ROOT: $plain} {
                ^$nu.current-exe --no-config-file $script --pane-id 7 --cwd $plain | complete
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

    print 'Diffview and Reviewr creation, native flock, headless RPC, reuse, unborn HEAD and tab isolation passed'
}
