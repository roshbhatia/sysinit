use std/assert

def run-command [arguments: list<string>, --data: string, --unchecked] {
    let program = $arguments | first

    let arguments = $arguments | skip 1

    let result = if $data == null {
        ^timeout 60s $program ...$arguments | complete
    } else {
        $data | ^timeout 60s $program ...$arguments | complete
    }

    if not $unchecked and $result.exit_code != 0 {
        error make {
            msg: ($result.stdout + "\n" + $result.stderr)
        }
    }

    $result
}

def write-json [path: path, value] {
    mkdir ($path | path dirname)

    $value | to json | save --force $path
}

def checkpoint [
    gate: path
    payload: record
    event: string
    repository: path
] {
    let request = {
        requestId: fixture
        input: {
            event: {
                harness: codex
                cwd: $repository
                raw: ($payload | upsert hook_event_name $event)
            }
        }
    }

    let result = run-command [$gate serve] --data ($request | to json)

    assert equal ($result.stdout | from json | get output.decision) pass
}

def main [
    ai: path
    gate: path
    provider: path
    attribution: path
    storage: path
] {
    let git = which git | first | get path

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    try {
        let home = $root | path join home

        let repo = $root | path join repo

        mkdir $home $repo

        with-env {
            HOME: $home
            XDG_CONFIG_HOME: ($home | path join .config)
            XDG_CACHE_HOME: ($home | path join .cache)
            XDG_DATA_HOME: ($home | path join .local share)
            GIT_CONFIG_GLOBAL: ($home | path join .gitconfig)
            GIT_CONFIG_NOSYSTEM: '1'
            GIT_AI_DAEMON_HOME: $home
            CODEX_HOME: ($home | path join .codex)
        } {
            cd $repo
            write-json ($home | path join .git-ai config.json) {
                git_path: $git, prompt_storage: local, telemetry_oss: off, disable_auto_updates: true, disable_version_checks: true
                feature_flags: {transcript_sweep: false, daemon_log_upload: false, token_usage_metrics: false}
            }
            run-command [$git config --global trace2.eventTarget $'af_unix:stream:($home)/.git-ai/internal/daemon/trace2.sock'] | ignore
            run-command [$git config --global trace2.eventNesting '0'] | ignore
            let log = $root | path join daemon.log
            let daemon = job spawn --auto-kill { ^$ai bg run out+err> $log }
            try {
                mut ready = false
                for attempt in 1..60 {
                    if (run-command [$ai bg status] --unchecked | get exit_code) == 0 { $ready = true; break }
                    if (job list | where id == $daemon | is-empty) {
                        error make {msg: (open --raw $log)}
                    }
                    sleep 250ms
                }
                assert $ready 'Git AI daemon did not become ready'
                run-command [$git init --quiet] | ignore
                run-command [$git config user.name 'Integration test'] | ignore
                run-command [$git config user.email test@example.invalid] | ignore
                let sample = $repo | path join sample.txt
                "baseline\n" | save $sample
                run-command [$git add .] | ignore
                run-command [$git commit -m baseline] | ignore
                "baseline\nhuman line\n" | save --force $sample
                let payload = {
                    cwd: $repo, session_id: native-codex-test, model: test-model, tool_name: functions.apply_patch, tool_use_id: call-1
                    tool_input: "*** Begin Patch\n*** Update File: sample.txt\n@@\n human line\n+agent line\n*** End Patch"
                    tool_response: "Success. Updated the following files:\nM sample.txt"
                }
                checkpoint $gate $payload PreToolUse $repo
                "baseline\nhuman line\nagent line\n" | save --force $sample
                checkpoint $gate $payload PostToolUse $repo
                run-command [$git add .] | ignore
                run-command [$git commit -m 'mixed human and agent edit'] | ignore
                run-command [$ai await --timeout '30'] | ignore
                let blame = run-command [$ai blame --json sample.txt] | get stdout | from json
                assert equal ($blame.lines | columns) ['3']
                let agent = $blame.prompts | get ($blame.lines | get '3') | get agent_id
                assert equal $agent {tool: codex, id: native-codex-test, model: test-model}
                run-command [$git notes --ref=changes add -m 'review stays separate'] | ignore
                let before = run-command [$git rev-parse refs/notes/changes] | get stdout
                let request = {version: changes.provider/v1, action: changes.notes, directory: $repo, files: [sample.txt], from: HEAD~1, to: HEAD}
                let notes = run-command [$nu.current-exe --no-config-file --stdin $provider] --data ($request | to json) | get stdout | from json | get notes
                assert equal ($notes | length) 1
                assert equal $notes.0.anchor.line 3
                assert equal $notes.0.session native-codex-test
                assert ($notes.0.rationale | str contains 'traces --all --session native-codex-test')
                assert equal (run-command [$git rev-parse refs/notes/changes] | get stdout) $before
                let manifests = $home | path join .config changes providers git-ai
                write-json ($manifests | path join provider.yaml) {
                    version: provider/v1, name: git-ai, description: 'Read Git AI attribution'
                    command: [$nu.current-exe --no-config-file --stdin $provider]
                    actions: {changes.notes: {description: 'Read attribution'}}
                }
                $env.CHANGES_PROVIDERS_DIRECTORY = $manifests | path dirname
                let listed = run-command [changes note list --commit HEAD --provider git-ai --json] | get stdout | from json
                assert ($listed | to json | str contains native-codex-test)
                "baseline\nhuman line\nagent line\nhuman suffix\n" | save --force $sample
                for arguments in [[] [--staged]] {
                    if ($arguments | is-not-empty) { run-command [$git add sample.txt] | ignore }
                    let listed = run-command ([changes note list --provider git-ai --json] | append $arguments) | get stdout | from json
                    assert equal ($listed.notes | length) 1
                    assert equal $listed.notes.0.anchor.line 3
                }
                let timestamp = date now | date to-timezone UTC | format date '%+'
                let events = [
                    {type: session_meta, timestamp: $timestamp, payload: {id: $agent.id, cwd: $repo}}
                    {
                        type: event_msg, timestamp: $timestamp
                        payload: {
                            type: item_completed, thread_id: $agent.id, turn_id: fixture-turn
                            item: {type: AgentMessage, id: fixture-message, content: [{type: Text, text: 'Native attribution fixture'}]}
                        }
                    }
                ]
                let sessions = $home | path join .codex sessions
                mkdir $sessions
                (($events | each { to json --raw } | str join "\n") + "\n") | save ($sessions | path join rollout-native-codex-test.jsonl)
                write-json ($home | path join .config traces providers codex provider.yaml) {
                    version: provider/v1, name: codex, description: 'Read Codex sessions'
                    command: [(which traces-provider-codex | first | get path)]
                    actions: {activity.read: {description: 'Read session activity', argv: [--since '{{ .Since }}' --session '{{ .Session }}' --directory '{{ .Directory }}']}}
                }
                let traced = run-command [traces --provider codex --all --session $agent.id --once --view output --format jsonl] | get stdout
                assert ($traced | str contains 'Native attribution fixture')
                let imports = $'use ($attribution | to json --raw) *; use ($storage | to json --raw) *; '
                let summary = run-command [$nu.current-exe --no-config-file -c ($imports + 'attribution stats | to json --raw')] | get stdout | from json
                assert equal $summary.ai_additions 1
                let sessions = run-command [$nu.current-exe --no-config-file -c ($imports + 'attribution sessions --commit HEAD | to json --raw')] | get stdout | from json
                assert equal $sessions [native-codex-test]
                let state = run-command [$nu.current-exe --no-config-file -c ($imports + 'attribution status | select repository_status | to json --raw')] | get stdout | from json
                assert equal $state.repository_status.last_error null
                let sizes = run-command [$nu.current-exe --no-config-file -c ($imports + 'storage usage . --depth 0 | to json --raw')] | get stdout | from json
                assert equal ($sizes | length) 1
                assert ($sizes.0.allocated > 0)
                for code in ['attribution stats missing-revision' 'storage usage missing-directory' 'attribution notes --commit HEAD --staged'] {
                    let failed = run-command [$nu.current-exe --no-config-file -c ($imports + $code)] --unchecked
                    assert ($failed.exit_code != 0) $code
                }
                let bad = {requestId: bad, input: {event: {harness: codex}}}
                let failed = run-command [$gate serve] --data ($bad | to json) --unchecked
                assert ($failed.exit_code != 0 and ($failed.stderr | str contains 'missing native hook payload'))
                let failed = run-command [$ai checkpoint codex --hook-input stdin] --data '{}' --unchecked
                assert ($failed.exit_code != 0 and ($failed.stderr | str contains 'preset error'))
                let quoted = 'quoted "fixture".txt'
                "baseline\n" | save $quoted
                run-command [$git add -- $quoted] | ignore
                run-command [$git commit -m 'quoted filename baseline'] | ignore
                let quoted_payload = $payload
                    | upsert tool_use_id call-quoted
                    | upsert tool_input ("*** Begin Patch\n*** Update File: " + $quoted + "\n@@\n baseline\n+agent first\n+agent second\n*** End Patch")
                    | upsert tool_response ("Success. Updated the following files:\nM " + $quoted)
                checkpoint $gate $quoted_payload PreToolUse $repo
                "baseline\nagent first\nagent second\n" | save --force $quoted
                checkpoint $gate $quoted_payload PostToolUse $repo
                run-command [$git add -- $quoted] | ignore
                run-command [$git commit -m 'adjacent attributed lines'] | ignore
                run-command [$ai await --timeout '30'] | ignore
                let quoted_request = $request | update files [$quoted]
                let notes = run-command [$nu.current-exe --no-config-file --stdin $provider] --data ($quoted_request | to json) | get stdout | from json | get notes
                assert equal ($notes | length) 1
                assert equal $notes.0.anchor.path $quoted
                assert equal $notes.0.anchor.startLine 2
                assert equal $notes.0.anchor.line 3
                let invalid = $request | update files ['../invalid']
                let failed = run-command [$nu.current-exe --no-config-file --stdin $provider] --data ($invalid | to json) --unchecked
                assert ($failed.exit_code != 0 and ($failed.stderr | str contains 'invalid repository path'))
                let malformed = run-command [$nu.current-exe --no-config-file --stdin $provider] --data fixture-secret --unchecked
                assert ($malformed.exit_code != 0)
                assert not (($malformed.stdout + $malformed.stderr) | str contains fixture-secret)
            } catch {|failure|
                try { job kill $daemon } catch { null } | ignore
                error make $failure
            }
            job kill $daemon
        }
    } catch {|failure|
        cd ($root | path dirname)

        rm --recursive --force $root

        error make $failure
    }

    cd ($root | path dirname)

    rm --recursive --force $root

    print 'Native checkpoints preserve human edits; Git notes and Traces session provenance compose'
}
