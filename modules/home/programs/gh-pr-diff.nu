const script = path self

def git-command [directory: path, arguments: list<string>] {
    ^git -C $directory ...$arguments

    if $env.LAST_EXIT_CODE != 0 { error make {msg: 'Git review preparation failed'} }
}

def api [endpoint: string] {
    let response = ^gh api $endpoint | complete

    if $response.exit_code != 0 { error make {msg: 'GitHub API request failed'} }

    $response.stdout | from json --strict
}

def revision [value] {
    if ($value | describe) != string or $value !~ '^[0-9a-f]{40}$' { error make {msg: 'GitHub returned an invalid commit ID'} }

    $value
}

def main [
    url: string
    --tool: string = nvim
    --history
    --overview
    --lock-held
] {
    let parsed = $url | parse --regex '^https://github\.com/(?P<owner>[A-Za-z0-9-]+)/(?P<repo>[A-Za-z0-9_.-]+)/pull/(?P<number>[1-9][0-9]*)$'

    if ($parsed | is-empty) or $parsed.0.repo in ['.' '..'] { error make {msg: 'Expected https://github.com/owner/repo/pull/number'} }

    if $tool not-in [
        nvim
        atlas
        diffview
        changes
        hunk
        tuicr
    ] { error make {msg: 'Unknown review tool'} }

    if $history and $tool != nvim { error make {msg: '--history uses Neovim'} }

    if $overview and ($history or $tool != nvim) { error make {msg: '--overview uses the GitHub review view in Neovim'} }

    let pr = $parsed | first

    let state = $env.XDG_STATE_HOME? | default ($env.HOME | path join .local state)

    let directory = $state | path join gh-dash reviews ($pr.owner | str lowercase) ($pr.repo | str lowercase) $pr.number

    mkdir $directory

    if not $lock_held {
        let options = [--lock-held --tool $tool] | append (if $history { [--history] } else { [] }) | append (if $overview { [--overview] } else { [] })

        ^flock --exclusive --nonblock --conflict-exit-code 73 $'($directory).lock' $nu.current-exe --no-config-file $script $url ...$options

        let status = $env.LAST_EXIT_CODE

        if $status == 73 { print --stderr 'This PR already has an open diff viewer' }

        exit $status
    }

    cd $directory

    let repository = $'https://github.com/($pr.owner)/($pr.repo).git'

    if $tool == hunk {
        if ($env.GH_TOKEN? | default '') == '' and ($env.GITHUB_TOKEN? | default '') == '' {
            let auth = ^gh auth token --hostname github.com | complete

            if $auth.exit_code != 0 or ($auth.stdout | str trim | is-empty) { error make {msg: 'GitHub CLI could not provide an authentication token'} }

            $env.GH_TOKEN = $auth.stdout | str trim
        }

        ^hunk gh pr $url

        exit $env.LAST_EXIT_CODE
    }

    git-command $directory [init --quiet '--template=']

    if $tool == tuicr {
        let remotes = ^git remote | lines

        git-command $directory [
            remote
            (if origin in $remotes { 'set-url' } else { 'add' })
            origin
            $repository
        ]

        ^tuicr pr $pr.number

        exit $env.LAST_EXIT_CODE
    }

    let endpoint = $'repos/($pr.owner)/($pr.repo)'

    let pull = api $'($endpoint)/pulls/($pr.number)'

    let base = revision $pull.base.sha

    let head = revision $pull.head.sha

    let comparison = api $'($endpoint)/compare/($base)...($head)'

    let merge_base = revision $comparison.merge_base_commit.sha

    let depth = if $history {
        if ($directory | path join .git shallow | path exists) { [--unshallow] } else { [] }
    } else {
        ['--depth=1']
    }

    git-command $directory (
        [fetch --quiet --no-tags]
        | append $depth
        | append [$repository $merge_base $head]
    )

    git-command $directory [update-ref HEAD $merge_base]

    git-command $directory [update-ref refs/pr/head $head]

    git-command $directory [read-tree $head]

    if $tool == changes {
        ^changes interactive --staged
    } else {
        let range = $'($merge_base)..($head)'

        let action = if $tool == atlas {
            $'Atlas review ($url)'
        } else if $tool == nvim and not $history {
            $'(if $overview { 'PRReview!' } else { 'PRReview' }) ($url)'
        } else if $history {
            $'DiffviewFileHistory --range=($range)'
        } else {
            $'DiffviewOpen ($range)'
        }

        ^nvim -n --cmd 'let g:sysinit_pr_review = v:true' -c $action
    }

    exit $env.LAST_EXIT_CODE
}
