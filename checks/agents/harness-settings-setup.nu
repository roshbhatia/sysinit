use ../lib/process.nu checked-command
use std/assert

def main [
    settings: path
    configuration: path
    providers: path
    probe: path
    timeout: path
    agents: path
    goose: string
] {
    let entry = open --raw $agents | from json | get agent_servers.goose

    assert equal $entry.command $goose

    assert equal $entry.args [acp]

    $env.HOME = $env.TMPDIR | path join home

    $env.XDG_CONFIG_HOME = $env.HOME | path join .config

    $env.COPILOT_HOME = $env.HOME | path join .copilot

    mkdir $env.COPILOT_HOME

    cp $settings ($env.COPILOT_HOME | path join settings.json)

    checked-command copilot config --list --json | save parsed.json

    let config = checked-command yq -o=json '.' $configuration | from json

    $config
    | update providers.directory $providers
    | update log ($env.TMPDIR | path join gate.jsonl)
    | update chains {PreToolUse: ($config.chains.PreToolUse | where provider == bash-guard)}
    | to json
    | save gate.json

    $env.GATE_CONFIG = $env.PWD | path join gate.json

    checked-command $nu.current-exe --no-config-file $probe $timeout | print
}
