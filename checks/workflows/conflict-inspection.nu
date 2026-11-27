use std/assert

def --wrapped git [...args: string] {
    ^git ...$args
}

def main [helper: path] {
    let root = mktemp --directory

    cd $root

    git init --quiet --template= --initial-branch=main

    git config user.name Fixture

    git config user.email fixture@example.invalid

    'base' | save 'file with spaces.txt'

    git add -- .

    git commit --quiet -m base

    git switch --quiet -c incoming

    'incoming' | save --force 'file with spaces.txt'

    'incoming addition' | save added.txt

    git add -- .

    git commit --quiet -m incoming

    git switch --quiet main

    'current' | save --force 'file with spaces.txt'

    'current addition' | save added.txt

    git add -- .

    git commit --quiet -m current

    let merge = git merge --no-edit incoming | complete

    assert equal $merge.exit_code 1

    let index = git ls-files --unmerged -z

    let summary = ^$nu.current-exe --no-config-file $helper | from json

    assert equal $summary.path [added.txt 'file with spaces.txt']

    assert equal $summary.0.stages.stage [2 3]

    assert equal $summary.1.stages.stage [1 2 3]

    let details = ^$nu.current-exe --no-config-file $helper --file 'file with spaces.txt' | from json

    assert ('-current' in $details.preview.lines)

    assert ('+incoming' in $details.preview.lines)

    assert equal $details.preview.truncated false

    assert equal (git ls-files --unmerged -z) $index

    let oid = $summary.1.stages.0.object

    $"120000 ($oid) 2\tlink\n120000 ($oid) 3\tlink\n" | git update-index --index-info

    let index_with_link = git ls-files --unmerged -z

    let link = ^$nu.current-exe --no-config-file $helper --file link | from json

    assert equal $link.stages.mode ['120000' '120000']

    assert equal $link.preview null

    let missing = ^$nu.current-exe --no-config-file $helper --file missing | complete

    assert ($missing.exit_code != 0)

    assert equal (git ls-files --unmerged -z) $index_with_link
}
