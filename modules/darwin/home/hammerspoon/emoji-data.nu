#!/usr/bin/env nu

def main [source: path, output: path] {
    let data = $source | path join internal/providers/symbols/data
    let variations = open --raw ($data | path join variations.txt)
    | lines
    | each {|line| $line | split row '#' | first | str trim }
    | where {|line| $line != "" }
    | each {|line| char --unicode ($line | split words | first) }
    let annotations = [
        ($data | path join en.xml)
        ($data | path join derived/en.xml)
    ]
    | each {|file|
            open --raw $file
            | from xml --allow-dtd
            | get content
            | where tag == annotations
            | get 0.content
        }
    | flatten
    | where tag == annotation
    | each {|node|
            {
                cp: ($node.attributes.cp? | default "")
                type: ($node.attributes.type? | default "")
                text: ($node.content | get content | str join | str trim)
            }
        }
    | where {|node| $node.cp != "" and $node.text != "" }
    $annotations
    | group-by cp
    | transpose cp annotations
    | each {|group|
        let names = $group.annotations | where type == tts | get text
        if ($names | is-empty) { return null }
        let name = $names | last
        let shortcode = $name | str lowercase | str replace --all --regex '[^a-z0-9]+' '_' | str trim --char '_'
        let terms = $group.annotations
            | where type != tts
            | get text
            | each {|text| $text | split row '|' | str trim }
            | flatten
            | where {|word| $word != "" }
            | append [$name $shortcode]
            | str lowercase
            | uniq
            | sort
        {
            cp: (if $group.cp in $variations { $group.cp + (char --unicode FE0F) } else { $group.cp })
            name: $name
            code: $shortcode
            search: ($terms | str join ' ')
        }
    }
    | compact
    | to json --raw
    | save --force $output
}
