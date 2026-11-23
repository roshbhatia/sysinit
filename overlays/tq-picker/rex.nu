def --wrapped rex-cli [...args: string] {
    let result = ^rex --autostart=false ...$args | complete

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default --empty 'Rex command failed')
        }
    }

    $result.stdout
}

def respond [request: record] {
    let input = $request.input

    if $request.capability == 'terminal.review' {
        ^agent-diff --review --allow-directory --cwd $input.cwd --background | ignore

        return {}
    }

    let sessions = rex-cli session ls --json | from json --strict | get sessions

    if $request.capability == 'terminal.spawn' {
        let matches = $sessions | where label == $input.workspace

        if ($matches | length) > 1 {
            error make {msg: $"Several Rex sessions are named ($input.workspace)"}
        }

        let args = [
            --cwd
            $input.cwd
            --shell
            none
            --json
            --
            ...$input.argv
        ]

        let reference = if ($matches | is-empty) {
            let created = rex-cli new $input.workspace --window $input.title ...$args | from json --strict

            {session: $created.session_id, tab: $created.initial_windows.0.window_id}
        } else {
            let session = $matches.0.session_id

            let created = rex-cli window new --session $session $input.title --focus=false ...$args | from json --strict

            {session: $session, tab: $created.window_id}
        }

        return {reference: $reference}
    }

    let reference = $input.reference

    let session = $sessions | where session_id == $reference.session | get 0?

    if $session == null { return {live: false} }

    let tabs = rex-cli session inspect $reference.session --json | from json --strict | get -o windows | default []

    let live = $reference.tab in ($tabs | get window_id)

    if not $live { return {live: false} }

    match $request.capability {
        'terminal.status' => {live: true}
        'terminal.focus' => {
            rex-cli focus --session $reference.session $reference.tab | ignore

            {live: true, workspace: $session.label}
        }
        'terminal.close' => {
            rex-cli window close --session $reference.session $reference.tab | ignore

            {}
        }
        _ => { error make {msg: $"Unsupported Rex capability ($request.capability)"} }
    }
}

def main [] {
    let request = $in | from json --strict

    let result = try {
        if $request.version != 'provider/v1' or $request.kind != 'request' {
            error make {msg: 'Expected a provider/v1 request'}
        }

        {
            status: ok
            output: (respond $request)
        }
    } catch {|failure|
        {status: error, message: $failure.msg}
    }

    $result
    | merge {version: provider/v1, kind: result, requestId: $request.requestId}
    | to json --raw
    | print
}
