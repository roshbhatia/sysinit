use std/assert

def main [fragment: path] {
    let root = mktemp -d | path expand --strict

    try {
        for name in [first second] {
            let folder = $root | path join $name

            mkdir $folder

            ^touch -d @1 $folder
        }

        let profile = $root | path join profile

        ^ln -s ($root | path join first) $profile

        let script = $root | path join test.zsh

        (
            'autoload() { :; }' + "\n" + 'compinit() { print -r -- $1; touch $ZSH_CACHE_DIR/zcompdump/.zcompdump; }' + "\n" + (
                open --raw $fragment
                | str replace '/etc/profiles/per-user/$USERNAME' $profile
            )
        ) | save $script

        with-env {HOME: $root, ZSH_CACHE_DIR: ($root | path join cache)} {
            assert equal (^zsh -f $script | str trim) '-d'
            assert equal (^zsh -f $script | str trim) '-C'
            rm $profile
            ^ln -s ($root | path join second) $profile
            assert equal (^zsh -f $script | str trim) '-d'
            assert equal (^zsh -f $script | str trim) '-C'
        }
    } catch {|failure|
        rm -rf $root

        error make $failure
    }

    rm -rf $root

    print 'completion cache follows profile generations, including fixed timestamps'
}
