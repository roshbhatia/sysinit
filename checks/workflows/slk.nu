use std/assert
use ../lib/process.nu [checked-command with-fixture]

def main [configure: path] {
    with-fixture {|root|
        let path = $root | path join config.toml
        let settings = $root | path join settings.toml

        '[appearance]
image_protocol = "auto"
[sidebar]
width = 26
' | save $settings

        '# preserved comment
[appearance]
image_protocol = "kitty"
theme = "custom"
[workspaces."work.team"]
team_id = "T123"
[notifications]
on_keyword = ["important"]
' | save $path

        checked-command python3 $configure $path $settings | ignore

        let contents = open --raw $path
        let result = $contents | from toml

        assert equal $result.appearance {image_protocol: auto, theme: custom}
        assert equal $result.workspaces.'work.team'.team_id T123
        assert equal $result.notifications.on_keyword [important]
        assert equal $result.sidebar.width 26
        assert ($contents | str contains '# preserved comment')
        assert equal (ls -l $path | first | get mode) 'rw-------'

        let inode = checked-command stat --format=%i $path

        checked-command python3 $configure $path $settings | ignore
        assert equal (open --raw $path) $contents
        assert equal (checked-command stat --format=%i $path) $inode

        '[broken' | save --force $path

        let invalid = ^python3 $configure $path $settings | complete

        assert ($invalid.exit_code != 0) 'Malformed config was accepted'
        assert equal (open --raw $path) '[broken'

        let fresh = $root | path join fresh config.toml

        checked-command python3 $configure $fresh $settings | ignore
        assert equal (open $fresh | get sidebar.width) 26
        assert (glob ($root | path join '.config.*') | is-empty)
    }

    print 'slk configuration preservation, idempotence, permissions, and invalid input passed'
}
