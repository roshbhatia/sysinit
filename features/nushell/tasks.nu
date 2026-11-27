# Read queue attempts and their live Pueue status without writing to queue state.
export def queue [--state: path]: nothing -> list<record> {
    let args = if $state == null { [] } else { [--state $state] }

    ^task-queue ...$args snapshot | from json
}

# Read the same projection that feeds the interactive Taskwarrior board.
export def --wrapped board [...args: string]: nothing -> record {
    ^task-board --json ...$args | from json
}
