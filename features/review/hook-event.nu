export def normalize [event: record, harness: string] {
    let phase = match $event.hook_event_name? {
        UserPromptSubmit => 'start'
        Stop => 'stop'
        PostToolUse => {
            let tool = $event.tool_name?

            let edits = match $harness {
                codex => { $tool == 'apply_patch' }
                claude => { $tool in [Edit Write MultiEdit NotebookEdit] }
                _ => { $tool in [apply_patch Edit Write MultiEdit NotebookEdit] }
            }

            if not $edits { return }

            let response = $event.tool_response?

            let failed = if ($response | describe) =~ '^record' {
                ($response.exit_code? | default 0) != 0 or $response.success? == false or $response.status? == 'failed'
            } else {
                false
            }

            if $failed { return }

            'edit'
        }
        _ => { return }
    }

    let session = $event.session_id? | default ''

    if $session == '' { return }

    {
        phase: $phase
        cwd: ($event.cwd? | default $env.PWD)
        session: $session
    }
}
