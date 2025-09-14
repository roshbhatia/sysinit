#!/usr/bin/env nu
# shellcheck disable=all
def should_run_zellij [] {
    # Check if we should start zellij
    (
        ($env.ZELLIJ? | default "") == "" and
        ($env.TMUX? | default "") == "" and
        ($env.TERM_PROGRAM? | default "") != "vscode" and
        ($env.NVIM? | default "") == ""
    )
}

# Auto-start zellij if conditions are met
if (should_run_zellij) and (which zellij | is-not-empty) {
    # Check if this is an interactive session and the first level shell
    if ($env.SHLVL? | default 1) == 1 {
        if ($env.ZELLIJ_AUTO_ATTACH? | default "false") == "true" {
            exec zellij attach -c
        } else {
            exec zellij
        }
    }
}
