use std/assert

def reconcile [script: path, root: path] {
    ^bash $script ($root | path join state) ($root | path join snapshot) ($root | path join check) ($root | path join reconcile) | complete
}

def main [script: path, fixture: path] {
    for mode in [overlap drift] {
        let root = mktemp --directory
        try {
            for command in [snapshot check reconcile] {
                let path = $root | path join $command
                (
                    $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.BREW_TEST_COMMAND = "($command)"' + "\n" + (open --raw $fixture)
                ) | save $path
                ^chmod 700 $path
            }
            with-env {BREW_TEST_ROOT: $root, BREW_TEST_MODE: $mode} {
                if $mode == overlap {
                    let result = reconcile $script $root
                    assert equal $result.exit_code 0 $result.stderr
                    assert equal (open --raw ($root | path join state)) "inventory\n"
                } else {
                    let inventory = $root | path join inventory
                    let state = $root | path join state
                    let count = $root | path join count
                    "v1\n" | save $inventory
                    for iteration in 1..2 {
                        let result = reconcile $script $root
                        assert equal $result.exit_code 0 $result.stderr
                    }
                    assert equal (open --raw $count | lines) [run]
                    touch ($root | path join missing)
                    assert equal (reconcile $script $root | get exit_code) 0
                    assert not ($root | path join missing | path exists)
                    "v2\n" | save --force $inventory
                    assert equal (reconcile $script $root | get exit_code) 0
                    assert equal (open --raw $count | lines | length) 3
                    let previous = open --raw $state
                    "v3\n" | save --force $inventory
                    touch ($root | path join failure)
                    assert ((reconcile $script $root | get exit_code) != 0)
                    assert equal (open --raw $state) $previous
                    rm ($root | path join failure)
                    assert equal (reconcile $script $root | get exit_code) 0
                    assert equal (^stat --format=%a $state | str trim) '600'
                }
            }
        } catch {|failure|
            rm --recursive --force $root
            error make $failure
        }
        rm --recursive --force $root
    }
    print 'Homebrew concurrency, drift, failure, and state checks passed'
}
