# Show filesystem capacity; APFS volumes can share the same free space.
export def "storage free" [] {
    sys disks | select device mount total free | sort-by free
}

# Rank allocated directory sizes without following symlinks.
export def "storage usage" [directory: path = ~, --depth: int = 1, --top: int = 20] {
    if $depth < 0 or $top < 1 { error make {msg: "depth must be nonnegative and top must be positive"} }
    let result = (^du -x -k -d $depth -- ($directory | path expand) | complete)
    if $result.exit_code != 0 { error make {msg: $"du could not complete: ($result.stderr | str trim)"} }
    $result.stdout
    | lines
    | parse --regex '^(?<kib>\d+)\t(?<path>.*)$'
    | each {|row| {path: $row.path, allocated: (($row.kib | into int) * 1024 | into filesize)} }
    | sort-by allocated --reverse
    | first $top
}

# List roots retaining Nix paths; deleting a result link changes retention.
export def "storage nix-roots" [] {
    let result = (^nix-store --gc --print-roots | complete)
    if $result.exit_code != 0 {
        error make {
            msg: ($result.stderr | str trim)
        }
    }
    $result.stdout
    | lines
    | parse --regex '^(?<root>.+) -> (?<target>/nix/store/.*)$'
    | update root { str trim --char '"' }
}

# Inspect managed cache thresholds; cleanup requires an explicit --apply.
export def "storage caches" [--apply] {
    let arguments = if $apply { [--apply] } else { [] }
    let result = (^cache-maintain ...$arguments | complete)
    if $result.exit_code != 0 { error make {msg: $"cache-maintain failed: ($result.stderr | str trim)"} }
    $result.stdout
    | from json
    | get results
    | update before_bytes { into filesize }
    | update after_bytes { into filesize }
    | update max_bytes { into filesize }
}
