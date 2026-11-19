use std/assert
use ./lib/process.nu [checked-command with-fixture]

def main [configuration: path, rules: path, wrapper: path] {
    let root = $env.TMPDIR | path join config ast-grep

    mkdir $root

    checked-command ln -s $configuration ($root | path join sgconfig.yml) | ignore

    checked-command ln -s $rules ($root | path join rules) | ignore

    with-fixture {|fixture|
        let source = $fixture | path join impure.nix

        "builtins.currentTime\n" | save $source

        let rejected = ^$wrapper --json $fixture | complete

        assert equal $rejected.exit_code 1
        assert ($rejected.stdout | from json | any {|finding| $finding.ruleId == nix-impure-eval })

        "{ answer = 42; }\n" | save --force $source
        checked-command $wrapper $fixture | ignore
    }
}
