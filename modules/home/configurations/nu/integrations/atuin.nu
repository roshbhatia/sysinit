#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/atuin.nu (begin)
$env.ATUIN_SESSION = (atuin uuid)
hide-env -i ATUIN_HISTORY_ID

# Magic token to make sure we don't record commands run by keybindings
let atuin_keybinding_token = $"# (random uuid)"

let atuin_pre_execution = {||
    if ($nu | get --optional history-enabled) == false {
        return
    }
    let cmd = (commandline)
    if ($cmd | is-empty) {
        return
    }
    if not ($cmd | str starts-with $atuin_keybinding_token) {
        $env.ATUIN_HISTORY_ID = (atuin history start -- $cmd)
    }
}

let atuin_pre_prompt = {||
    let last_exit = $env.LAST_EXIT_CODE
    if 'ATUIN_HISTORY_ID' not-in $env {
        return
    }
    with-env { ATUIN_LOG: error } {
        do { atuin history end $'--exit=($last_exit)' -- $env.ATUIN_HISTORY_ID } | complete

    }
    hide-env ATUIN_HISTORY_ID
}

def atuin_search_cmd [...flags: string] {
    let nu_version = do {
        let version = version
        let major = $version.major?
        if $major != null {
            # These members are only available in versions > 0.92.2
            [$major $version.minor $version.patch]
        } else {
            # So fall back to the slower parsing when they're missing
            $version.version | split row '.' | into int
        }
    }
    [
        $atuin_keybinding_token,
        ([
            `with-env { ATUIN_LOG: error, ATUIN_QUERY: (commandline) } {`,
                (if $nu_version.0 <= 0 and $nu_version.1 <= 90 { 'commandline' } else { 'commandline edit' }),
                (if $nu_version.1 >= 92 { '(run-external atuin search' } else { '(run-external --redirect-stderr atuin search' }),
                    ($flags | append [--interactive] | each {|e| $'"($e)"'}),
                (if $nu_version.1 >= 92 { ' e>| str trim)' } else {' | complete | $in.stderr | str substring ..-1)'}),
            `}`,
        ] | flatten | str join ' '),
    ] | str join "\n"
}

$env.config = ($env | default {} config).config
$env.config = ($env.config | default {} hooks)
$env.config = (
    $env.config | upsert hooks (
        $env.config.hooks
        | upsert pre_execution (
            $env.config.hooks | get --optional pre_execution | default [] | append $atuin_pre_execution)
        | upsert pre_prompt (
            $env.config.hooks | get --optional pre_prompt | default [] | append $atuin_pre_prompt)
    )
)

$env.config = ($env.config | default [] keybindings)

$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings
        | append {
            name: atuin
            modifier: control
            keycode: char_r
            mode: [emacs, vi_normal, vi_insert]
            event: { send: executehostcommand cmd: (atuin_search_cmd) }
        }
    )
)

$env.config = (
    $env.config | upsert keybindings (
        $env.config.keybindings
        | append {
            name: atuin
            modifier: none
            keycode: up
            mode: [emacs, vi_normal, vi_insert]
            event: {
                until: [
                    {send: menuup}
                    {send: executehostcommand cmd: (atuin_search_cmd '--shell-up-key-binding') }
                ]
            }
        }
    )
)
# modules/darwin/home/nu/core/atuin.nu (end)

