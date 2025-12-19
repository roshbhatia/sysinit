# Cobra CLI completion support for kubectl, gh, and other cobra-based tools

export def cobra_completer [spans: list<string>] {
    let ShellCompDirectiveError = 1
    let ShellCompDirectiveNoSpace = 2
    let ShellCompDirectiveNoFileComp = 4
    let ShellCompDirectiveFilterFileExt = 8
    let ShellCompDirectiveFilterDirs = 16
    let ShellCompDirectiveKeepOrder = 32

    let cmd = $spans | first 
    let rest = $spans | skip

    def cobra_log [message: string] {
        let file = do -i { $env | get NUSHELL_COMP_DEBUG_FILE }
        if $file != null {
            $"($message)\n" | save $file --append
        }
    }

    cobra_log $"External Completer called for cmd ($cmd)"

    def exec_complete [spans: list<string>] {
        let result = do --ignore-errors { 
            COBRA_ACTIVE_HELP=0 run-external $cmd "__complete" ...$spans | complete 
        }

        if $result != null and $result.exit_code == 0 {
            let completions = $result.stdout | lines

            let directive = do -i { 
                $completions | last | str replace ':' '' | into int 
            }

            let completions = $completions | drop | each { |it| 
                let words = $it | split row -r '\s{1}'

                let last_span = $spans | last
                let words = if ($last_span =~ '^-') and ($last_span =~ '=$') {
                    $words | each {|it| $"($last_span)($it)" }
                } else {
                    $words
                }

                {
                    value: ($words | first | str trim)
                    description: ($words | skip | str join ' ')
                }
            }

            { completions: $completions, directive: $directive }
        } else {
            { completions: [], directive: -1 }
        }
    }

    if (not ($rest | is-empty)) {
        let result = exec_complete $rest
        let completions = $result.completions
        let directive = $result.directive

        let completions = if $directive != $ShellCompDirectiveNoSpace {
            $completions | each {|it| 
                { value: $"($it.value) ", description: $it.description }
            }
        } else {
            $completions
        }

        let completions = if $directive == $ShellCompDirectiveFilterFileExt {
            []
        } else {
            $completions
        }

        if $directive == $ShellCompDirectiveNoFileComp {
            $completions
        } else if ($completions | is-empty) or $directive == $ShellCompDirectiveError {
            null
        } else {
            $completions
        }
    } else {
        null
    }
}
