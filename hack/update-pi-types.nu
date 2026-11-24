const root = path self | path dirname | path dirname

def main [] {
    let version = open ($root | path join _sources generated.json) | get pi-coding-agent.version

    let project = $root | path join checks agents pi-types

    let manifest = open ($project | path join package.json)

    let sdk = ["@earendil-works/pi-coding-agent" "@earendil-works/pi-tui"]

    if ($sdk | all {|package| ($manifest.devDependencies | get $package) == $version }) { return }

    let staging = mktemp --directory

    try {
        cp ($project | path join package.json) ($project | path join package-lock.json) $staging

        let dependencies = $sdk | each {|package| $'($package)@($version)' }

        let updated = do {
            cd $staging

            ^npm install --package-lock-only --ignore-scripts --no-audit --no-fund --save-dev --save-exact ...$dependencies | complete
        }

        if $updated.exit_code != 0 { error make {msg: $updated.stderr} }

        let lockfile = $staging | path join package-lock.json

        let hash = ^prefetch-npm-deps $lockfile | complete

        if $hash.exit_code != 0 { error make {msg: $hash.stderr} }

        let hashfile = $staging | path join npm-deps-hash

        (($hash.stdout | str trim) + "\n") | save $hashfile

        cp --force ($staging | path join package.json) $lockfile $hashfile $project
    } catch {|failure|
        rm --recursive --force $staging

        error make $failure
    }

    rm --recursive --force $staging
}
