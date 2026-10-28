def atuin-preserve-prompt [mode: string] {
    let primary = $env.PROMPT_COMMAND? | default ''
    let indicator = match $mode {
        vi_insert => ($env.PROMPT_INDICATOR_VI_INSERT? | default ': ')
        vi_normal => ($env.PROMPT_INDICATOR_VI_NORMAL? | default '> ')
        _ => ($env.PROMPT_INDICATOR? | default '> ')
    }
    for part in [$primary $indicator] {
        print -n (if ($part | describe) == closure { do $part } else { $part })
    }
    print (commandline)
}

# ExecuteHostCommand clears the editing line before handing the terminal over.
# Retain the configured prompt above Atuin, then let its native widget edit the buffer.
$env.config.keybindings = ($env.config.keybindings | each {|binding|
    if $binding.name == atuin {
        $binding.mode | each {|mode|
            $binding
            | update name $"atuin-($mode)"
            | update mode [$mode]
            | update event.cmd $"($binding.event.cmd | lines | first)\natuin-preserve-prompt ($mode)\n($binding.event.cmd)"
        }
    } else { [$binding] }
} | flatten)
