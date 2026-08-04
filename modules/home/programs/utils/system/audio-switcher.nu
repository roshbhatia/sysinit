#!/usr/bin/env nu

def main [] {
    let os = $nu.os-info.name

    match $os {
        "linux" => {
            if (which wpctl | is-empty) {
                print "(ansi red_bold)[ERROR](ansi reset) wpctl (WirePlumber) not found"
                exit 1
            }
            if (which rofi | is-empty) {
                print "(ansi red_bold)[ERROR](ansi reset) rofi not found"
                exit 1
            }

            let status = wpctl status
            
            let lines = $status | lines
            let sink_start = $lines | zip (0..(($lines | length) - 1)) | where {|it| $it.0 =~ "Sinks:"} | get 1 | first
            
            let next_section = $lines | zip (0..(($lines | length) - 1)) 
                | skip ($sink_start + 1) 
                | where {|it| ($it.0 | str trim | is-empty) or ($it.0 | str starts-with " ") == false} 
                | get 1 | first

            let sink_lines = $lines | slice ($sink_start + 1)..<$next_section | str trim
            
            let sinks = $sink_lines | each {|line|
                let is_active = $line | str starts-with "*"
                let clean_line = if $is_active { $line | str replace "*" "" | str trim } else { $line }
                
                let parts = $clean_line | split row "."
                let id = $parts | first | str trim
                let name = $parts | skip 1 | str join "." | split row "[" | first | str trim
                
                { id: $id, name: $name, active: $is_active }
            }

            if ($sinks | is-empty) {
                print "(ansi red_bold)[ERROR](ansi reset) No audio sinks found"
                exit 1
            }

            let rofi_input = $sinks | each {|s| 
                if $s.active { $"(ansi green)* ($s.name)(ansi reset)" } else { $s.name }
            } | str join "
"

            let selected_name = $rofi_input | ^rofi -dmenu -p "Select Audio Output" -i -markup-rows
            
            if ($selected_name | is-empty) { exit 0 }

            let clean_selected = $selected_name | str replace --all r#'\x1b\[[0-9;]*m'# "" | str replace "* " "" | str trim
            let target = $sinks | where name == $clean_selected | first

            wpctl set-default $target.id
            
            if (which notify-send | is-not-empty) {
                ^notify-send "Audio Output Switched" $"Default output set to: ($target.name)" -i audio-speakers
            }
        }
        "macos" => {
            if (which SwitchAudioSource | is-empty) {
                print "(ansi red_bold)[ERROR](ansi reset) SwitchAudioSource not found. Install with: brew install switchaudio-osx"
                exit 1
            }

            let devices = ^SwitchAudioSource -a -t output | lines
            let current = ^SwitchAudioSource -c
            
            let rofi_input = $devices | each {|d|
                if $d == $current { $"* ($d)" } else { $d }
            } | str join "
"

            let selected = if (which rofi | is-not-empty) {
                $rofi_input | ^rofi -dmenu -p "Select Audio Output" -i
            } else if (which fzf | is-not-empty) {
                $rofi_input | ^fzf --header "Select Audio Output"
            } else {
                print "Current: ($current)"
                print "Available:"
                $devices | each {|d| print $"  ($d)" }
                return
            }

            if ($selected | is-empty) { exit 0 }
            let clean_selected = $selected | str replace "* " "" | str trim
            
            ^SwitchAudioSource -s $clean_selected
            
            osascript -e $'display notification "Default output set to: ($clean_selected)" with title "Audio Output Switched"'
        }
        _ => {
            print $"(ansi red_bold)[ERROR](ansi reset) Unsupported OS: ($os)"
            exit 1
        }
    }
}
