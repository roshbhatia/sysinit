use std/assert

def main [nh: path, fixture: path] {
    let root = mktemp --directory | path expand --strict
    try {
        let bin = $root | path join bin
        let target = $root | path join built-system
        mkdir $bin ($target | path join sw bin)
        '{}' | save ($root | path join flake.nix)
        for entry in [
            {
                name: nix
                path: ($bin | path join nix)
            }
            {
                name: elevate
                path: ($bin | path join elevate)
            }
            {
                name: darwin-rebuild
                path: ($target | path join sw bin darwin-rebuild)
            }
        ] {
            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.NH_TEST_COMMAND = "($entry.name)"' + "\n" + (open --raw $fixture)
            ) | save $entry.path
            ^chmod 700 $entry.path
        }
        let log = $root | path join commands.jsonl
        cd $root
        with-env {PATH: ($env.PATH | prepend $bin), NH_TEST_LOG: $log, NH_TEST_TARGET: $target} {
            for case in [
                {name: relative, output: result-system, fail: false}
                {name: absolute, output: ($root | path join absolute-result), fail: false}
                {name: temporary, output: null, fail: false}
                {name: failed-build, output: failed-result, fail: true}
            ] {
                '' | save --force $log
                let arguments = [darwin switch '.#fixture' --hostname fixture --no-nom --diff never --elevation-strategy ($bin | path join elevate)]
                    | append (if $case.output == null { [] } else { [--out-link $case.output] })
                let result = with-env {NH_TEST_FAIL: (if $case.fail { '1' } else { '' })} { ^$nh ...$arguments | complete }
                let commands = open --raw $log | lines | each { from json }
                let profiles = $commands | where {|command| $command.0 == nix and '--profile' in $command}
                let activations = $commands | where {|command| $command.0 == darwin-rebuild}
                if $case.fail {
                    assert ($result.exit_code != 0) $case.name
                    assert ($profiles | is-empty)
                    assert ($activations | is-empty)
                } else {
                    assert equal $result.exit_code 0 ($result.stdout + $result.stderr)
                    assert equal ($profiles | length) 1 $case.name
                    assert equal ($activations | length) 1 $case.name
                }
                print $'($case.name): passed'
            }
        }
    } catch {|failure|
        cd ($root | path dirname)
        rm --recursive --force $root
        error make $failure
    }
    cd ($root | path dirname)
    rm --recursive --force $root
}
