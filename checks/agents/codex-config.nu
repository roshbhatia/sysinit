use std/assert
use ../lib/process.nu checked-command

def reconcile [command: path] {
    checked-command $command | ignore

    let config = open ($env.HOME | path join .codex/config.toml)

    assert equal $config.desktop.external-agent-import-sync-enabled false

    assert equal $config.shell_environment_policy.set.PATH '/profile/bin:/usr/bin:/bin'
}

def main [
    reconciler: path
    bootstrap: path
    native: path
    chmod: path
    codex: path
] {
    $env.HOME = $env.TMPDIR | path join home

    mkdir ($env.HOME | path join .codex)

    let config = $env.HOME | path join .codex/config.toml

    "[desktop]\nexternal-agent-import-sync-enabled = true\n" | save $config

    reconcile $reconciler

    open --raw $config
    | str replace 'external-agent-import-sync-enabled = false' 'external-agent-import-sync-enabled = true'
    | save --force $config

    reconcile $reconciler

    $env.HOME = $env.TMPDIR | path join bootstrap-home

    mkdir ($env.HOME | path join .codex)

    let config = $env.HOME | path join .codex/config.toml

    let disabled = {
        mcp_servers: {
            computer-use: {enabled: false}
            cua_repl: {enabled: false}
            node_repl: {enabled: false}
        }
    }

    $disabled | to toml | save ($env.HOME | path join .codex/.config.toml.nix-base)

    $disabled
    | insert mcp_servers.computer-use.command '/user/computer-use'
    | insert mcp_servers.cua_repl.command '/user/cua'
    | insert mcp_servers.node_repl.command '/app/node_repl'
    | insert mcp_servers.node_repl.env {NATIVE_PIPE: '/app/pipe'}
    | insert plugins {'computer-use@openai-bundled': {enabled: false}, 'browser@openai-bundled': {enabled: false}}
    | insert features {js_repl: false}
    | to toml
    | save $config

    checked-command $nu.current-exe --no-config-file $native --chmod-command $chmod | ignore

    checked-command $bootstrap | ignore

    assert (checked-command $codex mcp list | str contains node_repl)

    let document = open $config

    assert ($document.mcp_servers.computer-use? == null)

    assert ($document.mcp_servers.cua_repl? == null)

    assert equal $document.mcp_servers.node_repl.command '/app/node_repl'

    assert equal $document.mcp_servers.node_repl.env.NATIVE_PIPE '/app/pipe'

    assert ($document.mcp_servers.node_repl.enabled? | default true)

    assert equal ($document.plugins | get 'computer-use@openai-bundled' | get enabled) false

    assert ($document.plugins | get 'browser@openai-bundled' | get enabled)

    assert ($document.features.js_repl? == null)

    $document | update plugins.browser@openai-bundled.enabled false | to toml | save --force $config

    checked-command $nu.current-exe --no-config-file $native --chmod-command $chmod | ignore

    assert equal (open $config | get plugins.browser@openai-bundled.enabled) false

    $env.HOME = $env.TMPDIR | path join empty-native-server-home

    mkdir ($env.HOME | path join .codex)

    touch ($env.HOME | path join .codex/.sysinit-native-tools-v1)

    let config = $env.HOME | path join .codex/config.toml

    {
        mcp_servers: {
            node_repl: {}
        }
        plugins: {
            'browser@openai-bundled': {enabled: false}
        }
    } | to toml | save $config

    checked-command $nu.current-exe --no-config-file $native --chmod-command $chmod | ignore

    let document = open $config

    assert ($document.mcp_servers?.node_repl? == null)

    assert equal ($document.plugins | get 'browser@openai-bundled' | get enabled) false

    checked-command $codex mcp list | ignore
}
