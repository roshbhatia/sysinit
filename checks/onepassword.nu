use std/assert

def invoke [module: path, command: string] {
    ^$nu.current-exe --no-config-file -c $'use ($module | to json --raw) *; ($command)' | complete
}

def main [module: path, fixture: path] {
    let root = mktemp --directory
    try {
        for name in [op pbcopy] {
            let path = $root | path join $name
            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.OP_TEST_COMMAND = "($name)"' + "\n" + (open --raw $fixture)
            ) | save $path
            ^chmod 700 $path
        }
        let log = $root | path join calls.jsonl
        let clipboard = $root | path join clipboard
        with-env {PATH: ($env.PATH | prepend $root), OP_TEST_LOG: $log, OP_TEST_CLIPBOARD: $clipboard} {
            let found = invoke $module 'op-find EXAMPLE --account test --vault Test | to json'
            assert equal $found.exit_code 0 $found.stderr
            assert equal ($found.stdout | from json | first | get id) item123
            let reference = invoke $module 'op-ref Example --field username'
            assert equal ($reference.stdout | str trim) 'op://vault123/item123/username'
            let copied = invoke $module 'op-copy Example --account test'
            assert equal $copied.exit_code 0 $copied.stderr
            assert not (($copied.stdout + $copied.stderr) | str contains synthetic-password)
            assert equal (open --raw $clipboard) "  synthetic-password\n"
            let otp = invoke $module 'op-copy Example --otp'
            assert equal $otp.exit_code 0 $otp.stderr
            let calls = open --raw $log | lines | each { from json }
            for expected in [
                [item list --format json --account test --vault Test]
                [read 'op://vault123/item123/password' --no-newline --account test]
                [read 'op://vault123/item123/one-time password?attribute=otp' --no-newline]
            ] { assert ($expected in $calls) }
            let previous = open --raw $clipboard
            with-env {OP_TEST_FAIL: '1'} {
                let failed = invoke $module 'op-copy Example'
                assert ($failed.exit_code != 0)
                assert not (($failed.stdout + $failed.stderr) | str contains 'sensitive diagnostic')
                assert equal (open --raw $clipboard) $previous
            }
            let missing = invoke $module 'op-copy absent'
            assert ($missing.exit_code != 0)
            assert equal (open --raw $clipboard) $previous
            with-env {OP_TEST_EXIT: '7'} {
                let child = invoke $module 'op-with refs.env echo "two words"; exit $env.LAST_EXIT_CODE'
                assert equal $child.exit_code 7 $child.stderr
            }
            let calls = open --raw $log | lines | each { from json }
            assert ([run --env-file refs.env -- echo 'two words'] in $calls)
        }
    } catch {|failure|
        rm --recursive --force $root
        error make $failure
    }
    rm --recursive --force $root
    print '1Password metadata, references, clipboard, OTP, errors, and child status checks passed'
}
