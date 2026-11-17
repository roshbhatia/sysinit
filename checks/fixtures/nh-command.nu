use std/assert

def --wrapped main [...arguments: string] {
    if $env.NH_TEST_COMMAND == elevate {
        let command = $arguments | first
        exec $command ...($arguments | skip 1)
    }
    (([$env.NH_TEST_COMMAND] | append $arguments | to json --raw) + "\n") | save --append $env.NH_TEST_LOG
    if $env.NH_TEST_COMMAND == darwin-rebuild {
        assert equal $arguments [activate]
        assert equal $env.HOME /var/root
    } else if '--version' in $arguments {
        print 'nix (Nix) 2.34.0'
    } else if 'experimental-features' in $arguments {
        print 'nix-command flakes'
    } else if 'build' in $arguments {
        if '--profile' in $arguments {
            let profile = $arguments | enumerate | where item == '--profile' | first | get index
            assert equal ($arguments | get ($profile + 1)) /nix/var/nix/profiles/system
            assert equal ($arguments | last) $env.NH_TEST_TARGET
            assert equal $env.HOME /var/root
        } else {
            if ($env.NH_TEST_FAIL? | default '') != '' { exit 23 }
            let link = $arguments | enumerate | where item == '--out-link' | first | get index
            ^ln -s $env.NH_TEST_TARGET ($arguments | get ($link + 1))
        }
    } else { error make {msg: $'unexpected Nix arguments: ($arguments | to nuon)'} }
}
