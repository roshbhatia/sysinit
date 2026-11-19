def --wrapped main [...arguments: string] {
    if $env.NOTIFIER_TEST_COMMAND == focus {
        {args: $arguments, socket: $env.WEZTERM_UNIX_SOCKET?} | to json | save --force $env.NOTIFIER_CONTEXT

        return
    }

    $arguments | to json | save --force $env.NOTIFIER_ARGUMENTS

    if '-execute' in $arguments {
        let index = $arguments | enumerate | where item == '-execute' | first | get index

        let command = $arguments | get ($index + 1) | str substring 1..

        let result = ^/bin/sh -c $command | complete

        if $result.exit_code != 0 { error make {msg: $result.stderr} }
    }

    if '-action' in $arguments { print 'Open session' }
}
