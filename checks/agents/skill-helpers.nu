use std/assert

def main [helper: path] {
    let root = mktemp -d | path expand --strict

    try {
        let catalog = $root | path join catalog.json

        {
            roots: [managed absent]
            descriptions: {example: test, missing: test}
        } | to json | save $catalog

        for fixture in [
            {root: managed, body: canonical}
            {root: other, body: different}
        ] {
            let directory = $root | path join $fixture.root example

            mkdir $directory

            $fixture.body | save ($directory | path join SKILL.md)
        }

        let shell = $nu.current-exe

        let other = $root | path join other

        let result = ^$shell --no-config-file $helper --catalog $catalog --home $root $other $other | from json

        assert equal ($result.missing | get ($root | path join managed)) [missing]

        assert equal ($result.missing | get ($root | path join absent)) [example missing]

        assert equal $result.different_copies [example]

        assert equal $result.copies.example.managed [true false]

        assert equal ($result.copies.example.sha256 | first) ('canonical' | hash sha256)

        let failed = ^$shell --no-config-file $helper --catalog $catalog --home $root --check | complete

        assert equal $failed.exit_code 1

        let directory = $root | path join published

        mkdir $directory

        '' | save ($directory | path join SKILL.md)

        ^ln -s $directory ($root | path join managed missing)

        {
            roots: [managed]
            descriptions: {example: test, missing: test}
        } | to json | save --force $catalog

        let passed = ^$shell --no-config-file $helper --catalog $catalog --home $root --check | complete

        assert equal $passed.exit_code 0 $passed.stderr
    } catch {|failure|
        rm -rf $root

        error make $failure
    }

    rm -rf $root

    print 'skill inventory checks passed'
}
