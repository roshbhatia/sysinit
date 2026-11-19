export def apply [entries: list<any>, --defaults: string = '/usr/bin/defaults', --restart: string = '/usr/bin/killall'] {
    let domains = ($entries | reduce --fold {} {|entry, domains|
    let domain = if ($entry.0 | str starts-with '~') { $entry.0 | path expand } else { $entry.0 }
    let previous = $domains | get -o $domain | default {}
    $domains | upsert $domain ($previous | merge $entry.1)
  })

    mut changed = 0

    mut dock_changed = false

    for domain in ($domains | columns) {
        let exported = (^$defaults export $domain - | complete)

        let current = if $exported.exit_code == 0 {
            $exported.stdout | from plist
        } else if ($exported.stderr + $exported.stdout | str contains 'does not exist') {
            {}
        } else {
            error make {msg: $exported.stderr}
        }

        let desired = $domains | get $domain

        for key in ($desired | columns) {
            let value = $desired | get $key

            let exists = $key in ($current | columns)

            if $exists and ($current | get $key) == $value { continue }

            let result = if $value == null {
                if not $exists { continue }

                ^$defaults delete $domain $key | complete
            } else {
                let payload = $value | to plist

                ^$defaults write $domain $key $payload | complete
            }

            if $result.exit_code != 0 { error make {msg: $result.stderr} }

            $changed += 1

            $dock_changed = $dock_changed or $domain == 'com.apple.dock'
        }
    }

    if $dock_changed {
        ^$restart -q Dock | complete | ignore
    }

    print $"sysinit: updated ($changed) macOS defaults"

    $changed
}

def main [inventory: path] {
    apply (open --raw $inventory | from json) | ignore
}
