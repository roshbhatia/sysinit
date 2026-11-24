use catalog.nu agent-catalog
use attention.nu

const usage = 'Usage: agents [HARNESS [ARGS...]]
       agents list [--all] [--details]
       agents attention [--json] [HOST...]
       agents threads [ARGS...]

Run without arguments to choose an installed harness or a captured conversation.
Harness arguments pass through unchanged. List writes JSON.'

def launch-choices [--all] {
    let catalog = agent-catalog

    let favorites = $catalog.favorites? | default [] | enumerate

    $catalog.agents
    | where {|agent| $all or $agent.available }
    | each {|agent|
        let rank = $favorites | where item == $agent.name | get -o 0.index | default ($favorites | length)
        $agent | insert rank $rank
    }
    | sort-by rank label
    | reject rank
}

def "main list" [--all, --details] {
    let choices = launch-choices --all=$all

    if $details {
        $choices | to json --raw
    } else {
        $choices | select name label command available | to json --raw
    }
}

def --wrapped "main threads" [...args: string] {
    exec threads ...$args
}

def "main attention" [--json, ...hosts: string] {
    attention --json=$json ...$hosts
}

def --wrapped main [name?: string, ...args: string] {
    if $name in [help -h --help] {
        print $usage

        return
    }

    let choices = launch-choices --all

    let agent = if $name == null {
        let installed = $choices | where available | select label command

        let entries = if (which threads | where type == external | is-not-empty) {
            $installed | append {label: 'Captured conversations', command: threads}
        } else {
            $installed
        }

        if ($entries | is-empty) { error make {msg: 'No registered agent commands or threads command are on PATH.'} }

        $entries | input list --fuzzy --display label 'Choose an agent or conversation:'
    } else {
        let selected = $choices | where {|entry| $entry.name == $name or $entry.command == $name } | get -o 0

        if $selected == null { error make {msg: $"Unknown agent ($name). Run agents list --all."} }

        if not $selected.available { error make {msg: $"Agent command ($selected.command) is unavailable on PATH."} }

        $selected
    }

    if $agent != null {
        exec $agent.command ...$args
    }
}
