use std/assert
use ../lib/process.nu checked-command

def hook [event: string, payload: record] {
    let result = $payload | to json | ^gate hook --harness claude --event $event --format json | complete

    assert equal $result.exit_code 0 $'($result.stderr)\n($result.stdout)'

    $result.stdout
}

def main [
    providers: path
    git_ai_provider: path
    configuration: path
    review_config: path
    git_binary: path
] {
    $env.HOME = $env.TMPDIR | path join home

    $env.XDG_CONFIG_HOME = $env.TMPDIR | path join config

    $env.XDG_STATE_HOME = $env.TMPDIR | path join state

    let gate = $env.XDG_CONFIG_HOME | path join gate

    mkdir ($env.HOME | path join .git-ai) ($gate | path join providers) $env.XDG_STATE_HOME

    {
        git_path: $git_binary
        telemetry_oss: off
        prompt_storage: local
        feature_flags: {transcript_sweep: false, token_usage_metrics: false, daemon_log_upload: false}
    }
    | to json
    | save ($env.HOME | path join .git-ai/config.json)

    cp ...(glob ($providers | path join '*.yaml')) ($gate | path join providers)

    cp $git_ai_provider ($gate | path join providers/git-ai-gate.yaml)

    open --raw $configuration
    | str replace '@providers@' ($gate | path join providers)
    | str replace '@log@' ($env.TMPDIR | path join gate-decisions.jsonl)
    | save ($gate | path join config.yaml)

    cp $review_config ($gate | path join review.yaml)

    checked-command gate config validate | ignore

    with-env {GATE_REVIEW_CONFIG: ($gate | path join review.yaml)} {
        checked-command review policy | ignore
    }

    let denied = hook PreToolUse {
        hook_event_name: PreToolUse
        tool_name: Bash
        tool_input: {command: 'git push --force'}
        cwd: '/'
    } | from json

    assert equal $denied.decision deny

    "one\n" | save annotated.txt

    checked-command note add --file annotated.txt --line 1 --summary 'why is this here' --origin user | ignore

    let prompt = hook UserPromptSubmit {hook_event_name: UserPromptSubmit, prompt: hi, cwd: '/'}

    assert equal ($prompt | from json | get decision) context

    assert ($prompt | str contains 'why is this here')

    $env.PROSE_GATE_STATE_DIR = $env.TMPDIR | path join prose

    let stop = hook Stop {
        hook_event_name: Stop
        session_id: s1
        stop_hook_active: false
        last_assistant_message: 'Basically, this seamlessly leverages a pivotal unlock. In summary, we delivered a robust solution.'
    }

    assert equal $stop ''

    let prompt = hook UserPromptSubmit {hook_event_name: UserPromptSubmit, session_id: s1, prompt: go}

    assert ($prompt | str contains 'read like agent prose')

    assert ($prompt | str contains 'sysinit-ste output style is active')

    let work = $env.TMPDIR | path join work

    mkdir $work

    let work = $work | path expand

    checked-command git -C $work init --quiet --initial-branch=main | ignore

    "old\n" | save ($work | path join a.txt)

    checked-command git -C $work add a.txt | ignore

    checked-command git -C $work -c user.name=t -c user.email=t@example.invalid -c commit.gpgsign=false commit --quiet -m base | ignore

    let daemon_log = $env.TMPDIR | path join git-ai.log

    let daemon = job spawn --auto-kill { ^git-ai bg run out+err> $daemon_log }

    let result = try {
        mut ready = false

        for attempt in 1..40 {
            if (^git-ai bg status | complete | get exit_code) == 0 {
                $ready = true

                break
            }

            sleep 250ms
        }

        assert $ready $'git-ai daemon did not become ready: (open --raw $daemon_log)'

        {
            type: assistant
            message: {model: test-model}
        } | to json --raw | save ($work | path join session.jsonl)

        hook UserPromptSubmit {
            hook_event_name: UserPromptSubmit
            session_id: s2
            cwd: $work
            prompt: 'Make a.txt say new'
        } | ignore

        "new\n" | save --force ($work | path join a.txt)

        let edit = hook PostToolUse {
            hook_event_name: PostToolUse
            session_id: s2
            transcript_path: ($work | path join session.jsonl)
            cwd: $work
            tool_name: Edit
            tool_input: {
                file_path: ($work | path join a.txt)
                old_string: old
                new_string: new
            }
        }

        assert not ($edit | str contains '"decision":"deny"')

        let digest = $work | hash sha256 | str substring 0..15

        let stem = $env.XDG_STATE_HOME | path join agents/edits $'work-($digest)'

        let edits = open --raw $'($stem).jsonl' | lines | each {from json}

        assert (
            $edits
            | any {|entry| $entry.harness == claude and $entry.kind == edit and $entry.file == ($work | path join a.txt)}
        )

        assert equal (checked-command git --git-dir $'($stem).delta' log -1 --format=%s | str trim) 'Make a.txt say new'

        null
    } catch {|failure|
        $failure
    }

    if (job list | any {|job| $job.id == $daemon}) {
        job kill $daemon
    }

    if $result != null { error make $result }
}
