def --wrapped main [...arguments: string] {
    ($arguments | to json --raw) + "\n" | save --append $env.HEALTH_TEST_CALLS

    let mode = $env.HEALTH_TEST_MODE? | default healthy

    match $arguments {
        ['--query', bar] => {
            if $mode == timeout { sleep 6sec }

            if $mode == invalid {
                print invalid

                return
            }

            let items = [logo front_app clock battery sysinit_health] | where {|item| $mode != missing or $item != clock}

            {items: $items} | to json | print
        }
        ['--query', sysinit_health] => {
            {
                label: {value: $env.HEALTH_TEST_HEARTBEAT}
            } | to json | print
        }
        [query, displays] => {
            [
                {uuid: display-1}
            ] | to json | print
        }
        ['--reload'] => {
            if $mode == reload-failed { exit 2 }

            'reload' | save --force $env.HEALTH_TEST_RELOADED
        }
        _ => { }
    }
}
