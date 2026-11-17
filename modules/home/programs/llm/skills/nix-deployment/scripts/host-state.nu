def git-output [source: path, ...arguments: string] {
    let response = ^timeout 15s git -C $source ...$arguments | complete
    if $response.exit_code != 0 { error make {msg: $response.stderr} }
    $response.stdout
}

export def inspect [flake: path, result?: path, active: path = /run/current-system] {
    let source = $flake | path expand --strict
    let revision = git-output $source rev-parse HEAD | str trim
    let changes = git-output $source status '--porcelain' | lines
    let lock = open --raw ($source | path join flake.lock) | from json
    let pins = $lock.nodes | transpose name node | where {|entry| 'locked' in $entry.node} | reduce --fold {} {|entry, pins|
        $pins | insert $entry.name ($entry.node.locked.rev? | default null)
    }
    let state = {
        flake: $source
        revision: $revision
        changes: $changes
        pins: $pins
        active: (
            if ($active | path exists) {
                $active | path expand --strict
            } else {
                null
            }
        )
    }
    if $result == null {
        $state
    } else {
        let prepared = $result | path expand --strict
        $state | merge {prepared: $prepared, matches: ($state.active == $prepared)}
    }
}

def main [--flake: path, --result: path] {
    let source = $flake | default ($env.NH_FLAKE? | default null)
    if $source == null { error make {msg: '--flake or NH_FLAKE is required'} }
    let state = inspect $source $result
    $state | to json | print
    if $state.matches? == false { exit 1 }
}
