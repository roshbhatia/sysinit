use std/assert

def frontmatter [text: string] {
    let lines = $text | lines

    assert equal ($lines | first) '---'

    $lines | skip 1 | take while {|line| $line != '---'} | str join "\n" | from yaml
}

def main [path: path] {
    let manifest = open --raw $path | from json

    for file in $manifest.fixtureFiles {
        assert equal ($file | path expand --strict | path type) file $file
    }

    let standard = [
        name
        description
        license
        compatibility
        metadata
        allowed-tools
    ]

    for entry in $manifest.frontmatterFiles {
        let header = frontmatter (open --raw $entry.path)

        let allowed = if $entry.claude {
            $standard ++ [model effort disable-model-invocation]
        } else {
            $standard
        }

        assert equal $header.name $entry.name $entry.path

        assert ($header.name =~ '^[a-z0-9]+(-[a-z0-9]+)*$' and ($header.name | str length) <= 64) $entry.path

        assert (
            ($header.description | describe) == string and ($header.description | str trim | str length) in 1..1024
        ) $entry.path

        assert (($header | columns | where {|field| $field not-in $allowed}) | is-empty) $entry.path

        for field in [license compatibility allowed-tools] {
            if $field in ($header | columns) {
                assert equal ($header | get $field | describe) string $entry.path
            }
        }

        if 'compatibility' in ($header | columns) {
            assert (($header.compatibility | str trim | str length) in 1..500) $entry.path
        }

        if 'metadata' in ($header | columns) {
            assert (($header.metadata | describe) | str starts-with record) $entry.path

            assert ($header.metadata | values | all {|value| ($value | describe) == string}) $entry.path
        }
    }

    let claude = frontmatter $manifest.rendered

    let portable = frontmatter $manifest.amp

    assert equal $claude.disable-model-invocation false

    assert equal $claude.model haiku

    assert ('model' not-in ($portable | columns))

    assert ('disable-model-invocation' not-in ($portable | columns))

    assert equal $portable.description "It's a fixture"

    assert equal $portable.license MIT

    assert equal $portable.compatibility 'Requires Git'

    assert equal $portable.metadata.author sysinit

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
