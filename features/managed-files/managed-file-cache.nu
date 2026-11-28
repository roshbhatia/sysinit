#!/usr/bin/env nu

def fingerprint [paths: list<string>, policy: list<string>] {
    let hashes = $paths | each {|file|
        if ($file | path type) != file {
            error make {msg: "managed file is missing or is a symlink"}
        }
        open --raw $file | hash sha256
    }

    {
        files: $hashes
        inputs: ($paths | skip 2)
        policy: $policy
    }
}

def cache-operation [
    operation: string
    cache: path
    target: string
    base: string
    declared: string
    schema: string
    ...policy: string
] {
    let paths = [$target $base $declared] | append (if $schema == '-' { [] } else { [$schema] })

    try {
        let current = fingerprint $paths $policy

        match $operation {
            check => { (open --raw $cache | from json) == $current }
            record => {
                let directory = $cache | path dirname

                mkdir $directory

                let temporary = mktemp --tmpdir-path $directory .managed-cache-XXXXXX

                try {
                    $current | to json --raw | save --force $temporary

                    mv --force $temporary $cache
                } catch {|error|
                    rm --force $temporary

                    error make {msg: $error.msg}
                }

                true
            }
            _ => { false }
        }
    } catch {
        false
    }
}

def main [operation: string, ...arguments: string] {
    if $operation != batch {
        if ($arguments | length) < 5 { exit 1 }

        if not ((cache-operation
            $operation
            $arguments.0
            $arguments.1
            $arguments.2
            $arguments.3
            $arguments.4
            ...($arguments | skip 5)
        )) { exit 1 }

        return
    }

    if ($arguments | length) != 2 { exit 1 }

    let entries = open --raw $arguments.0 | from json

    for entry in $entries {
        let target = $env.HOME | path join $entry.1

        let name = $target | path basename

        let prefix = if ($name | str starts-with '.') { '' } else { '.' }

        let base = $target | path dirname | path join $"($prefix)($name).nix-base"

        if not ((cache-operation
            check
            $"($base).cache"
            $target
            $base
            $entry.3
            $entry.5
            $entry.2
            $entry.4
            $entry.6
            $entry.7
            $entry.8
            $arguments.1
        )) {
            print --no-newline --raw $"($entry.0)(char --integer 0)"
        }
    }
}
