use std/assert
use lib/process.nu checked-command

def main [
    lua: path
    root: path
    configuration: path
    environment: path
] {
    let forbidden = glob ($lua | path join '**/*.lua') | where {|file|
        (open --raw $file) =~ 'roster|tether|refresh_catalogs'
    }

    assert ($forbidden | is-empty) $'WezTerm performs catalog discovery or transport negotiation: ($forbidden)'

    mkdir ($env.XDG_CONFIG_HOME | path join wezterm)

    cp $configuration ($env.XDG_CONFIG_HOME | path join wezterm/config.json)

    cp $environment ($env.XDG_CONFIG_HOME | path join wezterm/env.json)

    let marker = $env.TMPDIR | path join tab-passed

    let keys = with-env {SYSINIT_WEZTERM_LUA: $lua, WEZTERM_TEST_RESULT: $marker} {
        checked-command wezterm --config-file ($root | path join checks/wezterm-entry.lua) show-keys --lua
    }

    assert equal (open --raw $marker | str trim) passed

    assert ($keys | str contains "{ key = 'h', mods = 'CTRL'")

    assert ($keys | str contains "{ key = 'phys:1', mods = 'SHIFT|CTRL|SUPER'")

    assert ((
        $keys
        | lines
        | where $it =~ '^    \{ key ='
        | length
    ) >= 80)
}
