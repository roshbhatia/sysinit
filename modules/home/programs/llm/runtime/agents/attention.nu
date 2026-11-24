def snapshot [host: string] {
    let result = if $host == local {
        ^agent-sessions | complete
    } else {
        ^timeout 8s ssh -o BatchMode=yes -o ConnectTimeout=3 -- $host 'agent-sessions --mux' | complete
    }

    if $result.exit_code != 0 {
        return {
            host: $host
            state: unavailable
            agents: []
        }
    }

    let catalog = try {
        $result.stdout | from json --strict
    } catch {
        {}
    }

    if $catalog.discovery_state? != fresh or $catalog.agents? == null {
        return {
            host: $host
            state: unavailable
            agents: []
        }
    }

    {host: $host, state: fresh, agents: $catalog.agents}
}

export def main [--json, ...hosts: string] {
    let snapshots = [local] ++ $hosts | uniq | par-each {|host| snapshot $host }

    let agents = $snapshots | each {|snapshot|
        $snapshot.agents | each {|agent|
            let rank = match $agent.status {
                waiting => 0
                done => 1
                _ => 2
            }

            $agent | merge {host: $snapshot.host, rank: $rank}
        }
    } | flatten | sort-by rank host workspace pane_id | reject rank

    if $json {
        return ({
            hosts: ($snapshots | select host state)
            agents: $agents
        } | to json --raw)
    }

    let unavailable = $snapshots | where state == unavailable | get host | str join ', '

    if ($unavailable | is-not-empty) {
        print --stderr $"Agent status unavailable on ($unavailable)."
    }

    if ($agents | is-empty) {
        print 'No active agent reports.'

        return
    }

    let selected = $agents
    | insert label {|row| $"($row.status)  ($row.host) / ($row.workspace)  ($row.agent)  ($row.reason | default '')" }
    | input list --fuzzy --display label 'Agent activity'

    if $selected == null { return }

    if $selected.host != local { exec tether attach $selected.host }

    let live = snapshot local

    let pane = $live.agents | any {|row| $row.pane_id == $selected.pane_id and $row.tty == $selected.tty and $row.workspace == $selected.workspace }

    if not $pane { error make {msg: 'That agent pane is no longer available.'} }

    ^ty pane focus ($selected.pane_id | into string) | ignore
}
