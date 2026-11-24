use std/assert

def main [emitter: path, router: path, probe: path] {
    let root = mktemp --directory

    let cwd = $root | path join 'work #1'

    mkdir $cwd

    let cwd = $cwd | path expand --strict

    let post = {hook_event_name: PostToolUse, cwd: $cwd}

    let patch = ($post | merge {
        tool_name: apply_patch
        tool_response: "Exit code: 0\nOutput:\nSuccess. Updated the following files:\nM a.nu\nD b.nu"
    })

    let edit = $post | merge {tool_name: Edit, tool_input: {file_path: 'a.nu'}}

    let failed = $patch | update tool_response "Exit code: 1\nError: patch failed"

    with-env {WEZTERM_PANE: '42', XDG_STATE_HOME: ($root | path join state)} {
        let link = ^$emitter $cwd | str trim
        let codex = $patch | to json --raw | ^$emitter --hook | from json
        let claude = $edit | to json --raw | ^$emitter --hook | from json
        assert equal $codex.systemMessage $link
        assert equal $claude.systemMessage $link
        assert equal ($failed | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update hook_event_name PostToolUseFailure | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update tool_name Bash | to json --raw | ^$emitter --hook | str trim) ''

        let uri = $link | parse 'Review diff <{uri}>' | get 0.uri
        assert ($uri =~ '^review://[0-9a-f]{16}$')
        assert equal (^$emitter --resolve $uri | str trim) $cwd
        let unknown = ^$emitter --resolve 'review://0000000000000000' | complete
        assert ($unknown.exit_code != 0)

        let file_uri = $"file://($cwd | url encode)"
        ^lua $probe $router $uri $cwd $file_uri
    }

    with-env {WEZTERM_PANE: ''} {
        assert equal ($edit | to json --raw | ^$emitter --hook | str trim) ''
    }
}
