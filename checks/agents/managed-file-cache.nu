use std/assert

def main [runner: path, cache_tool: path] {
    let directory = mktemp -d

    let failure = try {
        let target = $directory | path join .config/test.json

        let base = $directory | path join .config/.test.json.nix-base

        let cache = $"($base).cache"

        let run = {||
            with-env {HOME: $directory} { ^$runner | complete }
        }

        assert equal (do $run | get exit_code) 0

        assert ($cache | path exists)

        let other = $directory | path join .config/other.json

        let stamp = ls --long $target | get 0.modified

        let other_stamp = ls --long $other | get 0.modified

        assert equal (do $run | get exit_code) 0

        assert equal (ls --long $target | get 0.modified) $stamp

        {owned: false, custom: 7, retired: true} | to json | save --force $target

        assert equal (do $run | get exit_code) 0

        assert equal (open $target) {owned: true custom: 7}

        assert equal (ls --long $other | get 0.modified) $other_stamp

        open --raw $base | from json | upsert hooks {PreToolUse: [managed] Stop: [managed]} | to json | save --force $base

        open $target
        | upsert hooks {PreToolUse: [managed] Stop: [custom] state: {trusted: true}}
        | to json
        | save --force $target

        assert equal (do $run | get exit_code) 0

        assert equal (open $target | get hooks) {Stop: [custom] state: {trusted: true}}

        let previous_cache = open --raw $cache

        'invalid' | save --force $target

        assert ((do $run | get exit_code) != 0)

        assert equal (open --raw $target) invalid

        assert equal (open --raw $cache) $previous_cache

        rm $target

        assert equal (do $run | get exit_code) 0

        rm $target

        let foreign = $directory | path join foreign

        '{"owned": false}' | save $foreign

        ^ln -s $foreign $target

        assert ((do $run | get exit_code) != 0)

        assert equal (open --raw $foreign) '{"owned": false}'

        let inputs = [target base declared schema] | each {|name| $directory | path join $name }

        for file in $inputs {
            'initial' | save --force $file
        }

        let state = $directory | path join cache

        let cache_run = {|operation, policy|
            ^$nu.current-exe --no-config-file $cache_tool $operation $state ...$inputs $policy | complete | get exit_code
        }

        assert equal (do $cache_run record v1) 0

        assert equal (do $cache_run check v1) 0

        assert equal (do $cache_run check v2) 1

        for file in $inputs {
            'changed' | save --force $file

            assert equal (do $cache_run check v1) 1

            'initial' | save --force $file
        }

        'corrupt' | save --force $state

        assert equal (do $cache_run check v1) 1

        0x[ff000aff] | save --force $inputs.0

        assert equal (do $cache_run record v1) 0

        assert equal (do $cache_run check v1) 0

        null
    } catch {|error|
        $error
    }

    rm --recursive $directory

    if $failure != null { error make {msg: $failure.msg} }

    print 'Managed file cache checks passed'
}
