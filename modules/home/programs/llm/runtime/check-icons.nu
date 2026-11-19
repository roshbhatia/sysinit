def xpath [source: path, expression: string] {
    let result = ^xmllint --nonet --xpath $expression $source | complete

    if $result.exit_code != 0 { error make {msg: $result.stderr} }

    $result.stdout | str trim
}

def main [manifest: path, images?: path] {
    let sources = open --raw $manifest | from json

    for source in ($sources | transpose name path) {
        if $source.name !~ '^[a-z][a-z0-9_-]*$' {
            error make {msg: $'Invalid notification icon name: ($source.name)'}
        }

        let svg = "local-name(/*)='svg' and namespace-uri(/*)='http://www.w3.org/2000/svg' and boolean(/*/@viewBox)"

        if (xpath $source.path $svg) != 'true' {
            error make {msg: $'Icon needs an SVG viewBox: ($source.name)'}
        }

        let active = "count(//*[local-name()='script' or local-name()='foreignObject'])"

        if (xpath $source.path $active) != '0' {
            error make {msg: $'Active SVG content: ($source.name)'}
        }

        let external = "count(//@*[local-name()='href' and not(starts-with(., '#'))])"

        if (xpath $source.path $external) != '0' {
            error make {msg: $'External SVG reference: ($source.name)'}
        }

        if $images != null {
            let image = open --raw ($images | path join ($source.name + '.png'))

            if ($image | bytes at 0..7) != 0x[89504E470D0A1A0A] or ($image | bytes at 16..19 | into int --endian big) != 256 or ($image | bytes at 20..23 | into int --endian big) != 256 {
                error make {msg: $'Expected a 256x256 PNG: ($source.name)'}
            }
        }
    }

    print $'Validated ($sources | columns | length) notification icons'
}
