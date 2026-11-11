#!/usr/bin/env nu

# Structured control of seshy sessions and WezTerm panes for agents and launchers.

const version = "sysinit.ty/v1"

const usage = "ty: inspect and control seshy sessions in WezTerm

Usage:
  ty catalog
  ty sessions
  ty panes
  ty session open <session-id-or-name>
  ty session launch <session-id-or-name>
  ty session switch <session-id-or-name>
  ty pane split <pane-id> --direction right|down [--cwd PATH]
  ty pane spawn <pane-id> --direction right|down [--cwd PATH] -- <command> [args...]
  ty pane read <pane-id>
  ty pane send [--submit] <pane-id> [text...]
  ty pane focus <pane-id>
  ty pane close <pane-id>

Catalog and action results use JSON. Pane read writes terminal text directly.
Pane send reads text from stdin when no text argument is supplied.
"

# Usage errors exit 2 and operational errors exit 1, as callers branch on the code.
def usage-error [message: string] {
    error make {msg: $message, help: "usage"}
}

def tool [name: string] {
    match $name {
        "sy" => ($env.SYSINIT_TY_SY? | default "sy")
        "wezterm" => ($env.SYSINIT_TY_WEZTERM? | default "wezterm")
        "env" => ($env.SYSINIT_TY_ENV? | default "env")
    }
}

# Runs a tool with the same 15-second bound for every call, returning stdout.
def call [name: string, args: list<string>, input?: string] {
    let binary = (tool $name)
    let result = if $input == null {
        ^timeout 15 $binary ...$args | complete
    } else {
        $input | ^timeout 15 $binary ...$args | complete
    }
    if $result.exit_code != 0 {
        let detail = $result.stderr | str trim
        let base = $binary | path basename
        error make {
            msg: (
                if ($detail | is-empty) { $"($base): exit status ($result.exit_code)" } else { $"($base): exit status ($result.exit_code): ($detail)" }
            )
        }
    }
    $result.stdout
}

def emit [value: record] {
    print ($value | to json --raw)
}

def pane-id [value: string] {
    if $value !~ '^[0-9]+$' {
        usage-error $"pane id must be a non-negative integer: \"($value)\""
    }
    $value
}

def list-sessions [] {
    let raw = (
        try { call sy [list --format json] } catch {|error| error make {msg: $"list seshy sessions: ($error.msg)"} }
    )
    try {
        $raw | from json | default []
    } catch {
        error make {msg: "decode seshy session list"}
    }
}

def list-panes [] {
    let raw = (
        try {
            call wezterm [cli --no-auto-start list --format json]
        } catch {|error|
            error make {msg: $"list WezTerm panes: ($error.msg)"}
        }
    )
    try {
        $raw | from json | default []
    } catch {
        error make {msg: "decode WezTerm pane list"}
    }
}

def session [args: list<string>] {
    if ($args | length) != 2 or ($args.0 not-in [open switch launch]) {
        usage-error "usage: ty session open|switch|launch <session-id-or-name>"
    }
    let action = $args.0
    let target = $args.1 | str trim
    if ($target | is-empty) {
        usage-error "session id or name cannot be empty"
    }
    let raw = (
        try {
            call sy [open $target --format json]
        } catch {|error|
            error make {msg: $"resolve seshy open plan: ($error.msg)"}
        }
    )
    let plan = (
        try {
            $raw | from json
        } catch {
            error make {msg: "decode seshy open plan"}
        }
    )
    if ($plan.version? | default "") != "seshy.open/v1" {
        error make {
            msg: $"unsupported seshy open plan version \"($plan.version? | default '')\""
        }
    }
    let id = $plan.id? | default ""
    if not ($id | str starts-with "seshy:") or ($id | str replace "seshy:" "" | is-empty) {
        error make {msg: $"invalid seshy session id \"($id)\""}
    }
    let cwd = $plan.cwd? | default ""
    if not ($cwd | str starts-with "/") {
        error make {msg: $"seshy open plan cwd must be absolute: \"($cwd)\""}
    }
    let environment = $plan.environment? | default {}
    for entry in ($environment | transpose key value) {
        if ($entry.key !~ '^[A-Za-z_][A-Za-z0-9_]*$') or ($entry.value | str contains (char nul)) {
            error make {msg: $"invalid environment entry \"($entry.key)\""}
        }
    }
    let command = $plan.command? | default []
    if ($command | any {|arg| $arg | str contains (char nul) }) {
        error make {msg: "seshy open plan command contains a null byte"}
    }
    let workspace = $id | str replace "seshy:" ""
    if $action == "switch" {
        let existing = list-panes | where workspace == $workspace | get -o 0.pane_id
        if $existing != null {
            try {
                call wezterm [
                    cli
                    --no-auto-start
                    activate-pane
                    --pane-id
                    ($existing | into string)
                ]
            } catch {|error|
                error make {msg: $"switch to WezTerm session \"($id)\": ($error.msg)"}
            }
            emit {
                version: $version
                action: "session.switch"
                session_id: $id
                workspace: $workspace
                cwd: $cwd
                pane_id: ($existing | into string)
                opened: false
            }
            return
        }
    }
    # A plan environment is applied through env so the shell or command inherits it.
    let launched = if ($environment | is-empty) {
        $command
    } else {
        let assignments = (
            $environment
            | transpose key value
            | sort-by key
            | each {|e| $"($e.key)=($e.value)" }
        )
        let program = if ($command | is-empty) {
            [
                (login-shell)
                "-l"
            ]
        } else {
            $command
        }
        [
            (tool env)
        ] ++ $assignments ++ $program
    }
    let window = [--workspace $workspace --cwd $cwd] ++ (if ($launched | is-empty) { [] } else { ["--"] ++ $launched })
    if $action == "launch" {
        # The GUI outlives this command and must not hold its output pipes.
        try { ^/bin/sh -c '"$@" </dev/null >/dev/null 2>&1 &' sh (tool wezterm) start ...$window } catch {|error| error make {msg: $"launch WezTerm session \"($id)\": ($error.msg)"} }
        emit {
            version: $version
            action: "session.launch"
            session_id: $id
            workspace: $workspace
            cwd: $cwd
            opened: true
        }
        return
    }
    let spawned = (
        try {
            call wezterm ([cli --no-auto-start spawn --new-window] ++ $window)
            | str trim
        } catch {|error|
            error make {msg: $"open WezTerm session \"($id)\": ($error.msg)"}
        }
    )
    if $spawned !~ '^[0-9]+$' {
        error make {msg: $"WezTerm returned invalid pane id: \"($spawned)\""}
    }
    emit {
        version: $version
        action: (if $action == "switch" { "session.switch" } else { "session.open" })
        session_id: $id
        workspace: $workspace
        cwd: $cwd
        pane_id: $spawned
        opened: true
    }
}

def login-shell [] {
    let shell = $env.SHELL? | default ""
    if ($shell | str starts-with "/") { $shell } else if $nu.os-info.name == "macos" { "/bin/zsh" } else { "/bin/sh" }
}

def split [args: list<string>, spawn: bool] {
    mut pane = ""
    mut direction = ""
    mut cwd = ""
    mut command = []
    mut index = 0
    while $index < ($args | length) {
        let arg = $args | get $index
        if $arg == "--direction" or $arg == "--cwd" {
            $index += 1
            if $index >= ($args | length) {
                usage-error (
                    if $arg == "--direction" { "--direction requires right or down" } else { "--cwd requires a path" }
                )
            }
            if $arg == "--direction" { $direction = ($args | get $index) } else { $cwd = ($args | get $index) }
        } else if $arg == "--" {
            $command = ($args | skip ($index + 1))
            break
        } else if ($arg | str starts-with "-") or ($pane | is-not-empty) {
            usage-error $"unexpected split argument \"($arg)\""
        } else {
            $pane = $arg
        }
        $index += 1
    }
    let pane = $pane
    let direction = $direction
    let cwd = $cwd
    let command = $command
    pane-id $pane | ignore
    if $direction not-in [right down] { usage-error "--direction must be right or down" }
    if ($cwd | is-not-empty) and not ($cwd | str starts-with "/") { usage-error "--cwd must be an absolute path" }
    if $spawn and ($command | is-empty) { usage-error "pane spawn requires a command after --" }
    if (not $spawn) and ($command | is-not-empty) { usage-error "pane split does not accept a command; use pane spawn" }
    if ($command | any {|arg| $arg | str contains (char nul) }) { usage-error "command contains a null byte" }
    let wez = (
        [cli --no-auto-start split-pane --pane-id $pane (if $direction == "right" { "--right" } else { "--bottom" })]
        ++ (if ($cwd | is-empty) { [] } else { [--cwd $cwd] })
        ++ (if ($command | is-empty) { [] } else { ["--"] ++ $command })
    )
    let created = (
        try {
            call wezterm $wez | str trim
        } catch {|error|
            error make {msg: $"split pane ($pane): ($error.msg)"}
        }
    )
    if $created !~ '^[0-9]+$' { error make {msg: $"WezTerm returned invalid pane id: \"($created)\""} }
    emit {
        version: $version
        action: (if $spawn { "pane.spawn" } else { "pane.split" })
        pane_id: $created
    }
}

def send [args: list<string>] {
    let submit = ($args | get -o 0) == "--submit"
    let rest = if $submit {
        $args | skip 1
    } else {
        $args
    }
    if ($rest | is-empty) { usage-error "usage: ty pane send [--submit] <pane-id> [text...]" }
    let pane = (pane-id $rest.0)
    # A script's main does not receive piped stdin as $in, but an external command inherits it.
    let text = if ($rest | length) > 1 {
        $rest | skip 1 | str join " "
    } else {
        ^cat
    }
    if ($text | is-empty) { usage-error "text is empty" }
    try {
        (call
            wezterm
            [cli --no-auto-start send-text --pane-id $pane]
            $text
        )
    } catch {|error|
        error make {msg: $"send text to pane ($pane): ($error.msg)"}
    }
    if $submit {
        try {
            call wezterm [
                cli
                --no-auto-start
                send-text
                --no-paste
                --pane-id
                $pane
                "\r"
            ]
        } catch {|error|
            error make {msg: $"submit text to pane ($pane): ($error.msg)"}
        }
    }
    emit {version: $version, action: "pane.send", pane_id: $pane}
}

def pane [args: list<string>] {
    if ($args | is-empty) { usage-error "expected pane subcommand: split, spawn, read, send, focus, or close" }
    let rest = $args | skip 1
    match $args.0 {
        "split" => { split $rest false }
        "spawn" => { split $rest true }
        "read" => {
            if ($rest | length) != 1 { usage-error "usage: ty pane read <pane-id>" }
            let pane = (pane-id $rest.0)
            print --no-newline (
                try {
                    call wezterm [cli --no-auto-start get-text --pane-id $pane]
                } catch {|error|
                    error make {msg: $"read pane ($pane): ($error.msg)"}
                }
            )
        }
        "send" => { send $rest }
        "focus" | "close" => {
            let action = $args.0
            if ($rest | length) != 1 { usage-error $"usage: ty pane ($action) <pane-id>" }
            let pane = (pane-id $rest.0)
            let command = if $action == "close" { "kill-pane" } else { "activate-pane" }
            try {
                call wezterm [cli --no-auto-start $command --pane-id $pane]
            } catch {|error|
                error make {msg: $"($action) pane ($pane): ($error.msg)"}
            }
            emit {
                version: $version
                action: $"pane.($action)"
                pane_id: $pane
            }
        }
        $other => { usage-error $"unknown pane command \"($other)\"" }
    }
}

def --wrapped main [...args: string] {
    if ($args | is-empty) or ($args.0 in [--help -h help]) {
        print --no-newline $usage
        return
    }
    try {
        match $args.0 {
            "catalog" => {
                emit {
                    version: $version
                    sessions: (list-sessions)
                    panes: (list-panes)
                }
            }
            "sessions" => {
                emit {
                    version: $version
                    sessions: (list-sessions)
                }
            }
            "panes" => {
                emit {
                    version: $version
                    panes: (list-panes)
                }
            }
            "session" => { session ($args | skip 1) }
            "pane" => { pane ($args | skip 1) }
            $other => { usage-error $"unknown command \"($other)\"" }
        }
    } catch {|error|
        print -e $"ty: ($error.msg)"
        exit (if ($error.details?.help? | default "") == "usage" { 2 } else { 1 })
    }
}
