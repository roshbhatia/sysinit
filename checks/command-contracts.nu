use std/assert
use lib/process.nu checked-command

def 'main contains' [file: path, text: string] {
    assert (open --raw $file | str contains $text)
}

def 'main help' [command: path, text: string] {
    assert (checked-command $command --help | str contains $text)
}

def 'main gh-dash' [] {
    $env.HOME = $env.TMPDIR | path join home

    mkdir $env.HOME

    let result = ^gh-dash https://github.com/owner/repo/issues/1 | complete

    assert ($result.exit_code != 0) 'gh-dash accepted an issue URL as a PR'

    assert ($result.stderr | str contains 'points to an issue, only pull requests are supported')
}

def 'main command-surface' [functions: path] {
    $env.HOME = $env.TMPDIR

    let columns = checked-command $nu.current-exe --no-config-file -c $'use ($functions) *; ls | columns | to json -r' | from json

    assert ('icon' in $columns)
}

def 'main plugins' [plugin: path] {
    $env.HOME = $env.TMPDIR | path join home

    $env.XDG_CONFIG_HOME = $env.HOME | path join .config

    $env.XDG_DATA_HOME = $env.HOME | path join .local/share

    $env.XDG_RUNTIME_DIR = $env.TMPDIR | path join runtime

    mkdir $env.HOME $env.XDG_RUNTIME_DIR

    let configuration = $env.TMPDIR | path join plugin.msgpackz

    touch $configuration

    checked-command $nu.current-exe --no-config-file --plugin-config $configuration --commands $'plugin add ($plugin)' | ignore

    checked-command $nu.current-exe --no-config-file --plugin-config $configuration --commands 'plugin use nuvim; nuvim servers | ignore' | ignore
}
