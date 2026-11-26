use std/assert

let history = $env.config.keybindings | where modifier == control and keycode == char_r

for mode in [emacs vi_normal vi_insert] {
    let binding = $history | where {|binding| $mode in $binding.mode} | last

    assert equal $binding.name $'atuin-($mode)' $'Atuin does not own Ctrl-R in ($mode)'
}

let place = 'git --ver' | commandline complete --input | get place
let completion = do $env.config.completions.external.completer $place

assert ($completion | any {|item| $item.value == '--version'}) 'Atuin displaced the existing completion chain'
