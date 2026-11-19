def github [endpoint: string] {
    let result = ^gh api $endpoint | complete

    if $result.exit_code != 0 { error make {msg: $result.stderr} }

    $result.stdout | from json
}

def latest-tag [current: string, tags: list<string>] {
    $tags | prepend $current | enumerate | each {|entry|
        let version = $entry.item | str replace --regex '^v' '' | split row '.' | each { into int }
        {tag: $entry.item, major: $version.0, minor: $version.1, patch: $version.2, order: (0 - $entry.index)}
    } | sort-by major minor patch order | last | get tag
}

def main [--root: path] {
    let root = $root | default ($env.FILE_PWD | path dirname) | path expand --strict

    let tracked = ^git -C $root ls-files -- flake.nix '*/flake.nix' | complete

    if $tracked.exit_code != 0 { error make {msg: $tracked.stderr} }

    let paths = $tracked.stdout | lines | each {|path| {path: $path, depth: ($path | split row '/' | length)}} | sort-by depth path

    mut cache = {}

    for relative in $paths.path {
        let path = $root | path join $relative

        mut text = open --raw $path

        let references = $text | parse --regex 'github:(?P<owner>[^/"?]+)/(?P<repository>[^/"?]+)/(?P<reference>[^"?]+)(?P<query>\?[^"\s]*)?'

        for reference in $references {
            let pinned = $reference.reference

            let kind = if $pinned =~ '^[0-9a-f]{40}$' { 'sha' } else if $pinned =~ '^v?\d+\.\d+\.\d+$' { 'tag' } else { continue }

            let repository = $'($reference.owner)/($reference.repository)'

            let key = $'($repository):($kind)'

            if $key not-in $cache {
                let replacement = if $kind == sha {
                    let branch = if $repository == NixOS/nixpkgs {
                        'nixpkgs-unstable'
                    } else {
                        github $'repos/($repository)' | get default_branch
                    }

                    github $'repos/($repository)/commits/($branch)' | get sha
                } else {
                    let releases = github $'repos/($repository)/releases?per_page=100'

                    mut tags = $releases | where {|release| not $release.draft and not $release.prerelease} | get tag_name | where {|tag| $tag =~ '^v?\d+\.\d+\.\d+$'}

                    if ($tags | is-empty) {
                        $tags = github $'repos/($repository)/tags?per_page=100' | get name | where {|tag| $tag =~ '^v?\d+\.\d+\.\d+$'}
                    }

                    latest-tag $pinned $tags
                }

                $cache = $cache | upsert $key $replacement
            }

            let query = $reference.query? | default ''

            $text = $text | str replace --all $'github:($repository)/($pinned)($query)"' $'github:($repository)/($cache | get $key)($query)"'
        }

        $text | save --force $path

        cd ($path | path dirname)

        let updated = ^nix flake update | complete

        print --no-newline $updated.stdout

        print --stderr --no-newline $updated.stderr

        if $updated.exit_code != 0 { exit $updated.exit_code }
    }
}
