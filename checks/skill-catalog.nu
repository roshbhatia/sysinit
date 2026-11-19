use std/assert

def main [path: path] {
    let manifest = open --raw $path | from json

    for file in ($manifest.paths | append $manifest.fixtureFiles) {
        assert equal ($file | path expand --strict | path type) file $file
    }

    assert ($manifest.rendered | str contains 'disable-model-invocation: false')

    assert ($manifest.rendered | str contains 'model: "haiku"')

    assert not ($manifest.amp | str contains 'model:')

    let description = $manifest.rendered | lines | where {|line| $line | str starts-with 'description:'} | first | str replace 'description: ' '' | from json

    assert equal $description "It's a fixture"

    assert (($manifest.guidance | lines | length) <= 100)

    for case in $manifest.cases {
        assert not ($case.prompt | str trim | is-empty)

        for name in ($case.expected | append $case.avoid) {
            assert ($name in $manifest.names)
        }
    }

    for package in $manifest.packages {
        let links = $package.content | parse --regex '\]\((?<relative>(?:references|scripts|assets)/[^)#]+)(?:#[^)]*)?\)'

        for link in $links {
            assert ($link.relative in $package.files) $'($package.name): ($link.relative)'
        }
    }

    print 'Skill metadata, root/nested resources, and all managed roots passed'
}
