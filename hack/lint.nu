const root = path self | path dirname | path dirname

def available [command: string] {
    which $command | is-not-empty
}

def files-for [scope: string, pattern: string, configuration: string = '^$'] {
    let selected = if $scope == all {
        ^git ls-files | lines
    } else {
        ^git diff --cached --name-only --diff-filter=ACMR | lines
    }

    let candidates = if $scope == all or ($selected | any {|file| $file =~ $configuration}) {
        ^git ls-files | lines
    } else {
        $selected
    }

    $candidates | where {|file| $file =~ $pattern and ($file | path type) == file}
}

def check [
    label: string
    command: list<string>
    --directory: path = '.'
    --silent
] {
    print --stderr $'==> ($label)'

    let result = do {
        cd $directory

        ^($command.0) ...($command | skip 1) | complete
    }

    let failed = $result.exit_code != 0 or ($silent and ($result.stdout != '' or $result.stderr != ''))

    print --no-newline $result.stdout

    print --stderr --no-newline $result.stderr

    if $failed { print --stderr $'FAIL: ($label)' }

    not $failed
}

def main [--all] {
    cd $root

    let scope = if $all { 'all' } else { 'staged' }

    let temporary = (^mktemp -d | str trim)

    let result = try {
        run-checks $scope $temporary
    } catch {|failure|
        rm --recursive $temporary

        error make $failure
    }

    rm --recursive $temporary

    if not $result { exit 1 }
}

def run-checks [scope: string, temporary: path] {
    mut results = []

    let formatting = (files-for
        $scope
        '.'
        '(treefmt\.toml|nufmt\.nuon|flake/formatter\.nix|hack/format\.nu)$'
    )

    if ($formatting | is-not-empty) and (available treefmt) {
        $results = (
            $results
            | append (check formatting [nu --no-config-file hack/format.nu --check ...$formatting])
        )
    }

    let structural = (files-for
        $scope
        '\.(go|nix|py|ts|tsx)$'
        '(^sgconfig\.yml$|/ast-grep/rules/|^\.ast-grep/rules/)'
    )

    if ($structural | is-not-empty) and (available ast-grep) {
        $results = ($results | append (check ast-grep [ast-grep scan -c sgconfig.yml ...$structural]))
    }

    let nix = files-for $scope '\.nix$' | where $it != '_sources/generated.nix'

    if ($nix | is-not-empty) {
        $results = ($results | append (check nixfmt [nixfmt --check ...$nix]))

        if (available statix) {
            let isolated = $temporary | path join statix

            mkdir $isolated

            $nix | str join (char nul) | ^tar -c --null -T - | ^tar -x -C $isolated

            $results = (
                $results
                | append (check statix [
                    statix
                    check
                    --unrestricted
                    --config
                    $root
                    .
                ] --directory $isolated)
            )
        }

        if (available deadnix) {
            $results = ($results | append (check deadnix [deadnix --fail ...$nix]))
        }
    }

    let lua = files-for $scope '\.lua$' '(stylua\.toml$|(^|/)\.luarc\.json$)'

    if ($lua | is-not-empty) and (available stylua) {
        $results = ($results | append (check stylua [stylua --check ...$lua]))
    }

    if ($lua | is-not-empty) and (available lua-language-server) {
        for configuration in (
            ^git ls-files
            | lines
            | where {|file| $file =~ '(^|/)\.luarc\.json$' and ($file | path exists) }
        ) {
            let directory = $configuration | path dirname

            let name = $directory | str replace --all '/' '_'

            $results = ($results | append (check $'lua-language-server ($directory)' [
                lua-language-server $'--check=($directory)' $'--configpath=($configuration)'
                --checklevel=Warning --check_format=pretty
                $'--logpath=($temporary)/($name)-log' $'--metapath=($temporary)/($name)-meta'
            ]))
        }
    }

    let go = files-for $scope '\.go$' '(^\.golangci\.yml$|^pkgs/go\.(mod|sum)$)'

    if ($go | is-not-empty) and (available gofmt) {
        $results = ($results | append (check gofmt [gofmt -l ...$go] --silent))
    }

    if ($go | is-not-empty) and (available golangci-lint) {
        $results = (
            $results
            | append (check golangci-lint [golangci-lint run --config ../.golangci.yml ./...] --directory pkgs)
        )
    }

    let shells = files-for $scope '(\.sh$|^\.githooks/[a-z-]+$)'

    if ($shells | is-not-empty) and (available shellcheck) {
        $results = ($results | append (check shellcheck [shellcheck --shell=bash ...$shells]))
    }

    if (available zsh) {
        for file in (files-for $scope '\.zsh$') {
            $results = ($results | append (check $'zsh syntax ($file)' [zsh -n $file]))
        }
    }

    let nushell = files-for $scope '\.nu$'

    if ($nushell | is-not-empty) and (available nu) {
        if not (available nu_plugin_formats) {
            error make {msg: 'nu_plugin_formats is missing; run lint with nix develop'}
        }

        let plugin = which nu_plugin_formats | first | get path

        for file in $nushell {
            $results = (
                $results
                | append (
                    check $'nushell diagnostics ($file)' [
                        nu
                        --no-config-file
                        --plugins
                        $plugin
                        hack/check-nushell.nu
                        $file
                    ]
                )
            )
        }
    }

    for specification in [
        {
            label: yamllint
            pattern: '\.ya?ml$'
            configuration: '^\.yamllint\.yml$'
            command: [yamllint -c .yamllint.yml]
        }
        {
            label: actionlint
            pattern: '^\.github/workflows/.*\.ya?ml$'
            command: [actionlint]
        }
        {
            label: taplo
            pattern: '\.toml$'
            command: [taplo lint --no-schema]
        }
        {
            label: 'SVG syntax'
            pattern: '\.svg$'
            command: [xmllint --noout]
        }
        {
            label: 'TypeScript formatting'
            pattern: '\.tsx?$'
            configuration: '^tsconfig\.json$'
            command: [prettier --check]
        }
        {
            label: eslint
            pattern: '\.(js|mjs)$'
            configuration: '^eslint\.config\.mjs$'
            command: [eslint]
        }
    ] {
        let files = (files-for
            $scope
            $specification.pattern
            ($specification.configuration? | default '^$')
        )

        if ($files | is-not-empty) and (available $specification.command.0) {
            $results = ($results | append (check $specification.label [...$specification.command ...$files]))
        }
    }

    if (available jq) {
        for file in (files-for $scope '\.json$') {
            $results = ($results | append (check $'JSON syntax ($file)' [jq empty $file]))
        }
    }

    if (available cue) {
        for directory in (files-for $scope '\.cue$' | path dirname | uniq) {
            $results = ($results | append (check $'cue vet ($directory)' [cue vet $'./($directory)']))
        }
    }

    let c = files-for $scope '\.(c|h)$'

    if ($c | is-not-empty) and $nu.os-info.name == macos and (available clang) {
        $results = (
            $results
            | append (check 'C syntax' [clang -Wno-unused-command-line-argument -fsyntax-only ...$c])
        )
    }

    if (files-for $scope '\.tsx?$' '^tsconfig\.json$' | is-not-empty) and (available tsc) {
        $results = ($results | append (check 'TypeScript syntax' [tsc --project tsconfig.json]))
    }

    let python = files-for $scope '\.py$'

    if ($python | is-not-empty) {
        $results = (
            $results
            | append (
                check 'Python script blocks' [nu --no-config-file hack/check-script-blocks.nu ...$python]
            )
        )
    }

    $results | all {|success| $success}
}
