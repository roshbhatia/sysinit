use std/assert

def events [] {
    open --raw $env.DEFAULTS_TEST_EVENTS | lines | each { from json }
}

def main [helper: path, command: path] {
    let root = mktemp -d
    $env.DEFAULTS_TEST_STATE = $root | path join state.json
    $env.DEFAULTS_TEST_EVENTS = $root | path join events.jsonl
    {
        com.apple.dock: {size: 40, unmanaged: true}
    } | to json | save $env.DEFAULTS_TEST_STATE
    '' | save $env.DEFAULTS_TEST_EVENTS
    let imported = $helper | path expand
    let apply_script = $root | path join apply.nu
    ($'use ($imported) apply' + (char newline) + 'def main [inventory: path, command: path] {
  apply (open --raw $inventory | from json) --defaults $command --restart $command
}
') | save $apply_script
    let inventory = $root | path join desired.json
    let plugin = $env.DEFAULTS_TEST_PLUGIN
    let shell = $nu.current-exe
    let run = {|desired|
        $desired | to json | save --force $inventory
        ^$shell --no-config-file --plugins $plugin $apply_script $inventory $command | complete
    }
    let desired = [
        [
            com.apple.dock
            {size: 40}
        ]
        [
            new
            {enabled: false}
        ]
        [
            new
            {
                list: [1 two]
                nested: {label: 'a&b'}
            }
        ]
    ]
    let first = do $run $desired
    assert equal $first.exit_code 0 $first.stderr
    assert ($first.stdout | str contains 'updated 3 macOS defaults')
    let state = open --raw $env.DEFAULTS_TEST_STATE | from json
    assert equal $state.new {enabled: false, list: [1 two], nested: {label: 'a&b'}}
    assert equal (events | where operation == export | get domain) [com.apple.dock new]
    assert equal (events | where operation == restart | length) 0
    let repeated = do $run $desired
    assert equal $repeated.exit_code 0 $repeated.stderr
    assert ($repeated.stdout | str contains 'updated 0 macOS defaults')
    let dock = 'com.apple.dock'
    $state | upsert $dock (($state | get $dock) | upsert size 10) | to json | save --force $env.DEFAULTS_TEST_STATE
    let repaired = do $run $desired
    assert equal $repaired.exit_code 0 $repaired.stderr
    assert ($repaired.stdout | str contains 'updated 1 macOS defaults')
    assert equal (events | where operation == restart | length) 1
    let preserved = open --raw $env.DEFAULTS_TEST_STATE | from json | get $dock | get unmanaged
    assert $preserved
    let removed = do $run [
        [
            com.apple.dock
            {size: null, absent: null}
        ]
    ]
    assert equal $removed.exit_code 0 $removed.stderr
    assert ($removed.stdout | str contains 'updated 1 macOS defaults')
    let repeated_delete = do $run [
        [
            com.apple.dock
            {size: null, absent: null}
        ]
    ]
    assert equal $repeated_delete.exit_code 0 $repeated_delete.stderr
    assert ($repeated_delete.stdout | str contains 'updated 0 macOS defaults')
    for mode in [denied invalid] {
        let before = open --raw $env.DEFAULTS_TEST_STATE
        let count = events | length
        let result = with-env {DEFAULTS_TEST_READ_MODE: $mode} { do $run [[domain {key: 1}]] }
        assert ($result.exit_code != 0)
        assert equal (open --raw $env.DEFAULTS_TEST_STATE) $before
        assert equal ((events | skip $count | get operation)) [export]
    }
    let count = events | length
    let failed = with-env {DEFAULTS_TEST_WRITE_FAIL: 'true'} { do $run [[com.apple.dock {size: 40}]] }
    assert ($failed.exit_code != 0)
    assert equal ((events | skip $count | get operation)) [export]
    if ($env.DEFAULTS_NATIVE_CHECK? | default false | into bool) {
        let domain = $root | path join native-defaults
        ^/usr/bin/defaults write $domain unmanaged -bool true
        [
            [
                ($domain)
                {
                    size: 40
                    enabled: false
                    list: [1 two]
                    nested: {label: 'a&b'}
                }
            ]
        ] | to json | save --force $inventory
        let first = (^$shell --no-config-file --plugins $plugin $helper $inventory | complete)
        assert equal $first.exit_code 0 $first.stderr
        assert ($first.stdout | str contains 'updated 4 macOS defaults')
        let repeated = (^$shell --no-config-file --plugins $plugin $helper $inventory | complete)
        assert equal $repeated.exit_code 0 $repeated.stderr
        assert ($repeated.stdout | str contains 'updated 0 macOS defaults')
        let native = (^/usr/bin/defaults export $domain - | from plist)
        assert equal $native {unmanaged: true, size: 40, enabled: false, list: [1 two], nested: {label: 'a&b'}}
        [
            [
                ($domain)
                {size: null, absent: null}
            ]
        ] | to json | save --force $inventory
        let removed = (^$shell --no-config-file --plugins $plugin $helper $inventory | complete)
        assert equal $removed.exit_code 0 $removed.stderr
        assert ($removed.stdout | str contains 'updated 1 macOS defaults')
        let native = (^/usr/bin/defaults export $domain - | from plist)
        assert ('size' not-in ($native | columns))
        assert $native.unmanaged
        print 'native macOS defaults: typed writes, idempotence and deletion passed'
    }
    print 'incremental defaults: grouping, plist values, drift, removals, restart and failure boundaries passed'
}
