use std/assert
use ./process.nu checked-command

export def install [root: path, bridge: path, specifications: record] {
    let bridge_directory = $root | path join carapace bridge zsh

    let specification_directory = $root | path join carapace specs

    mkdir $bridge_directory $specification_directory

    cp $bridge ($bridge_directory | path join .zshrc)

    for specification in ($specifications | transpose name source) {
        cp $specification.source ($specification_directory | path join $specification.name)
    }
}

export def check-completion [command: string, arguments: list<string>, expected: string] {
    let values = checked-command carapace $command nushell $command ...$arguments
    | from json
    | get value
    | str trim

    assert ($expected in $values) $'Missing completion ($expected) for ($command)'
}
