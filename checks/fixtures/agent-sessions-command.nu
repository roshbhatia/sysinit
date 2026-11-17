use std/assert

def --wrapped main [...arguments: string] {
    if $env.AGENT_SESSION_TEST_COMMAND == wezterm {
        $arguments | to json | save --force ($env.FIXTURE | path join wezterm-args.json)
        assert equal $arguments [cli --no-auto-start list --format json]
        print $env.LIVE
        exit ($env.PROBE_EXIT? | default '0' | into int)
    }
    assert equal $arguments [list --names]
    print "session with spaces\nidle session"
}
