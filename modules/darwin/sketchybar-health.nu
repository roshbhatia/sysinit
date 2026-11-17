def command-output [binary: string, ...arguments: string] {
    let result = ^timeout 5s $binary ...$arguments | complete
    if $result.exit_code != 0 { error make {msg: $result.stderr} }
    $result.stdout
}

export def probe [sketchybar: string, now: int] {
    let bar = try {
        let parsed = command-output $sketchybar '--query' bar | from json
        if not ($parsed | describe | str starts-with record) { error make {msg: 'invalid bar response'} }
        $parsed
    } catch {|failure|
        return {
            reachable: false
            reason: $'bar query failed: ($failure.msg)'
        }
    }
    let items = $bar.items?
    if not ($items | describe | str starts-with list) or ($items | any {|item| ($item | describe) != string}) {
        return {reachable: true, reason: 'invalid widget list'}
    }
    if ([logo front_app clock battery sysinit_health] | any {|item| $item not-in $items}) {
        return {reachable: true, reason: 'required widgets are missing'}
    }
    let reason = try {
        let heartbeat = command-output $sketchybar '--query' sysinit_health | from json
        let age = $now - ($heartbeat.label.value | into int)
        if $age < 0 or $age > 90 { $'Lua heartbeat is stale (($age)s)' } else { '' }
    } catch {|failure|
        $'heartbeat query failed: ($failure.msg)'
    }
    {reachable: true, reason: $reason}
}

export def decide [
    previous: record
    now: int
    reason: string
    monitors
] {
    mut state = $previous
    if $now - ($state.last_check? | default $now) > 90 {
        $state = $state | merge {ready_at: ($now + 60), failures: 0}
    }
    $state = $state | merge {
        last_check: $now
        ready_at: ($state.ready_at? | default ($now + 60))
        failures: (if $reason != '' { ($state.failures? | default 0) + 1 } else { 0 })
    }
    let changed = $monitors != null and $monitors != $state.monitors?
    let action = if $now < $state.ready_at or $now - ($state.last_recovery? | default 0) < 120 {
        ''
    } else if $reason != '' and $state.failures >= 2 {
        $reason
    } else if $reason == '' and $changed {
        'monitor configuration changed'
    } else {
        ''
    }
    {state: $state, action: $action}
}

export def recover [
    sketchybar: string
    reachable: bool
    previous_reload: int
    now: int
    launchctl: string = /bin/launchctl
] {
    if $reachable and $now - $previous_reload >= 600 {
        try {
            command-output $sketchybar '--reload' | ignore
            return reload
        }
    }
    let uid = ^id -u | str trim
    (command-output
        $launchctl
        kickstart
        '-k'
        $'gui/($uid)/org.nixos.sketchybar'
    ) | ignore
    'restart'
}

def save-state [path: path, state: record] {
    let temporary = $path | path dirname | path join health.tmp
    ($state | to json) + "\n" | save --force $temporary
    mv --force $temporary $path
}

def main [--sketchybar: string, --rift-cli: string, --check] {
    if $sketchybar == null or $rift_cli == null { error make {msg: '--sketchybar and --rift-cli are required'} }
    let now = date now | format date '%s' | into int
    let health = probe $sketchybar $now
    if $check {
        print (
            if $health.reason == '' { 'SketchyBar is healthy' } else { $health.reason }
        )
        if $health.reason != '' { exit 1 }
        return
    }
    let cache = $env.XDG_CACHE_HOME? | default ($env.HOME | path join .cache)
    let path = $cache | path join sketchybar health.json
    mkdir ($path | path dirname)
    mut state = try {
        let loaded = open --raw $path | from json
        if not ($loaded | describe | str starts-with record) { error make {msg: 'invalid health state'} }
        $loaded
    } catch { {} }
    let monitors = try {
        let displays = command-output $rift_cli query displays | from json | get uuid | sort
        if ($displays | is-empty) { null } else { $displays }
    } catch {|failure|
        print $'Monitor query failed: ($failure.msg)'
        null
    }
    let decision = decide $state $now $health.reason $monitors
    $state = $decision.state
    if $decision.action != '' {
        let previous_reload = if $health.reason != '' {
            $state.last_reload? | default 0
        } else {
            0
        }
        $state = $state | merge {last_recovery: $now, failures: 0}
        save-state $path $state
        let result = recover $sketchybar $health.reachable $previous_reload $now
        if $result == reload { $state = $state | upsert last_reload $now }
        if $monitors != null { $state = $state | upsert monitors $monitors }
        print $'SketchyBar ($result): ($decision.action)'
    } else if $monitors != null and 'monitors' not-in $state {
        $state = $state | insert monitors $monitors
    }
    save-state $path $state
}
