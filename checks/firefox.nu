use std/assert

def main [fixtures: path, tridactyl: path] {
    for fixture in (open --raw $fixtures | from json) {
        for name in [chrome content tridactyl newtab] {
            let css = $fixture | get $name
            assert not ($css =~ '@(?:base\w+|opacity|blur|monospace-font|sans-font)\s*@') $name
            assert not ($css | str contains 'var(--sysinit-') $name
            assert ($css | str contains ('#' + $fixture.background)) $name
        }
        assert (
            'HomepageURL' not-in $fixture.policies and 'NewTabURL' not-in $fixture.policies
        )
        assert equal $fixture.policies.Homepage.StartPage previous-session
    }
    mut bindings = []
    for line in (
        open --raw $tridactyl
        | lines
        | where {|line| $line | str starts-with 'bind '}
    ) {
        let fields = $line | split row --regex '\s+' | skip 1
        let explicit_mode = $fields.0 | str starts-with '--mode='
        let mode = if $explicit_mode {
            $fields.0 | str replace '--mode=' ''
        } else {
            'normal'
        }
        let fields = if $explicit_mode {
            $fields | skip 1
        } else {
            $fields
        }
        let key = $fields.0 | parse --regex '(?<token><[^>]+>|.)' | get token
        for other in ($bindings | where mode == $mode) {
            assert ($key != $other.key) $'($mode): ($key | to nuon): duplicate'
            let length = [
                ($key | length)
                ($other.key | length)
            ] | math min
            assert (($key | first $length) != ($other.key | first $length)) $'($mode): ($key | to nuon): prefix collision with ($other.key | to nuon)'
        }
        $bindings = $bindings | append {mode: $mode, key: $key, command: ($fields | skip 1 | str join ' ')}
    }
    let normal = $bindings | where mode == normal
    assert ($normal | all {|binding| $binding.key not-in [['<A-p>'] ['<A-m>']]})
    assert equal (
        $normal
        | where {|binding| $binding.key == ['<Space>' t u]}
        | first
        | get command
    ) undo
    print 'Rendered themes and scoped binding prefixes passed'
}
