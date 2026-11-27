use ../git/review-checkpoint.nu snapshot
use ./hook-event.nu normalize
use ./turn-history.nu [retain-turn prune-turns]
use ./timing.nu review-timing

def link-directory [] {
    $env.XDG_STATE_HOME? | default ($env.HOME | path join .local state) | path join agent-diff links
}

def review-target [directory: path] {
    let git = ^git -C $directory rev-parse --path-format=absolute --show-toplevel --git-common-dir --git-dir | complete

    if $git.exit_code != 0 {
        return {
            directory: $directory
            labels: [
                ($directory | path basename)
            ]
        }
    }

    let paths = $git.stdout | lines

    let root = $paths.0 | path expand --strict

    let repository = $paths.1 | path dirname | path basename

    let checkout = if $paths.1 != $paths.2 {
        $root | path basename
    } else {
        let branch = ^git -C $root symbolic-ref --quiet --short HEAD | complete

        if $branch.exit_code == 0 {
            $branch.stdout | str trim
        } else {
            ^git -C $root rev-parse --short HEAD | str trim
        }
    }

    {
        directory: $root
        labels: [$repository $checkout]
    }
}

def review-link [cwd: path] {
    let directory = $cwd | path expand --strict

    if ($directory | path type) != dir { return }

    let target = review-target $directory

    let id = $target.directory | hash sha256 | str substring 0..<16

    let links = link-directory

    let path = $links | path join $id

    if not ($path | path exists) {
        mkdir $links

        ^chmod 700 $links

        ^ln -sT -- $target.directory $path | complete | ignore
    }

    if ($path | path expand --strict) == $target.directory {
        let labels = $target.labels | each {|name|
            $name | url encode --all
            | str replace --all '%2D' '-'
            | str replace --all '%2E' '.'
            | str replace --all '%5F' '_'
            | str replace --all '%7E' '~'
        } | str join '/'

        $"review://changes/($labels)/($id)"
    }
}

def resolve-link [uri: string] {
    let parts = $uri | parse --regex '^review://(?:(?:changes/(?:[A-Za-z0-9._~%-]+/){1,2})|worktree/)?(?<id>[0-9a-f]{16})(?:\?turn=(?<turn>[0-9a-f]{16}))?$'

    if ($parts | is-empty) {
        error make {msg: 'Invalid review link'}
    }

    let directory = try {
        link-directory | path join $parts.0.id | path expand --strict
    } catch {
        error make {msg: 'The review checkout is unavailable'}
    }

    if ($directory | path type) != dir {
        error make {msg: 'The review checkout is unavailable'}
    }

    {
        directory: $directory
        turn: ($parts.0.turn | default --empty null)
    }
}

def turn-link [baseline: record, tree: string] {
    cd $baseline.directory

    if $tree == $baseline.tree { return }

    let link = review-link $baseline.directory

    let turn = retain-turn (link-directory) $baseline.directory $baseline.tree $tree

    let changed = ^git diff --name-only -z $baseline.tree $tree -- | complete

    let files = if $changed.exit_code == 0 {
        $changed.stdout | split row (char nul) | where {|path| $path != ''} | length
    }

    {
        uri: $"($link)?turn=($turn)"
        files: $files
    }
}

def notice [link: record, title: string] {
    let files = $link.files?

    let scope = match $files {
        null => $title
        1 => $"($title) · 1 file"
        _ => $"($title) · ($files) files"
    }

    let label = if ($env.WEZTERM_PANE? | default '') =~ '^\d+$' {
        $"($scope) · ⌘-click below"
    } else {
        $scope
    }

    let rule = '----------------------------------------'

    {
        systemMessage: ([$rule $label $link.uri $rule] | str join "\n")
    } | to json --raw
}

def main [
    target: string = '.'
    --hook
    --harness: string = 'legacy'
    --resolve
    --json
    --prune
] {
    if $resolve {
        let resolved = resolve-link $target

        return (
            if $json {
                $resolved | to json --raw
            } else {
                $resolved.directory
            }
        )
    }

    if $prune {
        let checkout = ^git -C $target rev-parse --show-toplevel | str trim

        prune-turns (link-directory) ($checkout | path expand --strict) --force

        return
    }

    if not $hook { return (review-link $target) }

    let input = $in

    try {
        let event = normalize ($input | from json --strict) $harness

        if $event == null { return }

        let session = $event.session

        let pending = link-directory | path join turns

        let marker = $pending | path join ($session | hash sha256)

        let baseline_path = $'($marker).baseline.json'

        match $event.phase {
            'start' => {
                rm --force $marker $baseline_path

                let cwd = $event.cwd

                let root = ^git -C $cwd rev-parse --show-toplevel | complete

                if $root.exit_code == 0 {
                    let directory = $root.stdout | str replace --regex '\n$' '' | path expand --strict

                    cd $directory

                    let started = date now

                    let tree = snapshot

                    review-timing 'prompt-snapshot' $started

                    mkdir $pending

                    ^chmod 700 (link-directory)

                    {directory: $directory, tree: $tree} | to json --raw | save $baseline_path
                }

                return
            }
            'stop' => {
                let link = if ($baseline_path | path exists) {
                    let baseline = open $baseline_path

                    cd $baseline.directory

                    let started = date now

                    let tree = snapshot

                    review-timing 'turn-snapshot' $started

                    let link = turn-link $baseline $tree

                    rm --force $baseline_path $marker

                    try {
                        prune-turns (link-directory) $baseline.directory
                    } catch {|failure|
                        print -e $"agent-review-link: ($failure.msg)"
                    }

                    $link
                } else if ($marker | path exists) {
                    let link = open --raw $marker

                    rm $marker

                    {uri: $link}
                }

                if $link == null { return }

                return (notice $link 'Review turn edits')
            }
            'edit' => { }
        }

        if ($baseline_path | path exists) {
            let baseline = open $baseline_path

            let previous = if ($marker | path exists) { open --raw $marker } else { $baseline.tree }

            cd $baseline.directory

            let started = date now

            let tree = snapshot

            review-timing 'edit-snapshot' $started

            let link = turn-link ($baseline | update tree $previous) $tree

            if $link != null {
                $tree | save --force $marker

                return (notice $link 'Review edit')
            }
        } else if not ($marker | path exists) {
            let link = review-link ($event.cwd)

            if $link != null {
                mkdir $pending

                $link | save --force $marker

                return (notice {uri: $link} 'Review edit')
            }
        }
    } catch {|failure|
        print -e $"agent-review-link: ($failure.msg)"
    }
}
