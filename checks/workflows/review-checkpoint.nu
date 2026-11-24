use std/assert
use ../lib/process.nu [checked-command with-fixture]

def main [script: path] {
    with-fixture {|root|
        let repo = $root | path join repo
        let linked = $root | path join linked
        mkdir $repo
        cd $repo

        let git = {|args| checked-command git ...$args | str trim}
        let checkpoint = {|action| checked-command $nu.current-exe --no-config-file $script $action}

        do $git [init --quiet '--template='] | ignore
        "value = 1\n" | save code
        "scratch\n" | save .gitignore
        do $git [add .] | ignore
        do $git [-c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m base] | ignore

        "value = 2\n" | save --force code
        do $git [add code] | ignore
        "value = 3\n" | save --force code
        "untracked baseline\n" | save notes
        "ignored content\n" | save scratch
        let tree = do $checkpoint mark | str trim

        assert equal (do $checkpoint diff) ''

        "value = 4   \n" | save --force code
        "untracked revised\n" | save --force notes
        "new file\n" | save 'another file'
        let index = open --raw .git/index

        let patch = do $checkpoint diff
        assert ($patch | str contains '-value = 3')
        assert ($patch | str contains '+value = 4   ')
        assert ($patch | str contains '-untracked baseline')
        assert ($patch | str contains '+untracked revised')
        assert ($patch | str contains '+new file')
        assert (not ($patch | str contains 'scratch'))

        let formatted = open --raw code | ^git stripspace
        $formatted | save --force code
        assert ((do $checkpoint diff) | str contains "+value = 4\n")
        assert equal (open --raw .git/index) $index
        assert equal (do $git [show :code]) 'value = 2'

        do $git [worktree add --quiet --detach $linked HEAD] | ignore
        do {
            cd $linked
            let missing = ^$nu.current-exe --no-config-file $script diff | complete
            assert ($missing.exit_code != 0)
            assert ($missing.stderr | str contains 'No review checkpoint')
            do $checkpoint mark | ignore
            do $checkpoint clear | ignore
        }
        assert equal (do $git [rev-parse refs/worktree/sysinit/review]) $tree
        do $checkpoint clear | ignore
        let cleared = ^$nu.current-exe --no-config-file $script diff | complete
        assert ($cleared.exit_code != 0)
    }
}
