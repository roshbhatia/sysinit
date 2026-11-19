def main --wrapped [tool: string, ...arguments: string] {
    let text = $in

    if $tool == vale {
        if $env.REWRITE_MODE == unavailable { exit 2 }

        let alerts = if $env.REWRITE_MODE == clean or ($text | str starts-with 'Use ') {
            []
        } else if $env.REWRITE_MODE == unicode {
            [
                {
                    Line: 1
                    Span: [6 16]
                    Match: 'Basically, '
                    Action: {Name: remove}
                }
            ]
        } else {
            [
                {
                    Line: 1
                    Span: [1 11]
                    Match: 'Basically, '
                    Action: {Name: remove}
                }
            ]
        }

        {stdin: $alerts} | to json --raw | print
    } else {
        'called' | save --append $env.REWRITE_CALLS

        match $env.REWRITE_MODE {
            timeout => { sleep 10sec }
            number => {
                $text | str replace 42 43 | print
            }
            negation => {
                $text | str replace 'never ' '' | print
            }
            token => {
                $text | str replace SYSINIT_KEEP_0_END missing | print
            }
            _ => {
                $text | str replace --regex '^use ' 'Use ' | print
            }
        }
    }
}
