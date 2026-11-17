const resolution = {do: 'sunshine-res set', undo: 'sunshine-res restore'}
const stop_steam = {do: '', undo: 'pkill -f gamescope; pkill -f steam; true'}
const stop_heroic = {do: '', undo: 'pkill -f gamescope; pkill -f heroic; true'}
const stop_wine = {do: '', undo: 'pkill -f gamescope; pkill -f umu; true'}

def convert-cover [source: path, target: path] {
    let result = ^magick $source $target | complete
    if $result.exit_code != 0 { error make {msg: $result.stderr} }
    $target
}

def cover-from-url [url, key: string, covers: path] {
    if $url == null or $url == '' { return null }
    mkdir $covers
    let target = $covers | path join ($key + '.png')
    if ($target | path exists) { return $target }
    try {
        let download = $covers | path join ($key + '.download')
        let downloaded = ^curl --fail --location --silent --show-error --output $download $url | complete
        if $downloaded.exit_code != 0 { return null }
        convert-cover $download $target | ignore
        rm --force $download
        $target
    } catch { null }
}

def steam-games [home: path, covers: path] {
    let steam = $home | path join .local share Steam
    glob ($steam | path join steamapps 'appmanifest_*.acf') | sort | each {|manifest|
        let text = open --raw $manifest | into binary | decode utf-8
        let identifiers = $text | parse --regex '"appid"\s+"(?P<value>\d+)"'
        let names = $text | parse --regex '"name"\s+"(?P<value>[^"]+)"'
        if ($identifiers | is-empty) or ($names | is-empty) { return null }
        let identifier = $identifiers.0.value
        let name = $names.0.value
        if $name =~ 'Proton|Steam Linux Runtime|Steamworks|EasyAntiCheat' { return null }
        mut entry = {name: $name, cmd: $'steam-run-game ($identifier)', prep-cmd: [$resolution $stop_steam]}
        let art = $steam | path join appcache librarycache $identifier library_600x900.jpg
        if ($art | path exists) {
            mkdir $covers
            let target = $covers | path join ($identifier + '.png')
            if not ($target | path exists) or (ls $target | first | get modified) < (ls $art | first | get modified) {
                convert-cover $art $target | ignore
            }
            $entry = $entry | upsert image-path $target
        }
        $entry
    } | where {|entry| $entry != null}
}

def heroic-games [home: path, covers: path] {
    let heroic = $home | path join .config heroic
    let epic_library = $heroic | path join store_cache legendary_library.json
    let epic_games = if ($epic_library | path exists) {
        open $epic_library | get --optional library | default []
    } else {
        []
    }
    let installed = $heroic | path join legendaryConfig legendary installed.json
    mut entries = []
    if ($installed | path exists) {
        for game in (open $installed | transpose app_name metadata) {
            if ($game.metadata.is_dlc? | default false) { continue }
            let title = $game.metadata.title? | default --empty $game.app_name
            mut entry = {
                name: $title
                cmd: $'heroic-run-game legendary ($game.app_name)'
                prep-cmd: [$resolution $stop_heroic]
            }
            let metadata = $epic_games | where {|row| $row.app_name? == $game.app_name} | last 1 | get --optional 0 | default {}
            let url = $metadata.art_cover? | default --empty $metadata.art_square?
            let art = cover-from-url $url $'epic-($game.app_name)' $covers
            if $art != null { $entry = $entry | upsert image-path $art }
            $entries = $entries | append $entry
        }
    }
    let gog_library = $heroic | path join store_cache gog_library.json
    let gog_games = if ($gog_library | path exists) {
        open $gog_library | get --optional games | default []
    } else {
        []
    }
    let gog_installed = $heroic | path join gog_store installed.json
    if ($gog_installed | path exists) {
        for game in (open $gog_installed | get --optional installed | default []) {
            let metadata = $gog_games | where {|row| $row.app_name? == $game.appName} | last 1 | get --optional 0 | default {}
            let title = $metadata.title? | default --empty $game.appName
            mut entry = {
                name: $title
                cmd: $'heroic-run-game gog ($game.appName)'
                prep-cmd: [$resolution $stop_heroic]
            }
            let url = $metadata.art_cover? | default --empty $metadata.art_square?
            let art = cover-from-url $url $'gog-($game.appName)' $covers
            if $art != null { $entry = $entry | upsert image-path $art }
            $entries = $entries | append $entry
        }
    }
    $entries
}

def main [] {
    let directory = $env.HOME | path join .config sunshine
    let covers = $directory | path join covers
    let extra = $directory | path join extra-apps.json
    let additions = if ($extra | path exists) {
        open $extra | get --optional apps | default [] | each {|entry|
            if 'prep-cmd' in $entry { $entry } else { $entry | upsert prep-cmd [$resolution $stop_wine] }
        }
    } else { [] }
    let games = steam-games $env.HOME $covers | append (heroic-games $env.HOME $covers) | append $additions | sort-by --ignore-case name
    let users = [$env.LOGNAME? $env.USER? $env.LNAME? $env.USERNAME?] | where {|value| $value != null and $value != ''}
    let user = if ($users | is-empty) {
        ^id -un | str trim
    } else {
        $users | first
    }
    let catalog = {
        env: {
            PATH: $'/etc/profiles/per-user/($user)/bin:/run/current-system/sw/bin'
            WAYLAND_DISPLAY: wayland-1
            XDG_RUNTIME_DIR: /run/user/1000
            DISPLAY: ':0'
        }
        apps: ([
            {name: Desktop, prep-cmd: [$resolution], image-path: desktop.png}
            {name: 'Steam Big Picture', cmd: steam-bigpicture, prep-cmd: [$resolution $stop_steam], image-path: steam.png}
        ] | append $games)
    }
    let target = $directory | path join apps.json
    (($catalog | to json --indent 2) + "\n") | save --force $target
    print $'wrote ($target) with ($games | length) entries:'
    for game in $games { print $'  ($game.name)' }
}
