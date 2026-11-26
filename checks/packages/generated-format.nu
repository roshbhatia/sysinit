use std/assert
use ../lib/process.nu checked-command

def main [script: path, json: path] {
    checked-command shfmt -ln bash -i 2 -ci -sr -s -d $script | ignore

    assert equal (checked-command $script | str trim) 'argument with spaces'

    assert equal (open --raw $json) (checked-command jq --indent 2 . $json)
}
