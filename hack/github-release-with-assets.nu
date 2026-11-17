#!/usr/bin/env nu

export def select-release [releases: list<record>, assets: list<string>] {
    for release in (
        $releases
        | where {|release| not $release.draft and not $release.prerelease }
    ) {
        let available = $release.assets | get name
        if ($assets | all {|asset| $asset in $available }) {
            return $release.tag_name
        }
    }
    error make {
        msg: $"No stable release contains all required assets: ($assets | sort | to json --raw)"
    }
}

def main [repository: string, ...assets: string] {
    if ($assets | is-empty) { error make {msg: "At least one release asset is required"} }
    let response = ^gh api $"repos/($repository)/releases?per_page=100" | complete
    if $response.exit_code != 0 { error make {msg: $response.stderr} }
    select-release ($response.stdout | from json) $assets
}
