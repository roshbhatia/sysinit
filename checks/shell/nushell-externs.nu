use std/assert

def evaluate [module: path, code: string] {
    ^timeout 20s $nu.current-exe --no-config-file -c $'use ($module | to json --raw) *; ($code)' | complete
}

def success [module: path, code: string] {
    let result = evaluate $module $code

    assert equal $result.exit_code 0 $result.stderr

    assert equal $result.stderr ''

    $result.stdout
}

def last-arguments [] {
    open --raw $env.EXTERN_ARGV | lines | last | from json
}

def --wrapped git [...arguments: string] {
    let result = ^git ...$arguments | complete

    assert equal $result.exit_code 0 $result.stderr

    $result.stdout
}

def init-repository [] {
    git init --initial-branch=main | ignore

    "original\n" | save 'original file'

    "first\n" | save tracked

    git add . | ignore

    git commit -m 'subject | with "quotes"' | ignore

    "second\n" | save --force tracked

    git add tracked | ignore

    git commit '--allow-empty-message' '-m' '' | ignore
}

def main [module: path, fixture: path, cases_file: path] {
    let root = mktemp --directory | path expand --strict

    try {
        let cases = open $cases_file

        let bin = $root | path join bin

        mkdir $bin

        for name in (
            $cases
            | get prefix
            | each { first }
            | append [codex claude]
            | uniq
        ) {
            let path = $bin | path join $name

            (
                $'#!($nu.current-exe) --no-config-file' + "\n" + $'$env.EXTERN_TEST_COMMAND = "($name)"' + "\n" + (open --raw $fixture)
            ) | save $path

            ^chmod 700 $path
        }

        cd $root

        with-env {
            PATH: ($env.PATH | prepend $bin)
            EXTERN_ARGV: ($root | path join argv.jsonl)
            EXTERN_DATA: '{"name":"fixture"}'
            GIT_CONFIG_GLOBAL: /dev/null
            GIT_CONFIG_NOSYSTEM: '1'
            GIT_AUTHOR_NAME: 'Fixture Author'
            GIT_COMMITTER_NAME: 'Fixture Author'
            GIT_AUTHOR_EMAIL: fixture@example.invalid
            GIT_COMMITTER_EMAIL: fixture@example.invalid
        } {
            for case in $cases {
                let expected = match $case.kind {
                    array => { [{name: fixture}] }
                    objects => { [{name: fixture} {name: second}] }
                    record => { {name: fixture} }
                }
                let data = if $case.kind == objects { $expected | each { to json --raw } | str join "\n" } else { $expected | to json --raw }
                with-env {EXTERN_DATA: $data} {
                    let output = success $module $'($case.command) | collect | to json --raw' | from json
                    assert equal $output $expected $case.command
                    assert equal (last-arguments | take ($case.prefix | length)) $case.prefix $case.command
                }
            }
            for code in ['gh pr list' 'gh pr list | print' 'gh pr list | ^cat' '^gh pr list | str trim'] {
                assert equal (success $module $code | str trim) 'native text' $code
                assert equal (last-arguments) [gh pr list]
            }
            assert equal (success $module 'gh pr list | complete | to json --raw' | from json | get stdout) "native text\n"
            success $module 'gh pr list o> native.txt' | ignore
            assert equal (open --raw native.txt) "native text\n"
            assert equal (success $module 'gh --repo fixture/repo pr list | collect | to json --raw' | from json) 'native text'
            assert equal (success $module 'let runs = gh run list --limit 3; $runs.name | to json --raw' | from json) fixture
            assert equal (last-arguments | last 2) [--limit '3']
            let invalid = evaluate $module 'gh run list --limit invalid | collect'
            assert ($invalid.exit_code != 0)
            assert ($invalid.stderr | str contains int)
            for command in ['gh pr list' 'threads list' 'docker ps'] {
                with-env {EXTERN_FAIL: '1'} { assert ((evaluate $module $'($command) | collect' | get exit_code) != 0) }
                if $command != 'docker ps' {
                    with-env {EXTERN_BAD_JSON: '1'} { assert ((evaluate $module $'($command) | collect' | get exit_code) != 0) }
                }
            }
            with-env {EXTERN_EMPTY: '1'} {
                assert equal (success $module 'docker ps | collect | to json --raw' | from json) []
            }
            for command in ['git status' 'git log'] {
                let failed = evaluate $module $'($command) | collect'
                assert ($failed.exit_code != 0)
                assert ($failed.stderr | str contains 'not a git repository')
            }
            let repository = $root | path join repo
            mkdir $repository
            cd $repository
            init-repository
            assert equal (success $module 'git status | collect | to json --raw' | from json) []
            let target = "renamed \"file\"\nsecond line"
            git mv 'original file' $target | ignore
            "modified\n" | save --force tracked
            "new\n" | save 'new "file"'
            let rows = success $module 'git status | collect | to json --raw' | from json
            assert equal ($rows | where file == $target | first) {status: 'R ', file: $target, original_file: 'original file'}
            assert equal ($rows | where file == tracked | first | get status) ' M'
            assert equal ($rows | where file == 'new "file"' | first | get status) '??'
            assert equal (success $module 'git status --branch | collect | to json --raw' | from json) $rows
            assert equal (success $module 'git status -- tracked | collect | to json --raw' | from json | get file) [tracked]
            let dry_run = success $module 'git add --dry-run "new \"file\"" | complete | to json --raw' | from json
            assert equal $dry_run.exit_code 0
            assert ($dry_run.stdout | str contains 'new "file"')
            assert equal (git diff --cached --name-only -z) ($target + (char nul))
            let history = success $module 'git log -n 2 | collect | to json --raw' | from json
            assert equal ($history | length) 2
            assert equal $history.0.subject ''
            assert equal $history.1.subject 'subject | with "quotes"'
            assert equal $history.0.author 'Fixture Author'
            assert equal ($history.0.hash | str length) 40
            assert equal ($history.0.date | describe) string
            assert equal (success $module 'git log --grep absent-fixture-subject | collect | to json --raw' | from json) []
            assert equal (success $module 'git log --oneline -n 1 | complete | to json --raw' | from json | get stdout) (git log --oneline -n 1)
            git branch fixture-branch | ignore
            for case in [
                {command: 'git switch fixture-', expected: fixture-branch}
                {command: 'gh pr list --lim', expected: --limit}
                {command: 'codex res', expected: 'codex resume'}
                {command: 'codex resume --la', expected: --last}
                {command: 'claude --res', expected: --resume}
                {command: 'threads --a', expected: --all}
                {command: 'threads res', expected: 'threads resume'}
                {command: 'threads resume --in co', expected: codex}
                {command: 'atuin threads resume --in cl', expected: claude-code}
                {command: 'threads list --style js', expected: json}
                {command: 'threads search fixture --harness cl', expected: claude-code}
                {command: 'threads search fixture --harness cop', expected: copilot}
            ] {
                let output = success $module $'($case.command | to json --raw) | commandline complete | to json --raw' | from json
                assert ($case.expected in $output) $case.command
            }
            let dynamic = '$env.config.completions.external.enable = true; $env.config.completions.external.completer = {|place| if $place.command == ["kubectl get" "fixture-"] { ["fixture-pod"] } else { [] }}; "kubectl get fixture-" | commandline complete | to json --raw'
            assert (success $module $dynamic | str contains fixture-pod)
            success $module 'threads resume fixture --in codex --print' | ignore
            assert equal (last-arguments) [atuin threads resume fixture --in codex --print]
            for case in [
                {command: 'codex resume fixture --last', expected: [codex resume fixture --last]}
                {command: 'claude --resume fixture', expected: [claude --resume fixture]}
            ] {
                assert equal (success $module $case.command | str trim) 'native text'
                assert equal (last-arguments) $case.expected
            }
        }
    } catch {|failure|
        cd ($root | path dirname)

        rm --recursive --force $root

        error make $failure
    }

    cd ($root | path dirname)

    rm --recursive --force $root

    print 'Structured external output, native escapes, Git records, failures, and completion checks passed'
}
