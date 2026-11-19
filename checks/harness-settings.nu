use std/assert

def main [timeout: path] {
    let parsed = open parsed.json

    assert equal $parsed.theme default

    assert equal $parsed.defaultPermissionMode allow-all

    let hook = $parsed.hooks.preToolUse.0

    assert equal $hook._vsCodeCompat PreToolUse

    assert equal $hook.matcher Bash

    for case in [
        {command: 'printf fixture', expected: 0}
        {command: 'git reset --hard', expected: 2}
    ] {
        let request = {
            hook_event_name: PreToolUse
            session_id: harness-settings-test
            cwd: $env.PWD
            tool_name: Bash
            tool_input: {command: $case.command}
        }

        let result = with-env {PATH: '/usr/bin:/bin'} {
            $request | to json | ^$timeout 15s $hook.bash | complete
        }

        assert equal $result.exit_code $case.expected $result.stderr

        if $case.expected != 0 { assert ($result.stderr | str contains prohibited) $result.stderr }
    }

    print 'Native Copilot hook parsing and real guard allow/deny checks passed'
}
