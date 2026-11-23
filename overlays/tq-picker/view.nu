def main [id: string, mode: string] {
    if $id !~ '^\d+$' {
        print --stderr 'pueue-task-view: expected a numeric task ID'

        exit 2
    }

    let prompt = $"Pueue #($id) | j/k scroll | g/G top/end | q quit"

    match $mode {
        stdin => { exec less -R -P $prompt +G }
        log => {
            ^pueue log --lines 1000 $id | ^less -R -P $prompt +G
        }
        follow => {
            let follow_prompt = $"Pueue #($id) | Ctrl-C pause | j/k scroll | F follow | q quit"

            ^pueue follow --lines 1000 $id | ^less -R -P $follow_prompt +F
        }
        _ => {
            print --stderr 'pueue-task-view: invalid log mode'

            exit 2
        }
    }
}
