use std/assert

def main [guard: path, tools: path] {
    for tool in (open $tools) {
        for channel in [U_ALLOWED U_OTHER] {
            let result = {
                tool_name: $tool
                tool_input: {channel_id: $channel}
            }
            | to json --raw
            | ^bash $guard
            | complete

            assert equal $result.exit_code 0 $result.stderr

            let denied = ($tool | str ends-with schedule_message) or $channel == U_OTHER

            if $denied {
                assert equal ($result.stdout | from json | get hookSpecificOutput.permissionDecision) deny
            } else {
                assert equal ($result.stdout | str trim) ''
            }
        }
    }
}
