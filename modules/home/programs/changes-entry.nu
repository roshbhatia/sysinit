def --wrapped main [program: string, ...args: string] {
    if ($args | is-empty) and (is-terminal --stdin) and (is-terminal --stdout) {
        exec $program interactive
    }

    exec $program ...$args
}
