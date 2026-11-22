const checkpoint = 'refs/worktree/sysinit/review'

def --wrapped git-output [...args: string] {
    let result = ^git ...$args | complete

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim | default --empty 'Git failed')
        }
    }

    $result.stdout | str replace --regex '\n$' ''
}

def snapshot [] {
    let index = git-output rev-parse --path-format=absolute --git-path index

    let temporary = mktemp --directory

    let alternate = $temporary | path join index

    let tree = try {
        if ($index | path exists) { cp --preserve [timestamps] $index $alternate }

        with-env {GIT_INDEX_FILE: $alternate} {
            git-output add --all -- . | ignore
            git-output write-tree
        }
    } catch {|failure|
        rm --recursive $temporary

        error make $failure
    }

    rm --recursive $temporary

    $tree
}

def 'main mark' [] {
    cd (git-output rev-parse --show-toplevel)

    let tree = snapshot

    git-output update-ref $checkpoint $tree | ignore

    $tree
}

def 'main diff' [] {
    cd (git-output rev-parse --show-toplevel)

    let baseline = try {
        git-output rev-parse --verify $'($checkpoint)^{tree}'
    } catch {
        error make {msg: 'No review checkpoint in this worktree. Run review-checkpoint mark first.'}
    }

    let current = snapshot

    ^git --no-pager diff --binary --no-color --no-ext-diff --no-textconv --src-prefix=a/ --dst-prefix=b/ $baseline $current --
}

def 'main clear' [] {
    cd (git-output rev-parse --show-toplevel)

    git-output update-ref -d $checkpoint | ignore
}

def main [] {
    print 'Usage: review-checkpoint mark | diff | clear'
}
