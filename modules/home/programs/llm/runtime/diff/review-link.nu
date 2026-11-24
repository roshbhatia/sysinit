def review-link [cwd: path] {
    let directory = $cwd | path expand --strict

    if ($directory | path type) == dir {
        $"Review diff <review://($directory | url encode)>"
    }
}

def main [cwd: path = '.', --hook] {
    if not $hook { return (review-link $cwd) }

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
