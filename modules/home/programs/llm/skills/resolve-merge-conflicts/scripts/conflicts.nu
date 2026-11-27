def --wrapped git-output [...args: string] {
    let result = ^git ...$args | complete

    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim)
        }
    }

    $result.stdout
}

def preview [stages: list<record>] {
    let sides = $stages | where stage in [2 3]

    if ($sides | length) != 2 or ($sides | any {|side| $side.mode !~ '^100'}) { return null }

    let diff = (git-output
        diff
        --no-color
        --no-ext-diff
        --no-textconv
        --unified=3
        $sides.0.object
        $sides.1.object
    )

    let lines = $diff | lines

    {
        lines: ($lines | take 100)
        truncated: (($lines | length) > 100)
    }
}

def main [--file: string] {
    cd (git-output rev-parse --show-toplevel | str replace --regex '\n$' '')

    let entries = git-output ls-files --unmerged -z
    | split row (char nul)
    | where {|entry| $entry != ''}
    | parse --regex '(?s)^(?<mode>\d+) (?<object>[0-9a-f]+) (?<stage>[123])\t(?<path>.*)$'
    | update stage {|entry| $entry.stage | into int}

    let conflicts = $entries | group-by path | transpose path entries | each {|entry|
        {path: $entry.path, stages: ($entry.entries | reject path)}
    } | sort-by path

    if $file == null { return ($conflicts | to json --raw) }

    let conflict = $conflicts | where path == $file | get -o 0

    if $conflict == null { error make {msg: $"No unmerged index entry for ($file)."} }

    $conflict | insert preview (preview $conflict.stages) | to json --raw
}
