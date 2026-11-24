def link-directory [] {
    $env.XDG_STATE_HOME? | default ($env.HOME | path join .local state) | path join agent-diff links
}

def review-link [cwd: path] {
    let directory = $cwd | path expand --strict

    if ($directory | path type) != dir { return }

    let id = $directory | hash sha256 | str substring 0..<16

    let links = link-directory

    let path = $links | path join $id

    if not ($path | path exists) {
        mkdir $links

        ^chmod 700 $links

        ^ln -sT -- $directory $path | complete | ignore
    }

    if ($path | path expand --strict) == $directory {
        $"Review diff <review://($id)>"
    }
}

def resolve-link [uri: string] {
    if $uri !~ '^review://[0-9a-f]{16}$' {
        error make {msg: 'Invalid review link'}
    }

    let directory = try {
        link-directory | path join ($uri | str substring 9..) | path expand --strict
    } catch {
        error make {msg: 'The review checkout is unavailable'}
    }

    if ($directory | path type) != dir {
        error make {msg: 'The review checkout is unavailable'}
    }

    $directory
}

def main [target: string = '.', --hook, --resolve] {
    if $resolve { return (resolve-link $target) }

    if not $hook { return (review-link $target) }

    if ($env.WEZTERM_PANE? | default '') !~ '^\d+$' { return }

    let input = $in

    try {
        let event = $input | from json --strict

        if $event.hook_event_name? != 'PostToolUse' { return }

        let edited = match $event.tool_name? {
            'apply_patch' => {
                let response = $event.tool_response? | default ''

                let succeeded = $response | str starts-with "Exit code: 0\n"

                $succeeded and ($response | str contains 'Success. Updated the following files:')
            }
            'Edit' | 'Write' | 'MultiEdit' => { ($event.tool_input.file_path? | default '') != '' }
            'NotebookEdit' => { ($event.tool_input.notebook_path? | default '') != '' }
            _ => false
        }

        if $edited {
            let link = review-link ($event.cwd? | default $env.PWD)

            if $link != null {
                {systemMessage: $link} | to json --raw
            }
        }
    }
}
