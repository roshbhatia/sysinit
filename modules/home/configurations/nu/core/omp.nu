#!/usr/bin/env nu
# shellcheck disable=all
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# modules/darwin/home/nu/core/omp.nu (begin)

if ($env.config? | is-not-empty) {
    $env.config = ($env.config | upsert render_right_prompt_on_last_line true)
}

$env.POWERLINE_COMMAND = 'oh-my-posh'
$env.POSH_THEME = $"($env.XDG_CONFIG_HOME)/oh-my-posh/themes/sysinit.omp.json"
$env.PROMPT_INDICATOR = ""
$env.POSH_SESSION_ID = (random uuid)
$env.POSH_SHELL = "nu"
$env.POSH_SHELL_VERSION = (version | get version)

let _omp_executable: string = $"/etc/profiles/per-user/($env.USER)/bin/oh-my-posh"

def --wrapped _omp_get_prompt [
    type: string,
    ...args: string
] {
    mut execution_time = -1
    mut no_status = true

    if $env.CMD_DURATION_MS != '0823' {
        $execution_time = $env.CMD_DURATION_MS
        $no_status = false
    }

    (
        ^$_omp_executable print $type
            --save-cache
            --shell=nu
            $"--shell-version=($env.POSH_SHELL_VERSION)"
            $"--status=($env.LAST_EXIT_CODE)"
            $"--no-status=($no_status)"
            $"--execution-time=($execution_time)"
            $"--terminal-width=((term size).columns)"
            ...$args
    )
}

$env.PROMPT_MULTILINE_INDICATOR = (
    ^$_omp_executable print secondary
        --shell=nu
        $"--shell-version=($env.POSH_SHELL_VERSION)"
)

$env.PROMPT_COMMAND = {||
    mut clear = false
    if $nu.history-enabled {
        $clear = (history | is-empty) or ((history | last 1 | get 0.command) == "clear")
    }

    if ($env.SET_POSHCONTEXT? | is-not-empty) {
        do --env $env.SET_POSHCONTEXT
    }

    _omp_get_prompt primary $"--cleared=($clear)"
}

$env.PROMPT_COMMAND_RIGHT = {|| _omp_get_prompt right }
# modules/darwin/home/nu/core/omp.nu (end)

