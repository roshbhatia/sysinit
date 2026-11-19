def --wrapped main [...arguments: string] {
    if $env.OP_TEST_COMMAND == pbcopy {
        ^cat out> $env.OP_TEST_CLIPBOARD

        return
    }

    (($arguments | to json --raw) + "\n") | save --append $env.OP_TEST_LOG

    if ($arguments | take 2) == [item list] {
        [
            {
                id: item123
                title: 'Example Login'
                vault: {id: vault123, name: Test}
                category: LOGIN
            }
        ] | to json | print
    } else if $arguments.0 == read {
        if ($env.OP_TEST_FAIL? | default '') != '' {
            print --stderr 'sensitive diagnostic'

            exit 1
        }

        print --no-newline "  synthetic-password\n"
    } else if $arguments.0 == run {
        exit ($env.OP_TEST_EXIT? | default '0' | into int)
    } else {
        exit 2
    }
}
