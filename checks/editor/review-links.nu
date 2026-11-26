use std/assert

def main [emitter: path, router: path, probe: path] {
    let root = mktemp --directory

    let cwd = $root | path join 'work #1'

    mkdir $cwd

    let cwd = $cwd | path expand --strict

    let post = {hook_event_name: PostToolUse, cwd: $cwd, session_id: codex-fixture}

    let patch = ($post | merge {
        tool_name: apply_patch
        tool_response: "Exit code: 0\nOutput:\nSuccess. Updated the following files:\nM a.nu\nD b.nu"
    })

    let edit = $post | merge {session_id: claude-fixture, tool_name: Edit, tool_input: {file_path: 'a.nu'}}

    let failed = $patch | update tool_response "Exit code: 1\nError: patch failed"

    with-env {WEZTERM_PANE: '42', XDG_STATE_HOME: ($root | path join state)} {
        let uri = ^$emitter $cwd | str trim
        let stop = $post | update hook_event_name Stop
        let patch_notice = $patch | to json --raw | ^$emitter --hook | from json
        assert equal ($patch_notice.systemMessage | lines | get 1) 'Review edit · ⌘-click below'
        assert equal ($patch | to json --raw | ^$emitter --hook | str trim) ''
        let edit_notice = $edit | to json --raw | ^$emitter --hook | from json
        assert equal $edit_notice.systemMessage $patch_notice.systemMessage
        let codex = $stop | to json --raw | ^$emitter --hook | from json
        let claude = $stop | update session_id $edit.session_id | to json --raw | ^$emitter --hook | from json
        assert equal ($codex.systemMessage | lines) [
            '----------------------------------------'
            'Review turn edits · ⌘-click below'
            $uri
            '----------------------------------------'
        ]
        assert equal $claude.systemMessage $codex.systemMessage
        assert equal ($stop | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($failed | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update hook_event_name PostToolUseFailure | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($edit | update tool_name Bash | to json --raw | ^$emitter --hook | str trim) ''
        assert equal ($stop | to json --raw | ^$emitter --hook | str trim) ''
        $patch | to json --raw | ^$emitter --hook
        $stop | update hook_event_name UserPromptSubmit | to json --raw | ^$emitter --hook
        assert equal ($stop | to json --raw | ^$emitter --hook | str trim) ''

        assert ($uri =~ '^review://changes/work%20%231/[0-9a-f]{16}$')
        assert equal (^$emitter --resolve $uri | str trim) $cwd
        let id = $uri | split row '/' | last
        assert equal (^$emitter --resolve $"review://worktree/($id)" | str trim) $cwd
        assert equal (^$emitter --resolve $"review://($id)" | str trim) $cwd
        let unknown = ^$emitter --resolve 'review://worktree/0000000000000000' | complete
        assert ($unknown.exit_code != 0)

        let file_uri = $"file://($cwd | url encode)"
        ^lua $probe $router $uri $cwd $file_uri
    }

    with-env {WEZTERM_PANE: '', XDG_STATE_HOME: ($root | path join state)} {
        let edit_notice = $edit | to json --raw | ^$emitter --hook | from json
        assert equal ($edit_notice.systemMessage | lines | get 1) 'Review edit'
        let notice = $edit | update hook_event_name Stop | to json --raw | ^$emitter --hook | from json
        assert equal ($notice.systemMessage | lines | get 1) 'Review turn edits'

        let repo = $root | path join sysinit
        let nested = $repo | path join nested
        let worktree = $root | path join 'review links'
        mkdir $nested
        ^git -C $repo init --quiet --initial-branch feature/review
        ^git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --allow-empty --quiet -m fixture
        ^git -C $repo worktree add --quiet --detach $worktree
        let branch_link = ^$emitter $nested | str trim
        let worktree_link = ^$emitter $worktree | str trim
        assert ($branch_link =~ '^review://changes/sysinit/feature%2Freview/[0-9a-f]{16}$')
        assert ($worktree_link =~ '^review://changes/sysinit/review%20links/[0-9a-f]{16}$')
        assert equal (^$emitter --resolve $branch_link | str trim) ($repo | path expand --strict)
        assert equal (^$emitter --resolve $worktree_link | str trim) ($worktree | path expand --strict)

        let turn = $post | merge {cwd: $nested, hook_event_name: UserPromptSubmit}
        let stop = $turn | update hook_event_name Stop
        let edit = $patch | update cwd $nested
        'existing dirty file' | save ($repo | path join existing.txt)
        $turn | to json --raw | ^$emitter --hook
        'committed edit' | save ($repo | path join committed.txt)
        let first = $edit | to json --raw | ^$emitter --hook | from json
        assert equal ($first.systemMessage | lines | get 1) 'Review edit · 1 file'
        assert equal ($edit | to json --raw | ^$emitter --hook | str trim) ''
        ^git -C $repo add -- committed.txt
        ^git -C $repo -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m edit
        'uncommitted edit' | save ($repo | path join uncommitted.txt)
        let second = $edit | to json --raw | ^$emitter --hook | from json
        assert equal ($second.systemMessage | lines | get 1) 'Review edit · 1 file'
        let second_id = $second.systemMessage | lines | get 2 | split row '=' | last
        let second_ref = $'refs/worktree/sysinit/turn-reviews/($second_id)'
        assert equal (^git -C $repo diff --name-only $'($second_ref)/before' $'($second_ref)/after' -- | lines) [uncommitted.txt]
        let notice = $stop | to json --raw | ^$emitter --hook | from json
        assert equal ($notice.systemMessage | lines | get 1) 'Review turn edits · 2 files'
        let uri = $notice.systemMessage | lines | get 2
        assert ($uri =~ '^review://changes/sysinit/feature%2Freview/[0-9a-f]{16}\?turn=[0-9a-f]{16}$')
        assert equal (^$emitter --resolve $uri | str trim) $repo
        let id = $uri | split row '=' | last
        let ref = $'refs/worktree/sysinit/turn-reviews/($id)'
        assert equal (^git -C $repo diff --name-only $'($ref)/before' $'($ref)/after' -- | lines) [
            committed.txt
            uncommitted.txt
        ]
        'later edit' | save --force ($repo | path join uncommitted.txt)
        assert equal (^git -C $repo show $'($ref)/after:uncommitted.txt') 'uncommitted edit'
        assert equal (^git -C $repo diff --cached --name-only | str trim) ''
        assert equal (^git -C $repo ls-files --others --exclude-standard | lines) [
            existing.txt
            uncommitted.txt
        ]
        $turn | to json --raw | ^$emitter --hook
        assert equal ($stop | to json --raw | ^$emitter --hook | str trim) ''

        ^lua $probe $router $uri $repo $"file://($repo | url encode)" $id
    }
}
