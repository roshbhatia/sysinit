export def inventory [catalog: path, home: path, extra_roots: list<path>] {
    let declared = open --raw $catalog | from json

    let managed = $declared.roots | each {|root| $home | path join $root}

    let roots = $managed | append $extra_roots | uniq

    mut copies = {}

    mut missing = {}

    for root in $roots {
        let files = glob ($root | path join '*')
        | each {|directory| $directory | path join SKILL.md}
        | where {|file| ($file | path exists) and ($file | path expand --strict | path type) == file}
        | sort

        let names = $files | each {|file| $file | path dirname | path basename}

        for file in $files {
            let name = $file | path dirname | path basename

            let previous = $copies | get --optional $name | default []

            let copy = {
                path: $file
                managed: ($root in $managed)
                sha256: (open --raw $file | hash sha256)
            }

            $copies = $copies | upsert $name ($previous | append $copy)
        }

        if $root in $managed {
            $missing = $missing | insert $root (
                $declared.descriptions
                | columns
                | where {|name| $name not-in $names}
                | sort
            )
        }
    }

    {
        missing: $missing
        copies: $copies
        different_copies: (
            $copies
            | transpose name files
            | where {|entry| ($entry.files.sha256 | uniq | length) > 1}
            | get name
            | sort
        )
    }
}

def main [
    --catalog: path
    --home: path
    --check
    ...roots: path
] {
    let home = $home | default $env.HOME | path expand

    let config = $env.XDG_CONFIG_HOME? | default ($home | path join .config)

    let catalog = $catalog | default ($config | path join sysinit skills.json)

    let result = inventory $catalog $home ($roots | each {|root| $root | path expand})

    $result | to json | print

    if $check and ($result.missing | values | any {|names| ($names | length) > 0}) { exit 1 }
}
