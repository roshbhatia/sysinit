use std/assert

def main [path: path] {
    let manifest = open $path

    for harness in $manifest.harnesses {
        let source = open --raw $harness.source

        let text = if ($harness.key | is-empty) {
            $source
        } else {
            $harness.key | reduce --fold ($source | from json) {|key, value| $value | get $key}
        }

        let expected = open --raw $harness.expected

        assert equal ($text | split row $expected | length) 2 $harness.name

        if $harness.style != null {
            let style = open --raw $harness.style

            assert equal ($style | split row $manifest.outputStyle | length) 2 $harness.name
        }

        print $'($harness.name): generated instructions match shared sources'
    }
}
