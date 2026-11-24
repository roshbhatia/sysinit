use std/assert
use ../lib/process.nu with-fixture

def main [script: path] {
    with-fixture {|root|
        let gh = $root | path join gh
        let fixture = '#!NU
def --wrapped main [...args: string] {
    match $args.0 {
        pr => {
            if $env.GH_AUDIT_SLOW? != null {
                sleep 2sec
                touch $env.GH_AUDIT_SLOW
            }
            {
                url: $args.2
                state: ($env.GH_FIXTURE_STATE? | default OPEN)
                isDraft: false
                headRefOid: "abc123"
                reviewDecision: APPROVED
                mergeStateStatus: CLEAN
                statusCheckRollup: [{name: build, conclusion: SUCCESS}]
            } | to json --raw
        }
        api => {
            [{data: {repository: {pullRequest: {reviewThreads: {
                nodes: [{isResolved: ($env.GH_FIXTURE_RESOLVED? == "yes")} {isResolved: true}]
            }}}}}] | to json --raw
        }
    }
}'
        $fixture | str replace NU $nu.current-exe | save $gh
        ^chmod +x $gh
        let url = 'https://github.com/owner/repo/pull/1'
        with-env {PATH: ($env.PATH | prepend $root)} {
            let rows = ^$nu.current-exe --no-config-file $script $url invalid $url | from json
            assert equal ($rows | length) 2
            assert equal $rows.0.head abc123
            assert equal $rows.0.unresolved_threads 1
            assert equal $rows.0.ready false
            assert equal $rows.0.checks.0.state SUCCESS
            assert ($rows.1.error | str contains canonical)

            let watched = ^$nu.current-exe --no-config-file $script watch $url --interval 1sec --timeout 500ms | complete
            assert equal $watched.exit_code 8 $watched.stderr
            assert equal ($watched.stdout | lines | length) 1
            assert equal ($watched.stdout | from json | get head) abc123

            with-env {GH_FIXTURE_RESOLVED: yes} {
                let ready = ^$nu.current-exe --no-config-file $script watch $url --timeout 500ms | complete
                assert equal $ready.exit_code 0 $ready.stderr
                let waiting = ^$nu.current-exe --no-config-file $script watch $url --until closed --timeout 500ms | complete
                assert equal $waiting.exit_code 8 $waiting.stderr
            }
            with-env {GH_FIXTURE_STATE: MERGED} {
                let merged = ^$nu.current-exe --no-config-file $script watch $url --until closed | from json
                assert equal $merged.state MERGED
            }

            let invalid = ^$nu.current-exe --no-config-file $script watch invalid | complete
            assert equal $invalid.exit_code 1
            assert ($invalid.stderr | str contains canonical)

            let finished = $root | path join slow-call-finished
            let slow = with-env {GH_AUDIT_SLOW: $finished} {
                ^$nu.current-exe --no-config-file $script watch $url --timeout 250ms | complete
            }
            assert equal $slow.exit_code 8 $slow.stderr
            assert (not ($finished | path exists))
        }
    }
}
