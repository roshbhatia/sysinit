use std/assert

def main [script: path] {
    let script = $script | path expand --strict

    let root = mktemp --directory | path expand --strict

    let config = $root | path join config

    let bin = $root | path join bin

    let worktree = $root | path join 'working directory'

    mkdir ($config | path join sysinit) ($config | path join nushell) $bin $worktree

    touch ($config | path join nushell config.nu) ($config | path join nushell env.nu)

    try {
        let help = with-env {XDG_CONFIG_HOME: ($root | path join absent)} {
            ^$nu.current-exe --no-config-file $script --help | complete
        }

        assert equal $help.exit_code 0 $help.stderr

        assert ($help.stdout | str contains 'agents list')

        let fixture = '#!NU --no-config-file
def --wrapped main [...args: string] {
    {args: $args, cwd: $env.PWD} | to json --raw
}'

        for command in [fixture-pi fixture-codex threads] {
            $fixture | str replace NU $nu.current-exe | save ($bin | path join $command)

            chmod +x ($bin | path join $command)
        }

        let attention_fixture = '#!NU --no-config-file
def --wrapped main [...args: string] {
    let agents = if ($args | is-empty) {
        [{pane_id: 7, workspace: project, agent: pi, status: done}]
    } else if $args.5? == arrakis {
        [{pane_id: 7, workspace: remote, agent: codex, status: waiting}]
    } else {
        exit 255
    }

    {discovery_state: fresh, agents: $agents} | to json --raw
}'

        for command in [agent-sessions ssh] {
            let path = $bin | path join $command

            $attention_fixture | str replace NU $nu.current-exe | save $path

            chmod +x $path
        }

        {
            favorites: [missing codex]
            agents: [
                {
                    name: pi
                    label: Pi
                    command: fixture-pi
                    launch: {
                        resumeArgs: [--resume]
                    }
                }
                {name: missing, label: Missing, command: fixture-missing-agent}
                {name: codex, label: Codex, command: fixture-codex}
            ]
        } | to json | save ($config | path join sysinit agents.json)

        with-env {XDG_CONFIG_HOME: $config, PATH: ($env.PATH | prepend $bin)} {
            cd $worktree
            let available = ^$nu.current-exe --no-config-file $script list | from json --strict
            assert equal ($available | get name) [codex pi]
            let all = ^$nu.current-exe --no-config-file $script list --all | from json --strict
            assert equal ($all | get name) [missing codex pi]
            assert equal ($all | get available) [false true true]
            assert equal ($all | columns) [name label command available]
            let details = ^$nu.current-exe --no-config-file $script list --details | from json --strict
            assert equal ($details | where name == pi | get 0.launch.resumeArgs) [--resume]

            let launched = ^$nu.current-exe --no-config-file $script pi --model 'fixture model' | from json --strict
            assert equal $launched.args [--model 'fixture model']
            assert equal $launched.cwd $worktree

            let harness_help = ^$nu.current-exe --no-config-file $script pi --help | from json --strict
            assert equal $harness_help.args [--help]

            let threads = ^$nu.current-exe --no-config-file $script threads --all --print | from json --strict
            assert equal $threads.args [--all --print]
            assert equal $threads.cwd $worktree

            let attention = ^$nu.current-exe --no-config-file $script attention --json arrakis offline | from json --strict
            assert equal ($attention.agents | get host) [arrakis local]
            assert equal ($attention.agents | get pane_id) [7 7]
            assert equal ($attention.hosts | where host == offline | get 0.state) unavailable

            let unavailable = ^$nu.current-exe --no-config-file $script missing | complete
            assert ($unavailable.exit_code != 0)
            assert ($unavailable.stderr | str contains 'unavailable on PATH')
        }
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root
}
