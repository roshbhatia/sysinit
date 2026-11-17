use std/assert

def generate [script: path] {
    let result = ^$nu.current-exe --no-config-file $script | complete
    assert equal $result.exit_code 0 $result.stderr
    open ($env.HOME | path join .config sunshine apps.json)
}

def main [script: path] {
    let root = mktemp --directory | path expand --strict
    try {
        let home = $root | path join home
        let sunshine = $home | path join .config sunshine
        mkdir $sunshine
        with-env {HOME: $home} {
            let empty = generate $script
            assert equal $empty.apps.name [Desktop 'Steam Big Picture']
            let steam = $home | path join .local share Steam
            let manifests = $steam | path join steamapps
            let heroic = $home | path join .config heroic
            mkdir $manifests ($steam | path join appcache librarycache '1') ($heroic | path join store_cache) ($heroic | path join legendaryConfig legendary) ($heroic | path join gog_store)
            '"appid" "1" "name" "Zebra"' | save ($manifests | path join appmanifest_1.acf)
            '"appid" "2" "name" "Proton runtime"' | save ($manifests | path join appmanifest_2.acf)
            '"name" "Missing identifier"' | save ($manifests | path join appmanifest_bad.acf)
            let art = $steam | path join appcache librarycache '1' library_600x900.jpg
            let converted = ^magick -size 2x2 xc:red $art | complete
            assert equal $converted.exit_code 0 $converted.stderr
            let url = $'file://($art)'
            {'epic-game': {title: Alpha}, dlc: {title: 'Skipped DLC', is_dlc: true}, missing: {title: 'No artwork'}}
                | to json | save ($heroic | path join legendaryConfig legendary installed.json)
            {library: [{app_name: epic-game, art_cover: $url} {app_name: missing, art_cover: $'file://($root)/absent.jpg'}]}
                | to json | save ($heroic | path join store_cache legendary_library.json)
            {games: [{app_name: gog-game, title: beta, art_square: $url}]}
                | to json | save ($heroic | path join store_cache gog_library.json)
            {installed: [{appName: gog-game}]}
                | to json | save ($heroic | path join gog_store installed.json)
            {apps: [{name: Manual, cmd: 'umu game'} {name: Custom, cmd: 'custom game', prep-cmd: []}]}
                | to json | save ($sunshine | path join extra-apps.json)
            let catalog = generate $script
            assert equal $catalog.apps.name [Desktop 'Steam Big Picture' Alpha beta Custom Manual 'No artwork' Zebra]
            let games = $catalog.apps | skip 2
            assert equal ($games | where name == Alpha | first | get cmd) 'heroic-run-game legendary epic-game'
            assert equal ($games | where name == beta | first | get cmd) 'heroic-run-game gog gog-game'
            assert equal ($games | where name == Zebra | first | get cmd) 'steam-run-game 1'
            assert equal ($games | where name == Custom | first | get prep-cmd) []
            assert equal ($games | where name == Manual | first | get prep-cmd | last | get undo) 'pkill -f gamescope; pkill -f umu; true'
            assert ('image-path' not-in ($games | where name == 'No artwork' | first))
            for name in [Alpha beta Zebra] {
                let path = $games | where name == $name | first | get image-path
                assert equal (open --raw $path | into binary | bytes at 0..7) 0x[89504E470D0A1A0A]
            }
            let cover = $sunshine | path join covers '1.png'
            let modified = ls $cover | first | get modified
            generate $script | ignore
            assert equal (ls $cover | first | get modified) $modified
        }
    } catch {|failure|
        rm --recursive --force $root
        error make $failure
    }
    rm --recursive --force $root
    print 'Sunshine Steam, Epic, GOG, extra applications, artwork, and cache checks passed'
}
