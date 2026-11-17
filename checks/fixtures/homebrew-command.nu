use std/assert

def wait-for [path: path] {
    let deadline = (date now) + 3sec
    while not ($path | path exists) {
        assert ((date now) < $deadline) $'timed out waiting for ($path)'
        sleep 10ms
    }
}

def main [] {
    cd $env.BREW_TEST_ROOT
    if $env.BREW_TEST_MODE == overlap {
        match $env.BREW_TEST_COMMAND {
            snapshot => {
                touch snapshot-started
                wait-for check-started
                print inventory
            }
            check => {
                if ('fixed' | path exists) { return }
                touch check-started
                wait-for snapshot-started
                sleep 100ms
                touch check-finished
                exit 1
            }
            reconcile => {
                assert ('check-finished' | path exists)
                touch fixed
            }
        }
    } else {
        match $env.BREW_TEST_COMMAND {
            snapshot => {
                open --raw inventory | print --no-newline $in
            }
            check => {
                if ('missing' | path exists) { exit 1 }
            }
            reconcile => {
                if ('failure' | path exists) { exit 1 }
                "run\n" | save --append count
                rm --force missing
            }
        }
    }
}
