#!/usr/bin/env nu

# Audio outputs as {id, name, current}, from SwitchAudioSource on macOS or pactl on Linux.
def devices [] {
    match $nu.os-info.name {
        "macos" => {
            let active = (^SwitchAudioSource -c -t output -f json | from json | get id)
            # SwitchAudioSource prints one JSON object per line rather than an array.
            ^SwitchAudioSource -a -t output -f json
            | lines
            | where {|line| $line | str trim | is-not-empty }
            | each {|line| $line | from json | {id: $in.id, name: $in.name, current: ($in.id == $active)} }
        }
        "linux" => {
            let active = (^pactl get-default-sink | str trim)
            ^pactl --format=json list sinks
            | from json
            | each {|sink| {id: $sink.name, name: $sink.description, current: ($sink.name == $active)} }
        }
        $other => { fail $"unsupported OS: ($other)" }
    }
}

def fail [message: string] {
    print -e $"audio-switcher: ($message)"
    exit 1
}

def switch-to [id: string, outputs: list<any>] {
    if ($outputs | where id == $id | is-empty) {
        fail $"unknown audio device ID: ($id)"
    }
    if $nu.os-info.name == "macos" {
        ^SwitchAudioSource -t output -i $id | ignore
    } else {
        ^pactl set-default-sink $id
    }
}

# Print the audio outputs as JSON.
def "main list" [] {
    devices | to json --raw
}

# Switch to the output with this ID.
def "main set" [id: string] {
    switch-to $id (devices)
}

# Select an audio output with fzf.
def main [] {
    let outputs = (devices)
    if ($outputs | is-empty) {
        fail "no audio outputs available"
    }
    let choice = (
        $outputs
        | enumerate
        | each {|row| $"($row.index)\t(if $row.item.current { '* ' } else { '' })($row.item.name | str replace --all --regex '[\n\r\t]' ' ')" }
        | str join "\n"
        | ^fzf --no-multi --delimiter="\t" --with-nth=2.. "--prompt=Audio output> "
        | complete
    )
    # fzf exits 1 with no match and 130 when dismissed; both mean no change.
    if $choice.exit_code in [1 130] {
        return
    }
    if $choice.exit_code != 0 {
        fail $"fzf exited ($choice.exit_code)"
    }
    let index = (
        $choice.stdout
        | str trim
        | split row "\t"
        | first
        | into int
    )
    switch-to ($outputs | get $index | get id) $outputs
}
