#!/usr/bin/env nu

# Attach a WezTerm mux domain without starting a second GUI instance.
def main [domain: string] {
    let config = $"($env.XDG_CONFIG_HOME? | default $"($env.HOME)/.config")/wezterm/config.json"
    let local_domain = if ($config | path exists) {
        open $config | get -o localDomain | default "local"
    } else {
        "local"
    }
    # A second GUI on the local mux mirrors its windows; closing either closes both.
    if $domain in ["local" "unix" $local_domain] {
        print -e $"connect: ($domain) is the local mux, which the running GUI already shows; use wezspawn to open a window"
        exit 1
    }
    # The pane's socket names the local mux, which has no SSH domains; the GUI owns them.
    let clients = ^env -u WEZTERM_UNIX_SOCKET wezterm cli --no-auto-start list-clients --format json | complete
    if $clients.exit_code == 0 and (($clients.stdout | from json | length) > 0) {
        ^env -u WEZTERM_UNIX_SOCKET wezterm cli --no-auto-start spawn --new-window --domain-name $domain
        exit $env.LAST_EXIT_CODE
    }
    ^wezterm connect $domain
    exit $env.LAST_EXIT_CODE
}
