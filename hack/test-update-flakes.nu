use std/assert

def main [script: path, fixture: path] {
    let root = mktemp --directory | path expand --strict
    try {
        let bin = $root | path join bin
        mkdir $bin ($root | path join extras)
        for command in [gh nix] {
            let path = $bin | path join $command
            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.UPDATE_FIXTURE_COMMAND = "($command)"' + "\n" + (open --raw $fixture)
            ) | save $path
            ^chmod 700 $path
        }
        ^git init --quiet $root
        let outer = $root | path join flake.nix
        let inner = $root | path join extras flake.nix
        '"github:owner/tool/v1.0.0?dir=extras" "github:owner/tool/main"' | save $outer
        $'"github:owner/tool/('a' | fill --width 40 --character a)"' | save $inner
        ^git -C $root add flake.nix extras/flake.nix
        let log = $root | path join commands.jsonl
        with-env {PATH: ($env.PATH | prepend $bin), UPDATE_FIXTURE_LOG: $log, UPDATE_FIXTURE_MODE: releases} {
            let result = ^$nu.current-exe --no-config-file $script --root $root | complete
            assert equal $result.exit_code 0 $result.stderr
            assert equal (open --raw $outer) '"github:owner/tool/v2.0.0?dir=extras" "github:owner/tool/main"'
            assert equal (open --raw $inner) $'"github:owner/tool/('b' | fill --width 40 --character b)"'
            let calls = open --raw $log | lines | each { from json }
            assert equal ($calls | where command == nix | get cwd) [$root ($root | path join extras)]
        }
        for case in [
            {current: v2.0.0, expected: v2.1.0}
            {current: v4.0.0, expected: v4.0.0}
        ] {
            $'"github:owner/tool/($case.current)"' | save --force $outer
            with-env {PATH: ($env.PATH | prepend $bin), UPDATE_FIXTURE_LOG: $log, UPDATE_FIXTURE_MODE: tags} {
                let result = ^$nu.current-exe --no-config-file $script --root $root | complete
                assert equal $result.exit_code 0 $result.stderr
                assert equal (open --raw $outer) $'"github:owner/tool/($case.expected)"'
            }
        }
        let before = open --raw $outer
        with-env {PATH: ($env.PATH | prepend $bin), UPDATE_FIXTURE_LOG: $log, UPDATE_FIXTURE_MODE: releases, UPDATE_FIXTURE_FAIL: gh} {
            let result = ^$nu.current-exe --no-config-file $script --root $root | complete
            assert ($result.exit_code != 0)
            assert equal (open --raw $outer) $before
        }
    } catch {|failure|
        rm --recursive --force $root
        error make $failure
    }
    rm --recursive --force $root
    print 'Flake updater checks passed'
}
