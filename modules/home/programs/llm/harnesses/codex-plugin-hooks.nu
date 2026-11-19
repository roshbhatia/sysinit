def main [root?: path, --chmod-command: string = chmod] {
    let root = $root | default ($env.HOME | path join .codex)

    for path in (
        glob ($root | path join plugins cache openai-codex codex '*' hooks hooks.json)
    ) {
        let document = open --raw $path | from json

        let groups = $document.hooks.SessionEnd? | default []

        let updated = $groups | each {|group|
            if 'hooks' not-in $group { return $group }
            $group | upsert hooks ($group.hooks? | default [] | each {|hook|
                let timeout = $hook.timeout?
                if (($timeout | describe) in [int float]) and $timeout > 3 {
                    $hook | update timeout 3
                } else {
                    $hook
                }
            })
        }

        if $updated == $groups { continue }

        let backup = $path | path dirname | path join hooks.json.before-sysinit-timeout

        if not ($backup | path exists) { cp --preserve [mode timestamps] $path $backup }

        let temporary = mktemp --tmpdir-path ($path | path dirname) .hooks-XXXXXXXXXX

        try {
            $document | update hooks.SessionEnd $updated | to json --indent 2 | $in + "\n" | save --force $temporary

            let permissions = ^$chmod_command $'--reference=($path)' $temporary | complete

            if $permissions.exit_code != 0 { error make {msg: $permissions.stderr} }

            mv --force $temporary $path
        } catch {|failure|
            rm --force $temporary

            error make $failure
        }
    }
}
