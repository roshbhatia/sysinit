use std/assert

def main [manifest: path] {
    let probes = open $manifest

    let root = $env.TMPDIR

    let environment = {
        HOME: ($root | path join home)
        XDG_CONFIG_HOME: ($root | path join config)
        XDG_DATA_HOME: ($root | path join data)
        XDG_CACHE_HOME: ($root | path join cache)
        XDG_STATE_HOME: ($root | path join state)
    }

    mkdir ...($environment | values)

    for entry in ($probes.files | transpose destination source) {
        mkdir ($entry.destination | path dirname)

        cp $entry.source $entry.destination
    }

    with-env $environment {
        for command in $probes.commands {
            let result = ^timeout 180s $command.0 ...($command | skip 1) | complete

            if $result.stdout != '' {
                print --no-newline $result.stdout
            }

            if $result.stderr != '' {
                print --stderr --no-newline $result.stderr
            }

            assert equal $result.exit_code 0 $'Probe failed: ($command | str join " ")'
        }
    }
}
