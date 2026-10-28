def atuin-preserve-prompt [_mode: string] {
    print ''
}

# ExecuteHostCommand leaves the rendered editing line on screen. Start Atuin on
# the following line without printing another copy of the prompt or input.
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
