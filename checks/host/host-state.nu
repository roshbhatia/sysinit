use std/assert

def main [helper: path] {
    let root = mktemp -d | path expand --strict

    try {
        with-env {HOME: $root, GIT_CONFIG_GLOBAL: /dev/null, GIT_CONFIG_NOSYSTEM: '1'} {
            let repo = $root | path join host
            mkdir $repo
            ^git init -q $repo
            ^git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty -qm 'Initial fixture'
            {nodes: {sysinit: {locked: {rev: source-revision}}, root: {inputs: {}}}} | to json | save ($repo | path join flake.lock)
            let prepared = $root | path join system
            let other = $root | path join other
            mkdir $prepared $other
            let shell = $nu.current-exe
            let active = $root | path join active
            ^ln -s $prepared $active
            with-env {HOST_FIXTURE: $repo, HOST_PREPARED: $prepared, HOST_ACTIVE: $active} {
                let command = 'use ' + ($helper | to nuon) + ' inspect; inspect $env.HOST_FIXTURE $env.HOST_PREPARED $env.HOST_ACTIVE | to json'
                let state = ^$shell --no-config-file --commands $command | from json
                assert equal $state.matches true
                assert equal $state.active $prepared
            }
            let result = ^$shell --no-config-file $helper --flake $repo | from json
            assert equal $result.pins.sysinit source-revision
            assert equal ($result.pins | columns) [sysinit]
            assert equal ($result.changes | length) 1
            assert equal ($result.revision | str length) 40
            let mismatch = ^$shell --no-config-file $helper --flake $repo --result $other | complete
            assert equal $mismatch.exit_code 1
            assert equal ($mismatch.stdout | from json | get matches) false
            let missing = ^$shell --no-config-file $helper --flake ($root | path join absent) | complete
            assert ($missing.exit_code != 0)
            let failed = ^$shell --no-config-file $helper --flake $other | complete
            assert ($failed.exit_code != 0)
        }
    } catch {|failure|
        rm -rf $root

        error make $failure
    }

    rm -rf $root

    print 'host-state checks passed'
}
