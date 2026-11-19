use std/assert
use lib/process.nu with-fixture

def main [script: path] {
    with-fixture {|root|
        let gh = $root | path join gh
        let fixture = '#!NU
def --wrapped main [...args: string] {
    match $args.0 {
        pr => {
            {
                url: $args.2
                state: OPEN
                isDraft: false
                headRefOid: "abc123"
                reviewDecision: APPROVED
                mergeStateStatus: CLEAN
                statusCheckRollup: [{name: build, conclusion: SUCCESS}]
            } | to json --raw
        }
        api => {
            [{data: {repository: {pullRequest: {reviewThreads: {
                nodes: [{isResolved: false} {isResolved: true}]
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

            let watched = ^$nu.current-exe --no-config-file $script watch $url --interval 5ms --timeout 100ms | complete
            assert equal $watched.exit_code 8 $watched.stderr
            assert equal ($watched.stdout | lines | length) 1
            assert equal ($watched.stdout | from json | get head) abc123
        }
    }
}
