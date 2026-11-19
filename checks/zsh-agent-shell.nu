use std/assert

def run-case [
    zsh: path
    fragment: path
    case: record
    command: string
] {
    let flags = if $case.interactive { '-fic' } else { '-fc' }

    ^timeout 10s $zsh $flags ('source "$1"; ' + $command) sysinit-check $fragment | complete
}

def main [zsh: path, fragment: path] {
    let root = mktemp -d

    let cases = [
        {
            name: plain
            variables: {}
            compatible: false
            interactive: false
        }
        {
            name: codex
            variables: {CODEX_THREAD_ID: sysinit-check}
            compatible: true
            interactive: false
        }
        {
            name: claude
            variables: {CLAUDECODE: '1'}
            compatible: true
            interactive: false
        }
        {
            name: opt-in
            variables: {SYSINIT_AGENT_SHELL: '1'}
            compatible: true
            interactive: false
        }
        {
            name: opt-out
            variables: {SYSINIT_AGENT_SHELL: '0'}
            compatible: false
            interactive: false
        }
        {
            name: interactive
            variables: {CODEX_THREAD_ID: sysinit-check}
            compatible: false
            interactive: true
        }
    ]

    try {
        with-env {} {
            hide-env --ignore-errors CLAUDECODE CODEX_THREAD_ID SYSINIT_AGENT_SHELL
            cd $root
            for case in $cases {
                with-env $case.variables {
                    let split = run-case $zsh $fragment $case 'value="one two"; set -- $value; print -r -- "$#"'
                    assert equal $split.exit_code 0 $split.stderr
                    assert equal ($split.stdout | str trim) (if $case.compatible { '2' } else { '1' }) $case.name
                    let quoted = run-case $zsh $fragment $case 'value="one two"; set -- "$value"; print -r -- "$#"'
                    assert equal $quoted.exit_code 0 $quoted.stderr
                    assert equal ($quoted.stdout | str trim) '1' $case.name
                    let equals = run-case $zsh $fragment $case 'print -r -- =zsh'
                    assert equal $equals.exit_code 0 $equals.stderr
                    if $case.compatible {
                        assert equal ($equals.stdout | str trim) '=zsh' $case.name
                    } else {
                        assert ($equals.stdout | str trim | str starts-with '/') $case.name
                    }
                    let glob = run-case $zsh $fragment $case 'print -r -- __sysinit_missing_*.pattern'
                    if $case.interactive {
                        assert ($glob.exit_code != 0) $case.name
                    } else {
                        assert equal $glob.exit_code 0 $glob.stderr
                        assert equal ($glob.stdout | str trim) '__sysinit_missing_*.pattern' $case.name
                    }
                }
            }
        }
    } catch {|failure|
        rm -rf $root

        error make $failure
    }

    rm -rf $root

    print 'Zsh agent-shell behavior passed for all six contexts'
}
