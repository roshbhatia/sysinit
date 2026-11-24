use std/assert
use ../lib/carapace.nu
use ../lib/process.nu with-fixture

def main [
    bridge: path
    pueue: path
    alias_spec: path
    queue_spec: path
    tasks: path
] {
    with-fixture {|root|
        let configuration = $root | path join .config

        carapace install $configuration $bridge {
            'pueue.yaml': $pueue
            'tq.yaml': $alias_spec
            'task-queue.yaml': $queue_spec
        }

        with-env {HOME: $root, XDG_CONFIG_HOME: $configuration} {
            carapace check-completion pueue [add --sta] '--stashed'
            carapace check-completion tq [submit --ter] '--terminal'
            carapace check-completion task-queue [submit --ter] '--terminal'
        }

        assert ((^task-queue) | str starts-with 'Usage: task-queue ')
        assert equal (^tq) (^task-queue)
        let data = $root | path join task
        mkdir $data
        let taskrc = $root | path join taskrc
        '' | save $taskrc
        with-env {TASKRC: $taskrc, TASKDATA: $data, XDG_STATE_HOME: ($root | path join state)} {
            let state = $root | path join empty-queue
            let queue = ^nu --no-config-file -c $'use ($tasks); tasks queue --state ($state) | to json --raw' | from json
            let board = ^nu --no-config-file -c $'use ($tasks); tasks board --all --context none | to json --raw' | from json
            assert equal $queue []
            assert equal $board (^task-board --all --context none --json | from json)
            assert equal $board (^tb --all --context none --json | from json)
        }
    }
}
