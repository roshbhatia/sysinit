use std/assert
use ./lib/process.nu with-fixture

def main [] {
    with-fixture {|root|
        let log = $root | path join service.log
        let policy = $root | path join logrotate.conf
        let state = $root | path join state
        let writer = $root | path join writer.nu

        $'($log) {
    size 1k
    rotate 3
    missingok
    notifempty
    copytruncate
}
' | save $policy

        'use std/assert

def main [log: path, policy: path, state: path] {
    let inode = ^stat --format=%i $log

    for _ in 1..5 {
        print --no-newline (1..1000 | each { "fixture\n" } | str join)

        let rotated = ^logrotate --state $state $policy | complete

        assert equal $rotated.exit_code 0 $rotated.stderr
        assert equal (^stat --format=%i $log) $inode
        assert equal (ls --long $log | first | get size) 0b
    }

    print "still logging"
}' | save $writer

        let written = ^$nu.current-exe --no-config-file $writer $log $policy $state out>> $log | complete

        assert equal $written.exit_code 0 $written.stderr

        assert equal (open --raw $log) "still logging\n"
        assert equal (glob ($root | path join 'service.log.*') | length) 3
    }

    print 'Log rotation preserves an open writer and retains three archives'
}
