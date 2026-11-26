def main --wrapped [tool: string, ...arguments: string] {
    let input = $in

    let root = $env.REVIEW_FIXTURE

    match $tool {
        gh => {
            ($arguments | to json --raw) + "\n" | save --append ($root | path join gh-calls)

            if $arguments.0 == auth {
                print fixture-token
            } else if $arguments.0 == api {
                let revisions = open ($root | path join revisions.json)

                if ($arguments.1 | str contains /compare/) {
                    {
                        merge_base_commit: {sha: $revisions.base}
                    } | to json --raw | print
                } else {
                    {
                        base: {sha: $revisions.base}
                        head: {sha: $revisions.head}
                    } | to json --raw | print
                }
            }
        }
        ask => {
            "call\n" | save --append ($root | path join ask-calls)

            print $env.ASK_RESPONSE

            exit ($env.ASK_EXIT? | default '0' | into int)
        }
        provider => {
            {
                envelope: ($input | from json --strict)
                arguments: $arguments
            } | to json --raw | print

            exit ($env.PROVIDER_EXIT? | default '0' | into int)
        }
        changes => {
            {
                files: (^git diff --cached --name-only)
                head: (^git rev-parse HEAD | str trim)
            } | to json | save --force observed.json
        }
        hunk => {
            {
                arguments: $arguments
                authenticated: ($env.GH_TOKEN? == fixture-token)
                explicit: $env.GITHUB_TOKEN?
            } | to json | save --force hunk.json

            exit ($env.HUNK_EXIT? | default '0' | into int)
        }
        nvim => {
            if '--headless' in $arguments {
                let expression = $arguments | last

                if $env.RPC_FAIL? == '1' { exit 1 }

                match $expression {
                    'getcwd()' => { print $env.DIFF_ROOT }
                    $expression if ($expression | str contains 'get_current_view()') => {
                        print (if ($root | path join diffview-inactive | path exists) { 0 } else { 1 })
                    }
                    $expression if ($expression | str contains '.select_review(') => {
                        if ($expression | str contains '"refresh":true') {
                            touch ($root | path join review-refreshed)
                        }

                        print 1
                    }
                    $expression if ($expression | str contains '.jump(_A.position, _A.review)') => {
                        $expression | save --force ($root | path join source-jump.txt)

                        print 1
                    }
                    "execute('checktime | DiffviewRefresh')" => {
                        touch ($root | path join refreshed)
                    }
                    'getpid()' => { print 123 }
                    _ => { exit 1 }
                }
            } else {
                $arguments | to json | save --force editor.json
            }
        }
        wezterm => {
            let action = $arguments.2

            match $action {
                list-clients => { print '[{"client_id":1}]' }
                list => {
                    open ($root | path join panes.json) | to json --raw | print
                }
                spawn => {
                    $arguments | to json | save --force ($root | path join spawn.json)

                    open ($root | path join panes.json) | append {pane_id: 9, tab_id: 3, cwd: ''} | to json | save --force ($root | path join panes.json)

                    print 9
                }
                send-text => {
                    $input | save --force ($root | path join paste.txt)
                }
                split-pane => {
                    $arguments | to json | save --force ($root | path join split.json)

                    let index = (
                        $arguments
                        | enumerate
                        | where item == --listen
                        | first
                        | get index
                    ) + 1

                    touch ($arguments | get $index)

                    open ($root | path join panes.json) | append {pane_id: 8, tab_id: 2} | to json | save --force ($root | path join panes.json)

                    print 8
                }
                activate-pane => {
                    $arguments | to json | save --force ($root | path join activation.json)
                }
                zoom-pane => {
                    $arguments | to json | save --force ($root | path join zoom.json)
                }
            }
        }
        lock => {
            touch ($root | path join lock-ready)

            while not ($root | path join lock-release | path exists) { sleep 10ms }
        }
    }
}
