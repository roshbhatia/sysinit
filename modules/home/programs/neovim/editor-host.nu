def --wrapped main [tool: string, program: string, ...args: string] {
    let ui = if $tool == changes {
        $env.CHANGES_UI_HOST? | default neovim
    } else {
        $env.TRACES_UI_HOST? | default neovim
    }

    let flags = $args
    | take until {|arg| $arg == '--'}
    | where {|arg| $arg | str starts-with '-'}
    | each {|arg| $arg | split row '=' | first | str trim --left --char '-'}

    let terminal = (is-terminal --stdin) and (is-terminal --stdout)

    let interactive = if $tool == changes {
        (
            (($args | is-empty) and $terminal)
            or (($args | get 0?) == 'interactive' and not ('help' in $flags or '-h' in $args))
        )
    } else {
        (
            not (($args | get 0?) in [provider generate completion help])
            and not ($flags | any {|flag| $flag in [json once list view format version help h]})
            and $terminal
        )
    }

    if not $interactive or $ui == 'native' {
        exec $program ...$args
    }

    if $ui != 'neovim' {
        error make {msg: $"($tool): UI host must be neovim or native"}
    }

    if not ((which nvim) | is-not-empty) {
        error make {msg: $"($tool): managed Neovim is required for the neovim UI host"}
    }

    let query = if $tool == changes and ($args | is-empty) { [interactive] } else { $args }

    $env.SYSINIT_EDITOR_QUERY = {tool: $tool, program: $program, args: $query} | to json --raw

    exec nvim -c "lua if vim.fn.exists(':SysinitEditorQuery') == 2 then vim.cmd.SysinitEditorQuery() else io.stderr:write('The Sysinit Neovim workbench is required\\n'); vim.cmd.cquit() end"
}
