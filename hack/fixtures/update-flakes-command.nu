def --wrapped main [...arguments: string] {
    if ($env.UPDATE_FIXTURE_FAIL? | default '') == $env.UPDATE_FIXTURE_COMMAND { exit 7 }
    (
        (
            {
                command: $env.UPDATE_FIXTURE_COMMAND
                arguments: $arguments
                cwd: $env.PWD
            }
            | to json --raw
        ) + "\n"
    ) | save --append $env.UPDATE_FIXTURE_LOG
    if $env.UPDATE_FIXTURE_COMMAND == nix {
        if $arguments != [flake update] { error make {msg: 'unexpected Nix operation'} }
        return
    }
    let endpoint = $arguments.1
    let value = if ($endpoint | str ends-with '/releases?per_page=100') {
        if $env.UPDATE_FIXTURE_MODE == releases {
            [
                {tag_name: v3.0.0-rc1, draft: false, prerelease: true}
                {tag_name: v1.5.0, draft: false, prerelease: false}
                {tag_name: v2.0.0, draft: false, prerelease: false}
            ]
        } else { [] }
    } else if ($endpoint | str ends-with '/tags?per_page=100') {
        [
            {name: v1.9.0}
            {name: v3.0.0-rc1}
            {name: v2.1.0}
        ]
    } else if ($endpoint | str ends-with '/commits/main') {
        {
            sha: ('b' | fill --width 40 --character b)
        }
    } else {
        {default_branch: main}
    }
    $value | to json | print
}
