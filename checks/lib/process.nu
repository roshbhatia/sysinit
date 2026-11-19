use std/assert

export def --wrapped checked-command [command: string, ...arguments: string] {
    let result = ^timeout 30s $command ...$arguments | complete

    assert equal $result.exit_code 0 $result.stderr

    $result.stdout
}

export def with-fixture [body: closure] {
    let root = ^mktemp -d '/tmp/sysinit-check.XXXXXX' | str trim

    try {
        do $body $root
    } catch {|failure|
        rm --recursive $root

        error make $failure
    }

    rm --recursive $root
}
