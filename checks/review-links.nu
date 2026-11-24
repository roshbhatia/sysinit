use std/assert

def main [emitter: path, router: path, probe: path] {
    let root = mktemp --directory

    let cwd = $root | path join 'work #1'

    mkdir $cwd

    let post = {hook_event_name: PostToolUse, cwd: $cwd}

    let patch = ($post | merge {
        tool_name: apply_patch
        tool_response: "Exit code: 0\nOutput:\nSuccess. Updated the following files:\nM a.nu\nD b.nu"
    })

    let edit = $post | merge {tool_name: Edit, tool_input: {file_path: 'a.nu'}}

    let failed = $patch | update tool_response "Exit code: 1\nError: patch failed"

    with-env {WEZTERM_PANE: '42'} {
        let link = ^$emitter $cwd | str trim
        let codex = $patch | to json --raw | ^$emitter --hook | from json
        let claude = $edit | to json --raw | ^$emitter --hook | from json
        assert equal $codex.systemMessage $link
        assert equal $claude.systemMessage $link
        assert ($link | str ends-with '/work%20%231>')
        assert equal ($failed | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update hook_event_name PostToolUseFailure | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update tool_name Bash | to json --raw | ^$emitter --hook | str trim) ''

        let uri = $link | parse 'Review diff <{uri}>' | get 0.uri
        ^lua $probe $router $uri $cwd
    }

    with-env {WEZTERM_PANE: ''} {
        assert equal ($edit | to json --raw | ^$emitter --hook | str trim) ''
    }
}
