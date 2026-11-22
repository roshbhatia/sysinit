use std/assert

def --wrapped git-command [directory: path, ...arguments: string] {
    let result = ^git -C $directory ...$arguments | complete

    assert equal $result.exit_code 0 $result.stderr

    $result.stdout | str trim
}

def review [script: path, url: string, arguments: list<string> = []] {
    let result = ^$nu.current-exe --no-config-file $script $url ...$arguments | complete

    assert equal $result.exit_code 0 $result.stderr

    $result
}

def queue [
    functions: path
    message: string
    response: string
    arguments: list<string> = []
    --code: int = 0
] {
    with-env {ASK_RESPONSE: $response, ASK_EXIT: ($code | into string)} {
        let expression = $'use ($functions | to json --raw) *; ($message | to json --raw) | prq ($arguments | str join " ")' + (if '--dry-run' in $arguments { ' | to json --raw' } else { '' })
        ^$nu.current-exe --no-config-file -c $expression | complete
    }
}

def check [
    script: path
    terminal: path
    functions: path
    root: path
] {
    let source = $root | path join source

    mkdir $source

    git-command $source init --quiet '--template=' | ignore

    "base\n" | save ($source | path join base.txt)

    git-command $source add . | ignore

    git-command $source commit --quiet -m base | ignore

    let base = git-command $source rev-parse HEAD

    for text in [first second] {
        $text | save --force ($source | path join change.txt)

        git-command $source add . | ignore

        git-command $source commit --quiet -m 'PR change' | ignore
    }

    let head = git-command $source rev-parse HEAD

    {base: $base, head: $head} | to json | save ($root | path join revisions.json)

    ^git config --file $env.GIT_CONFIG_GLOBAL $'url.file://($source).insteadOf' https://github.com/one/repo.git

    assert equal $env.LAST_EXIT_CODE 0

    let url = 'https://github.com/one/repo/pull/1'

    let directory = $env.XDG_STATE_HOME | path join gh-dash reviews one repo 1

    review $script $url [--tool changes] | ignore

    assert equal (open ($directory | path join observed.json)) {files: 'change.txt', head: $base}

    git-command $directory notes add -m 'Keep this review note' $head | ignore

    review $script $url [--history] | ignore

    assert equal (git-command $directory rev-list --count $head) '3'

    assert equal (git-command $directory notes show $head) 'Keep this review note'

    assert (
        $'DiffviewFileHistory --range=($base)..($head)' in (open ($directory | path join editor.json))
    )

    for entry in [
        {
            tool: nvim
            flags: []
            action: $'PRReview ($url)'
        }
        {
            tool: nvim
            flags: [--overview]
            action: $'PRReview! ($url)'
        }
        {
            tool: diffview
            flags: []
            action: $'DiffviewOpen ($base)..($head)'
        }
    ] {
        review $script $url ([--tool $entry.tool] | append $entry.flags) | ignore

        assert equal (open ($directory | path join editor.json)) [-n --cmd 'let g:sysinit_pr_review = v:true' -c $entry.action]
    }

    assert equal (git-command $source status --porcelain) ''

    rm --force ($root | path join gh-calls)

    for invalid in [
        'https://github.com/o/r/issues/1'
        'https://github.com/o/../pull/1'
        'https://github.com/o/r/pull/1;echo'
    ] {
        let result = ^$nu.current-exe --no-config-file $script $invalid | complete

        assert ($result.exit_code != 0)
    }

    let retired = ^$nu.current-exe --no-config-file $script $url --tool atlas | complete

    assert ($retired.exit_code != 0)

    assert ($retired.stderr | str contains 'Unknown review tool')

    assert (not ($root | path join gh-calls | path exists))

    let lock = $'($directory).lock'

    let fixture = $env.REVIEW_TOOLS

    let holder = job spawn --auto-kill { ^flock --exclusive $lock $nu.current-exe --no-config-file $fixture lock }

    let conflict = try {
        let deadline = (date now) + 5sec

        while not ($root | path join lock-ready | path exists) {
            assert ((date now) < $deadline) 'Timed out acquiring fixture review lock'

            sleep 10ms
        }

        ^$nu.current-exe --no-config-file $script $url --tool hunk | complete
    } catch {|failure|
        touch ($root | path join lock-release)

        try { job kill $holder }

        error make $failure
    }

    touch ($root | path join lock-release)

    let released = ^flock --exclusive --timeout 5 $lock true | complete

    assert equal $released.exit_code 0 'Timed out waiting for the fixture review lock to be released'

    assert equal $conflict.exit_code 73

    review $script $url [--tool hunk] | ignore

    assert equal (open ($directory | path join hunk.json)) {arguments: [gh pr $url], authenticated: true, explicit: null}

    assert (not ($env | columns | any {|column| $column == GH_TOKEN}))

    rm ($root | path join gh-calls)

    let explicit = with-env {GITHUB_TOKEN: explicit-fixture-token, HUNK_EXIT: '7'} {
        ^$nu.current-exe --no-config-file $script $url --tool hunk | complete
    }

    assert equal $explicit.exit_code 7

    assert equal (open ($directory | path join hunk.json) | get explicit) explicit-fixture-token

    assert (not ($root | path join gh-calls | path exists))

    review $script $url [--tool tuicr] | ignore

    assert equal (git-command $directory remote get-url origin) $'file://($source)'

    assert equal (open ($directory | path join tuicr.json)) [pr '1']

    let request = {
        prompt: 'Extract URLs'
        input: data
        model: opus
        schema: {type: object}
    }

    for envelope in [
        {action: inference.generate, request: $request}
        {
            action: models.list
            request: {}
        }
    ] {
        let result = $envelope | to json --raw | ^$nu.current-exe --no-config-file --stdin $terminal provider 'quoted argument' '' | complete

        assert equal $result.exit_code 0 $result.stderr

        let output = $result.stdout | from json --strict

        assert equal $output.arguments ['quoted argument' '']

        if $envelope.action == inference.generate {
            assert ($output.envelope.request.prompt | str contains 'terminal pipeline')

            assert equal ($output.envelope.request | reject prompt) ($request | reject prompt)
        } else {
            assert equal $output.envelope $envelope
        }
    }

    let propagated = with-env {PROVIDER_EXIT: '9'} {
        {action: models.list, request: {}} | to json --raw | ^$nu.current-exe --no-config-file --stdin $terminal provider | complete
    }

    assert equal $propagated.exit_code 9

    let response = {
        urls: [$url]
    } | to json --raw

    for arguments in [
        [--dry-run]
        [--dry-run]
        [--dry-run --refresh]
    ] {
        let result = queue $functions $url $response $arguments

        assert equal $result.exit_code 0 $result.stderr
    }

    assert equal (open --raw ($root | path join ask-calls) | lines | length) 2

    let changed = queue $functions $'Please review ($url)' $response [--dry-run]

    assert equal $changed.exit_code 0 $changed.stderr

    assert equal (open --raw ($root | path join ask-calls) | lines | length) 3

    for cache in (glob ($env.XDG_CACHE_HOME | path join '**/*.json')) {
        'not JSON' | save --force $cache
    }

    let malformed_cache = queue $functions $url $response [--dry-run]

    assert equal $malformed_cache.exit_code 0 $malformed_cache.stderr

    assert equal (open --raw ($root | path join ask-calls) | lines | length) 4

    let urls = [$url 'https://github.com/two/repo/pull/22']

    let message = "<github.com/one/repo/pull/1|link>\nhttps://github.com/two/repo/pull/22/files?x=y"

    let deduplicated = queue $functions $message ({
        urls: ($urls | append $url)
    } | to json --raw)

    assert equal $deduplicated.exit_code 0 $deduplicated.stderr

    assert equal (
        open --raw ($root | path join gh-calls)
        | lines
        | each { from json --strict }
    ) ($urls | each {|url| [dash $url]})

    rm ($root | path join gh-calls)

    for entry in [
        {
            response: (
                {
                    urls: [$url 'https://github.com/other/repo/pull/2']
                }
                | to json --raw
            )
            code: 0
        }
        {response: 'not JSON', code: 0}
        {response: '{"urls":[]}', code: 1}
    ] {
        let result = queue $functions $url $entry.response [--refresh] --code $entry.code

        assert ($result.exit_code != 0)

        assert (not ($root | path join gh-calls | path exists))
    }

    let dry = queue $functions $url $response [--dry-run --refresh]

    assert equal $dry.exit_code 0 $dry.stderr

    assert equal ($dry.stdout | from json) [$url]

    let empty = queue $functions 'No pull requests here' '{"urls":[]}'

    assert equal $empty.exit_code 0 $empty.stderr

    assert (not ($root | path join gh-calls | path exists))
}

def main [
    script: path
    terminal: path
    functions: path
    fixture: path
] {
    let script = $script | path expand --strict

    let terminal = $terminal | path expand --strict

    let functions = $functions | path expand --strict

    let fixture = $fixture | path expand --strict

    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    let bin = $root | path join bin

    mkdir $bin

    for tool in [
        gh
        changes
        nvim
        hunk
        tuicr
        provider
        ask
    ] {
        let command = [
            'exec'
            ($nu.current-exe | to json --raw)
            '--no-config-file --stdin'
            ($fixture | to json --raw)
            $tool
            '"$@"'
        ] | str join ' '

        $"#!/bin/sh\n($command)\n" | save ($bin | path join $tool)

        chmod +x ($bin | path join $tool)
    }

    try {
        with-env {
            PATH: ($env.PATH | prepend $bin)
            REVIEW_FIXTURE: $root
            REVIEW_TOOLS: $fixture
            XDG_CACHE_HOME: ($root | path join cache)
            XDG_STATE_HOME: ($root | path join state)
            GIT_CONFIG_GLOBAL: ($root | path join gitconfig)
            GIT_CONFIG_NOSYSTEM: '1'
            GIT_AUTHOR_NAME: Test
            GIT_AUTHOR_EMAIL: test@example.invalid
            GIT_COMMITTER_NAME: Test
            GIT_COMMITTER_EMAIL: test@example.invalid
        } {
            hide-env --ignore-errors GH_TOKEN GITHUB_TOKEN
            check $script $terminal $functions $root
        }
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'PR review revisions, notes, tools, credentials, provider protocol and queue/cache boundaries passed'
}
