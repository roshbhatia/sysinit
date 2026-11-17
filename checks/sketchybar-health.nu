use std/assert
use ../modules/darwin/sketchybar-health.nu [probe decide recover]

const helper = path self | path dirname | path join ../modules/darwin/sketchybar-health.nu
const fixture = path self | path dirname | path join fixtures/sketchybar-command.nu

def step [
    state: record
    now: int
    reason: string
    monitors
    expected: string
] {
    let decision = decide $state $now $reason $monitors
    assert equal $decision.action $expected
    $decision.state
}

def main [] {
    mut state = step {} 1000 bad [display] ''
    $state = step $state 1030 '' [display] ''
    $state = step $state 1060 bad [display] ''
    $state = step $state 1090 bad [display] bad
    $state = $state | insert last_recovery 1090
    $state = step $state 1120 bad [display] ''
    $state = step $state 1150 '' [display] ''
    assert equal $state.failures 0
    $state = step {
        last_check: 1000
        monitors: [display]
        ready_at: 0
    } 2000 stale null ''
    assert equal $state.monitors [display]
    $state = step $state 2030 '' null ''
    $state = step $state 2060 '' [display] ''
    step $state 2090 '' ['new display'] 'monitor configuration changed' | ignore
    let root = mktemp -d | path expand --strict
    try {
        let binary = $root | path join bar
        let shell = $nu.current-exe
        ($'#!($shell) --no-config-file' + "\n" + (open --raw $fixture)) | save $binary
        ^chmod 700 $binary
        let calls = $root | path join calls.jsonl
        let reloaded = $root | path join reloaded
        with-env {HEALTH_TEST_CALLS: $calls, HEALTH_TEST_RELOADED: $reloaded, HEALTH_TEST_HEARTBEAT: '1000', HEALTH_TEST_MODE: healthy, XDG_CACHE_HOME: $root} {
            assert equal (probe $binary 1050) {reachable: true, reason: ''}
            assert ((probe $binary 1100).reason | str contains stale)
            with-env {HEALTH_TEST_MODE: missing} {
                assert ((probe $binary 1050).reason | str contains missing)
            }
            with-env {HEALTH_TEST_MODE: invalid} {
                assert equal (probe $binary 1050).reachable false
            }
            with-env {HEALTH_TEST_MODE: timeout} {
                assert equal (probe $binary 1050).reachable false
            }
            assert equal (recover $binary true 0 1000 $binary) reload
            assert equal (open --raw $reloaded) reload
            assert equal (recover $binary true 1000 1200 $binary) restart
            assert equal (recover $binary false 0 2000 $binary) restart
            with-env {HEALTH_TEST_MODE: reload-failed} {
                assert equal (recover $binary true 0 2000 $binary) restart
            }
            assert (open --raw $calls | lines | last | str contains kickstart)
            let path = $root | path join sketchybar health.json
            mkdir ($path | path dirname)
            let now = date now | format date '%s' | into int
            {ready_at: 0, last_check: $now, failures: 1} | to json | save $path
            with-env {HEALTH_TEST_HEARTBEAT: '0'} {
                let first = ^$shell --no-config-file $helper --sketchybar $binary --rift-cli $binary | complete
                assert equal $first.exit_code 0 $first.stderr
                assert ($first.stdout | str contains 'reload: Lua heartbeat is stale')
                let second = ^$shell --no-config-file $helper --sketchybar $binary --rift-cli $binary | complete
                assert equal $second.exit_code 0 $second.stderr
                assert equal $second.stdout ''
                '' | save --force $path
                let reset = ^$shell --no-config-file $helper --sketchybar $binary --rift-cli $binary | complete
                assert equal $reset.exit_code 0 $reset.stderr
                assert ((open $path | get ready_at) > $now)
            }
            let before = open --raw $path
            with-env {HEALTH_TEST_HEARTBEAT: ($now | into string)} {
                let checked = ^$shell --no-config-file $helper --sketchybar $binary --rift-cli $binary --check | complete
                assert equal $checked.exit_code 0 $checked.stderr
                assert equal ($checked.stdout | str trim) 'SketchyBar is healthy'
                assert equal (open --raw $path) $before
            }
        }
    } catch {|failure|
        rm -rf $root
        error make $failure
    }
    rm -rf $root
    print 'SketchyBar health checks passed'
}
