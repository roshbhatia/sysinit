#!/usr/bin/env nu

const source_file = path self

def rift [...arguments: string] {
    let result = ^$env.RIFT_CLI ...$arguments | complete
    if $result.exit_code != 0 {
        error make {msg: $"rift-view: ($result.stderr | str trim)"}
    }
    $result.stdout
}

def query [...arguments: string] {
    rift query ...$arguments | from json
}
def execute [...arguments: string] {
    rift execute ...$arguments | ignore
}

def saved [] {
    if ($env.RIFT_VIEW_STATE | path exists) {
        open --raw $env.RIFT_VIEW_STATE | from json
    } else { null }
}

def save-state [state] {
    if $state == null {
        rm --force $env.RIFT_VIEW_STATE
    } else {
        let temporary = mktemp --tmpdir-path ($env.RIFT_VIEW_STATE | path dirname) .rift-view-XXXXXX
        $state | to json --raw | save --force $temporary
        mv --force $temporary $env.RIFT_VIEW_STATE
    }
}

def selected-path [node: record, window] {
    if $window == null { return [] }
    if $node.window_id? == $window { return [$node] }
    let children = $node.children? | default []
    let selected = $children | each {|child| selected-path $child $window } | flatten
    if ($selected | is-empty) {
        []
    } else {
        [$node] | append $selected
    }
}

def column [layout: record] {
    if $layout.mode != "scrolling" or $layout.selected_window == null { return null }
    $layout.container_tree.children
    | where {|node| $node.role? == "column" and (selected-path $node $layout.selected_window | is-not-empty) }
    | get -o 0
}

def gap [layout: record] {
    let config = rift execute config get | from json
    let gaps = $config.settings.layout.gaps
    let display = query displays | where space == $layout.space_id | get -o 0
    let override = $gaps.per_display? | default {} | get -o ($display.uuid? | default "") | default {}
    $override.inner?.horizontal? | default $gaps.inner.horizontal
}

def ratio [layout: record, selected: record, gap: float] {
    ($selected.frame.size.width + $gap) / ($layout.container_tree.frame.size.width + $gap)
}

def set-width [
    layout: record
    selected: record
    target: float
    gap: float
] {
    let amount = $target - (ratio $layout $selected $gap)
    if ($amount | math abs) > 0.000001 {
        execute window resize-by $"--amount=($amount | into string)"
    }
}

def fullscreen-flags [layout: record] {
    let nodes = selected-path $layout.container_tree $layout.selected_window
    [
        {flag: is_fullscreen, command: toggle-fullscreen}
        {
            flag: is_fullscreen_within_gaps
            command: toggle-fullscreen-within-gaps
        }
    ] | where {|item| $nodes | any {|node| $node | get -o $item.flag | default false } } | get command
}

def restore-reading [layout: record, --camera] {
    let state = saved
    let selected = column $layout
    if $state == null or $selected == null { return false }
    if $state.space_id != $layout.space_id or $state.workspace_id != $layout.workspace_id or $state.column_id != $selected.node_id {
        return false
    }
    let gap = gap $layout
    set-width $layout $selected $state.ratio $gap
    if $camera {
        let updated = query layout
        let restored = column $updated
        if $restored != null {
            let root = $updated.container_tree.frame
            let offset = $restored.frame.origin.x - $root.origin.x
            let delta = ($offset - $state.left * $root.size.width) / ($restored.frame.size.width + $gap)
            if ($delta | math abs) > 0.000001 {
                (execute
                    layout
                    scroll-strip
                    "--"
                    ($delta | into string)
                )
            }
        }
    }
    save-state null
    true
}

def reading [] {
    let layout = query layout
    if (restore-reading $layout --camera) { return }
    for command in (fullscreen-flags $layout) { execute window $command }
    let layout = query layout
    let selected = column $layout
    if $selected == null { return }
    let root = $layout.container_tree.frame
    let gap = gap $layout
    let ratio = ratio $layout $selected $gap
    save-state {
        space_id: $layout.space_id
        workspace_id: $layout.workspace_id
        column_id: $selected.node_id
        ratio: $ratio
        left: (($selected.frame.origin.x - $root.origin.x) / $root.size.width)
    }
    set-width $layout $selected ([
        $ratio
        (4 / 5)
    ] | math max) $gap
    execute layout center-selection
}

def focus [direction: string] {
    let before = query layout
    let fullscreen = fullscreen-flags $before
    let selected = column $before
    if $selected != null and $direction in [left right] {
        let columns = $before.container_tree.children
        let index = $columns | enumerate | where item.node_id == $selected.node_id | get 0.index
        if ($direction == left and $index > 0) or ($direction == right and $index + 1 < ($columns | length)) {
            restore-reading $before | ignore
        }
    }
    for command in $fullscreen { execute window $command }
    execute window focus $direction
    if ($fullscreen | is-not-empty) and (query layout | get selected_window) == $before.selected_window {
        for command in $fullscreen { execute window $command }
    }
}

def --env main [
    operation: string
    --rift-cli: string = "rift-cli"
    --state-dir: path
    --locked
    ...arguments: string
] {
    if $operation not-in [reading focus run layout toggle-scrolling] { error make {msg: "expected reading, focus, run, layout, or toggle-scrolling"} }
    if $operation == focus and ($arguments | length) != 1 { error make {msg: "focus requires a direction"} }
    if $operation == focus and ($arguments | get 0) not-in [left right up down] { error make {msg: "invalid focus direction"} }
    if $operation == run and ($arguments | is-empty) { error make {msg: "run requires a Rift execute command"} }
    if $operation == layout and ($arguments | length) not-in [1 2] { error make {msg: "layout requires a mode and optional orientation toggle"} }
    if $operation == layout and ($arguments | get 0) not-in [
        traditional
        scrolling
        stack
        bsp
        master_stack
        floating
    ] { error make {msg: "invalid layout mode"} }
    if $operation == layout and ($arguments | length) == 2 and $arguments.1 != "toggle-orientation" { error make {msg: "expected toggle-orientation"} }
    let directory = $state_dir | default (
        ($env.XDG_STATE_HOME? | default ($env.HOME | path join ".local/state"))
        | path join "rift"
    )
    mkdir $directory
    if not $locked {
        exec /usr/bin/lockf -k ($directory | path join "transient-view.lock") $nu.current-exe --no-config-file $source_file --locked --rift-cli $rift_cli --state-dir $directory -- $operation ...$arguments
    }
    $env.RIFT_CLI = $rift_cli
    $env.RIFT_VIEW_STATE = $directory | path join "transient-view.json"
    match $operation {
        reading => { reading }
        focus => { focus $arguments.0 }
        run => {
            restore-reading (query layout) | ignore
            execute ...$arguments
        }
        layout => {
            restore-reading (query layout) | ignore
            execute workspace set-layout $arguments.0
            if ($arguments | length) == 2 { execute layout toggle-orientation }
        }
        toggle-scrolling => {
            let before = query layout
            restore-reading $before | ignore
            (execute
                workspace
                set-layout
                (
                    if $before.mode == scrolling { "traditional" } else { "scrolling" }
                )
            )
        }
    }
}
