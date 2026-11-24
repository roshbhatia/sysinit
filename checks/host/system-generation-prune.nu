use std/assert
use ../lib/process.nu checked-command

def fixture [root: path, name: string] {
    let input = $root | path join inputs $name

    mkdir $input

    $name | save ($input | path join marker)

    checked-command nix-store --add $input | str trim
}

def prune [
    script: path
    profiles: path
    current: path
    backend: path
] {
    checked-command bash $script ($profiles | path join system) $current $backend (which readlink | first | get path) (which sleep | first | get path) 1 0 | ignore
}

def target [file: path] {
    checked-command readlink $file | str trim
}

def main [
    script: path
    racer: path
    hello: path
    jq: path
    coreutils: path
    bash: path
] {
    let root = $env.TMPDIR | path expand | path join system-generation-prune

    mkdir ($root | path join config)

    $env.NIX_CONF_DIR = $root | path join config

    $env.NIX_USER_CONF_FILES = '/dev/null'

    $env.NIX_CONFIG = ''

    $env.NIX_REMOTE = $'local?root=($root)/store'

    let first = fixture $root first

    let second = fixture $root second

    let third = fixture $root third

    let profiles = $root | path join nix/var/nix/profiles

    let current = $root | path join run/current-system

    mkdir $profiles ($current | path dirname)

    for value in [$first $second $third] {
        checked-command nix-env --profile ($profiles | path join system) --set $value | ignore
    }

    ^ln -s (target ($profiles | path join system-3-link)) $current

    let backend = which nix-env | first | get path

    prune $script $profiles $current $backend

    assert equal (target ($profiles | path join system)) system-3-link

    assert equal (target ($profiles | path join system-3-link)) (target $current)

    for generation in [1 2] {
        assert (
            $profiles
            | path join $'system-($generation)-link'
            | path type
            | is-empty
        )
    }

    checked-command nix-env --profile ($profiles | path join system) --set $first | ignore

    rm $current

    ^ln -s (target ($profiles | path join system-3-link)) $current

    prune $script $profiles $current $backend

    assert equal (target ($profiles | path join system)) system-4-link

    for generation in [3 4] {
        assert equal ($profiles | path join $'system-($generation)-link' | path type) symlink
    }

    let race = $env.TMPDIR | path join system-generation-race

    let profiles = $race | path join nix/var/nix/profiles

    let current = $race | path join run/current-system

    mkdir $profiles ($current | path dirname)

    for entry in ([$hello $jq $coreutils] | enumerate) {
        ^ln -s $entry.item ($profiles | path join $'system-($entry.index + 1)-link')
    }

    ^ln -s system-3-link ($profiles | path join system)

    ^ln -s $coreutils $current

    with-env {RACE_NEW_TARGET: $bash} { prune $script $profiles $current $racer }

    assert equal (target ($profiles | path join system)) system-4-link

    assert equal (target ($profiles | path join system-3-link)) (target $current)

    assert equal ($profiles | path join system-4-link | path type) symlink

    for generation in [1 2] {
        assert (
            $profiles
            | path join $'system-($generation)-link'
            | path type
            | is-empty
        )
    }
}
