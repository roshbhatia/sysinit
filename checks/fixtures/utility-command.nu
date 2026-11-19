def --wrapped main [...arguments: string] {
    match $env.UTILITY_TEST_COMMAND {
        wezterm => {
            if ($env.UTILITY_TEST_CONNECT_FAIL? | default '') != '' {
                print --stderr 'fixture failure'

                exit 23
            }

            print --no-newline snapshot
        }
        sudo => {
            (($arguments | str join ' ') + "\n") | save --append $env.CALLS

            exit ($env.FAIL? | default '0' | into int)
        }
        ask => { sleep 10sec }
        fd => { print --no-newline ($env.SELECTED + (char nul)) }
        fzf => {
            ^cat | ignore

            print --no-newline ($env.SELECTED + (char nul))

            exit ($env.PICKER_EXIT | into int)
        }
        osascript => {
            $arguments.2 | save --force $env.CALLS

            exit ($env.APPLY_EXIT | into int)
        }
        gh => { }
        chafa => { }
    }
}
