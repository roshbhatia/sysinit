def app-snapshot [origin: path, app: path, codesign: string] {
    if not (($app | path basename) | str ends-with '.app') or ($app | path type) != dir {
        error make {msg: 'application is not a copied bundle'}
    }

    let verified = (^$codesign --verify --deep --strict $app | complete)

    if $verified.exit_code != 0 { error make {msg: $verified.stderr} }

    let requirement = (^$codesign -d -r- $app | complete)

    if $requirement.exit_code != 0 { error make {msg: $requirement.stderr} }

    {
        source: ($origin | path expand --strict)
        requirement: ($requirement.stdout + $requirement.stderr)
    }
}

def app-names [directory: path] {
    ls --all $directory | each {|entry| $entry.name | path basename } | sort
}

def snapshot [source: path, target: path, codesign: string] {
    if (($source | path expand --strict | path type) != dir) or ($target | path type) != dir {
        error make {msg: 'application directory is missing or is a symlink'}
    }

    let names = app-names $source

    if $names != (app-names $target) { error make {msg: 'application lists differ'} }

    $names | reduce --fold {} {|name, current|
    $current | upsert $name (app-snapshot ($source | path join $name) ($target | path join $name) $codesign)
  }
}

def unchanged-apps [
    source: path
    target: path
    state: path
    codesign: string
] {
    let loaded = try {
        open --raw $state | from json
    } catch {
        {}
    }

    let previous = if ($loaded | describe | str starts-with record) { $loaded } else { {} }

    app-names $source | where {|name|
    let current = try { app-snapshot ($source | path join $name) ($target | path join $name) $codesign } catch { null }
    $current != null and $current == ($previous | get -o $name)
  }
}

def guard-running [protected: list<string>, unchanged: list<string>, pgrep: string] {
    for name in $protected {
        if ($name + '.app') in $unchanged { continue }

        let result = (^$pgrep -x $name | complete)

        if $result.exit_code == 0 {
            error make {msg: $"Quit ($name) before switching: its app bundle would be replaced or removed"}
        }

        if $result.exit_code != 1 {
            error make {msg: $"Cannot check whether ($name) is running: pgrep exited ($result.exit_code)"}
        }
    }
}

def sync-apps [
    source: path
    target: path
    unchanged: list<string>
    rsync: string
] {
    let excludes = ($unchanged | sort | each {|name|
    let literal = $name | str replace --all --regex '([\\*?\[])' '\$1'
    '--exclude=/' + $literal
  })

    mkdir $target

    let result = (
        ^$rsync --recursive --checksum --perms --links --copy-unsafe-links --specials --delete --chmod=+w ...$excludes ($source + '/') $target
        | complete
    )

    if $result.exit_code != 0 { error make {msg: $result.stderr} }
}

def record-state [state: path, current: record] {
    let directory = $state | path dirname

    mkdir $directory

    let temporary = mktemp --tmpdir-path $directory .app-copy-XXXXXX

    try {
        $current | to json --raw | save --force $temporary

        mv --force $temporary $state
    } catch {|error|
        rm --force $temporary

        error make {msg: $error.msg}
    }
}

def main [
    operation: string
    source: path
    target: path
    state: path
    --codesign: string = '/usr/bin/codesign'
    --rsync: string = 'rsync'
    --protect-running: string = '[]'
    --pgrep: string = '/usr/bin/pgrep'
    --touch: string = '/usr/bin/touch'
] {
    try {
        match $operation {
            check-permission => {
                if ($target | path type) != dir { return }

                let installed = app-names $target | where {|name| $name | str ends-with '.app' }

                if ($installed | is-empty) { return }

                let unchanged = if ($source | path exists) {
                    unchanged-apps $source $target $state $codesign
                } else {
                    []
                }

                for name in $installed {
                    if $name in $unchanged { continue }

                    let app = $target | path join $name

                    if ($app | path type) != dir { continue }

                    let result = (^$touch ($app | path join .DS_Store) | complete)

                    if $result.exit_code != 0 {
                        error make {
                            msg: $"Cannot update ($app). Run activation from a terminal with App Management permission.\n($result.stderr | str trim)"
                        }
                    }
                }
            }
            preflight | sync => {
                let unchanged = unchanged-apps $source $target $state $codesign

                (guard-running
                    ($protect_running | from json)
                    $unchanged
                    $pgrep
                )

                if $operation == sync { sync-apps $source $target $unchanged $rsync }
            }
            check => {
                let previous = open --raw $state | from json

                if (snapshot $source $target $codesign) != $previous { exit 1 }
            }
            record => { record-state $state (snapshot $source $target $codesign) }
            _ => { error make {msg: $"Unknown application operation ($operation)"} }
        }
    } catch {|error|
        if $operation in [check-permission preflight sync] { print --stderr $"sysinit: ($error.msg)" }

        exit 1
    }
}
