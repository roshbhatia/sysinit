def main [path: path] {
    let deadline = (date now) + 20sec

    while not ($path | path exists) {
        if (date now) >= $deadline { error make {msg: $'timed out waiting for ($path)'} }

        sleep 10ms
    }
}
