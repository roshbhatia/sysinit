export def agent-catalog [] {
    let config = $env.XDG_CONFIG_HOME? | default ($env.HOME | path join .config)

    let catalog = open --raw ($config | path join sysinit agents.json) | from json --strict

    $catalog | update agents {|record|
        $record.agents | each {|agent|
            $agent | insert available (which $agent.command | where type == external | is-not-empty)
        }
    }
}
