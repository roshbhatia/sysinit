use std/assert

def main [script: path, fixture: path] {
    let root = mktemp --directory --tmpdir-path /tmp | path expand --strict

    try {
        for tool in [vale fm] {
            let command = [
                'exec'
                ($nu.current-exe | to json --raw)
                '--no-config-file --stdin'
                ($fixture | to json --raw)
                $tool
                '"$@"'
            ] | str join ' '

            $"#!/bin/sh\n($command)\n" | save ($root | path join $tool)

            chmod +x ($root | path join $tool)
        }

        let text = 'Basically, use `never change 42` and [source](https://example.com).
```sh
echo "never change"
```
'

        let fixed = $text | str replace 'Basically, ' ''

        for mode in [
            clean
            unavailable
            timeout
            number
            negation
            token
            accepted
        ] {
            let calls = $root | path join calls

            rm --force $calls

            let result = with-env {
                PATH: ($env.PATH | prepend $root)
                REWRITE_MODE: $mode
                REWRITE_CALLS: $calls
            } {
                {text: $text} | to json --raw | ^$nu.current-exe --no-config-file --stdin $script --style fixture --fm ($root | path join fm) | complete
            }

            assert equal $result.exit_code 0 $result.stderr

            let output = $result.stdout | from json --strict

            match $mode {
                clean => {
                    assert equal $output {text: $text, status: clean}

                    assert (not ($calls | path exists))
                }
                unavailable => {
                    assert equal $output {text: $text, status: unavailable}

                    assert (not ($calls | path exists))
                }
                accepted => { assert equal $output {text: ($fixed | str replace --regex '^use ' 'Use '), status: fm} }
                _ => { assert equal $output {text: $fixed, status: deterministic-fallback} }
            }

            if ($calls | path exists) { assert equal (open --raw $calls) called }
        }

        let unicode = with-env {PATH: ($env.PATH | prepend $root), REWRITE_MODE: unicode} {
            {text: 'café Basically, use `42`.'} | to json --raw
                | ^$nu.current-exe --no-config-file --stdin $script --style fixture | complete
        }

        assert equal $unicode.exit_code 0 $unicode.stderr

        assert equal ($unicode.stdout | from json) {text: 'café use `42`.', status: deterministic}
    } catch {|failure|
        rm --recursive --force $root

        error make $failure
    }

    rm --recursive --force $root

    print 'Protected content, numeric/negation guards, clean bypass, unavailable fallback and actual FM timeout passed'
}
