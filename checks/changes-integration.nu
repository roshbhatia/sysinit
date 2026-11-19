use std/assert
use lib/process.nu checked-command

def main [version: string, plugin: path, configuration: path] {
    let reported = checked-command changes --version | lines

    assert equal $reported.0 $version

    assert ($reported | any {|line| $line =~ '^provider/v1 spec [0-9.]+$'})

    $env.HOME = $env.TMPDIR | path join home

    $env.XDG_CACHE_HOME = $env.TMPDIR | path join cache

    $env.XDG_CONFIG_HOME = $env.TMPDIR | path join config

    $env.XDG_DATA_HOME = $env.TMPDIR | path join data

    mkdir $env.HOME $env.XDG_CACHE_HOME $env.XDG_CONFIG_HOME $env.XDG_DATA_HOME repository

    checked-command changes provider validate git-notes | ignore

    cd repository

    checked-command git init --quiet | ignore

    checked-command git config user.name 'Changes integration test' | ignore

    checked-command git config user.email changes@example.invalid | ignore

    checked-command git remote add origin https://example.invalid/changes.git | ignore

    checked-command git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*' | ignore

    checked-command git config remote.origin.push refs/heads/main | ignore

    "package main\n" | save main.go

    checked-command git add main.go | ignore

    checked-command git commit --quiet -m baseline | ignore

    "package main\nfunc main() {}\n" | save --force main.go

    checked-command git add main.go | ignore

    checked-command git commit --quiet -m fixture | ignore

    let fetch = checked-command git config --get-all remote.origin.fetch

    let push = checked-command git config --get-all remote.origin.push

    checked-command changes note add --commit HEAD --provider git-notes --file main.go --line 2 --origin user --author sysinit-test --message 'Keep this entry point explicit' | ignore

    assert (
        checked-command git notes --ref=refs/notes/changes show HEAD
        | str contains 'Keep this entry point explicit'
    )

    assert equal (checked-command git config --get-all remote.origin.fetch) $fetch

    assert equal (checked-command git config --get-all remote.origin.push) $push

    "package main\nfunc main() {\n}\n" | save --force main.go

    let workspace = checked-command changes workspace --refresh --no-symbols --quiet | from json

    assert equal $workspace.version changes.workspace/v1

    assert equal $workspace.repository.root $env.PWD

    assert equal $workspace.freshness.state fresh

    assert ($workspace.files | any {|file| $file.path == main.go})

    assert ($workspace.notes? == null or ($workspace.notes | describe) =~ '^list|^table')

    assert (($workspace.history | describe) =~ '^list|^table')

    assert equal ($workspace.rendered | describe) string

    assert equal (checked-command git config --get-all remote.origin.fetch) $fetch

    assert equal (checked-command git config --get-all remote.origin.push) $push

    cd ..

    let site = $env.TMPDIR | path join nvim-site

    mkdir ($site | path join pack/hm/start)

    ^ln -s $plugin ($site | path join pack/hm/start/changes.nvim)

    checked-command nvim --headless --clean -u NONE --cmd $'set packpath^=($site)' --cmd 'set noloadplugins' -c $'luafile ($configuration)' -c 'lua assert(vim.fn.exists(":ChangesNote") == 2); assert(vim.fn.exists(":ChangesWorkspace") == 2); assert(vim.fn.exists(":ChangesWorkspaceDecorate") == 2)' -c 'lua assert(type(require("changes.notes").setup) == "function"); local workspace = require("changes.workspace"); assert(type(workspace.setup) == "function"); assert(type(workspace.read) == "function"); assert(type(workspace.open) == "function"); assert(type(workspace.decorate) == "function")' -c 'qa!' | ignore
}
