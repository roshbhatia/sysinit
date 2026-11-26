use ../../../git/review-checkpoint.nu snapshot

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
    let parts = $uri | parse --regex '^review://(?:(?:changes/(?:[A-Za-z0-9._~%-]+/){1,2})|worktree/)?(?<id>[0-9a-f]{16})(?:\?turn=[0-9a-f]{16})?$'

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

    $directory
}

def turn-link [baseline: record] {
    cd $baseline.directory

    let tree = snapshot

    if $tree == $baseline.tree { return }

    let link = review-link $baseline.directory

    let turn = [$baseline.tree $tree] | str join ':' | hash sha256 | str substring 0..<16

    let ref = $'refs/worktree/sysinit/turn-reviews/($turn)'

    # Keep both trees reachable for links read after later edits or Git maintenance.
    let updated = $"update ($ref)/before ($baseline.tree)\nupdate ($ref)/after ($tree)\n" | ^git update-ref --stdin | complete

    if $updated.exit_code == 0 { $"($link)?turn=($turn)" }
}

def main [target: string = '.', --hook, --resolve] {
    if $resolve { return (resolve-link $target) }

    if not $hook { return (review-link $target) }

    let input = $in

    try {
        let event = $input | from json --strict

        let session = $event.session_id? | default ''

        if $session == '' { return }

        let pending = link-directory | path join turns

        let marker = $pending | path join ($session | hash sha256)

        let baseline_path = $'($marker).baseline.json'

        match $event.hook_event_name? {
            'UserPromptSubmit' => {
                rm --force $marker $baseline_path

                let cwd = $event.cwd? | default $env.PWD

                let root = ^git -C $cwd rev-parse --show-toplevel | complete

                if $root.exit_code == 0 {
                    let directory = $root.stdout | str replace --regex '\n$' '' | path expand --strict

                    cd $directory

                    let tree = snapshot

                    mkdir $pending

                    ^chmod 700 (link-directory)

                    {directory: $directory, tree: $tree} | to json --raw | save $baseline_path
                }

                return
            }
            'Stop' => {
                let link = if ($baseline_path | path exists) {
                    let baseline = open $baseline_path

                    rm $baseline_path

                    turn-link $baseline
                } else if ($marker | path exists) {
                    let link = open --raw $marker

                    rm $marker

                    $link
                }

                if $link == null { return }

                let scope = if ($link | str contains '?turn=') {
                    'Review changes from this turn'
                } else {
                    'Review changes'
                }

                let label = if ($env.WEZTERM_PANE? | default '') =~ '^\d+$' {
                    $"($scope) · ⌘-click below"
                } else {
                    $scope
                }

                let rule = '----------------------------------------'

                return ({
                    systemMessage: ([$rule $label $link $rule] | str join "\n")
                } | to json --raw)
            }
            'PostToolUse' => { }
            _ => { return }
        }

        let edited = match $event.tool_name? {
            'apply_patch' => {
                let response = $event.tool_response? | default ''

                let succeeded = $response | str starts-with "Exit code: 0\n"

                $succeeded and ($response | str contains 'Success. Updated the following files:')
            }
            'Edit' | 'Write' | 'MultiEdit' => { ($event.tool_input.file_path? | default '') != '' }
            'NotebookEdit' => { ($event.tool_input.notebook_path? | default '') != '' }
            _ => false
        }

        if $edited and not ($baseline_path | path exists) {
            let link = review-link ($event.cwd? | default $env.PWD)

            if $link != null {
                mkdir $pending

                $link | save --force $marker
            }
        }
    }
}
