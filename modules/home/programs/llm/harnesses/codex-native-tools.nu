const native_servers = [computer-use cua_repl node_repl]
const browser_plugin = 'browser@openai-bundled'

def write-atomically [
    root: path
    path: path
    text: string
    chmod_command: string
] {
    let temporary = mktemp --tmpdir-path $root .native-tools-XXXXXXXXXX

    try {
        $text | save --force $temporary

        let permissions = ^$chmod_command $'--reference=($path)' $temporary | complete

        if $permissions.exit_code != 0 { error make {msg: $permissions.stderr} }

        mv --force $temporary $path
    } catch {|failure|
        rm --force $temporary

        error make $failure
    }
}

def render [document: record] {
    if ($document | is-empty) {
        "[mcp_servers]\n"
    } else {
        $document | to toml
    }
}

def migrate-document [document: record, is_config: bool] {
    mut document = $document

    if 'mcp_servers' in $document {
        mut servers = $document.mcp_servers

        for name in $native_servers {
            if $name not-in $servers { continue }

            let server = $servers | get $name

            let disabled = $server.enabled? == false

            let inert = $name != node_repl or ($server.command? | default /bin/false | str ends-with /bin/false)

            if not $is_config or ($disabled and $inert) {
                $servers = $servers | reject $name
            } else if $disabled {
                $servers = $servers | update $name ($server | reject enabled)
            }
        }

        $document = $document | update mcp_servers $servers
    }

    let plugins = $document.plugins? | default {}

    if $browser_plugin in $plugins {
        $document = $document | update plugins (
            if $is_config {
                $plugins | update $browser_plugin ($plugins | get $browser_plugin | upsert enabled true)
            } else {
                $plugins | reject $browser_plugin
            }
        )
    }

    if 'features' in $document {
        $document = $document | update features ($document.features | reject --optional js_repl)
    }

    $document
}

def migrate [root: path, chmod_command: string] {
    let marker = $root | path join .sysinit-native-tools-v1

    let config = $root | path join config.toml

    if ($marker | path exists) or not ($config | path exists) { return }

    for path in [
        $config
        ($root | path join .config.toml.nix-base)
    ] {
        if not ($path | path exists) { continue }

        let document = open --raw $path | from toml

        let updated = migrate-document $document ($path == $config)

        if $updated == $document { continue }

        let backup = $'($path).before-native-tools'

        if not ($backup | path exists) {
            cp --preserve [mode timestamps] $path $backup

            ^$chmod_command 600 $backup
        }

        write-atomically $root $path (render $updated) $chmod_command
    }

    "" | save $marker

    ^$chmod_command 600 $marker
}

# Codex rejects an MCP server table with no transport; v1 of migrate left these.
def drop-transportless-servers [root: path, chmod_command: string] {
    let config = $root | path join config.toml

    if not ($config | path exists) { return }

    let document = open --raw $config | from toml

    let servers = $document.mcp_servers? | default {}

    let empty = $native_servers | where {|name|
        $name in $servers and ($servers | get $name | columns | all {|key| $key not-in [command url] })
    }

    if ($empty | is-empty) { return }

    let updated = $document | update mcp_servers ($servers | reject ...$empty)

    write-atomically $root $config (render $updated) $chmod_command
}

def main [root?: path, --chmod-command: string = chmod] {
    let root = $root | default ($env.HOME | path join .codex)

    migrate $root $chmod_command

    drop-transportless-servers $root $chmod_command
}
