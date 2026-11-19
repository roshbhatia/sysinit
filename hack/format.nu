def --wrapped main [...arguments: string] {
    let root = (^git rev-parse --show-toplevel | str trim)

    cd $root

    if $arguments.0? != '--check' {
        exec treefmt --config-file ($root | path join treefmt.toml) ...$arguments
    }

    let temporary = (^mktemp -d | str trim)

    let result = try {
        let files = (
            ^git ls-files -z
            | split row (char nul)
            | where {|file| ($file | is-not-empty) and ($file | path type) == file}
        )

        $files | str join (char nul) | ^tar -c --null -T - | ^tar -x -C $temporary

        ^treefmt --config-file ($temporary | path join treefmt.toml) --tree-root $temporary --working-dir $temporary --walk filesystem --ci ...($arguments | skip 1) | complete
    } catch {|failure|
        rm --recursive $temporary

        error make $failure
    }

    rm --recursive $temporary

    print --no-newline $result.stdout

    print --stderr --no-newline $result.stderr

    exit $result.exit_code
}
