use std/assert
use ./lib/carapace.nu
use ./lib/process.nu with-fixture

def main [
    bridge: path
    pueue: path
    queue: path
    executable: path
] {
    with-fixture {|root|
        let configuration = $root | path join .config

        carapace install $configuration $bridge {'pueue.yaml': $pueue, 'task-queue.yaml': $queue}

        with-env {HOME: $root, XDG_CONFIG_HOME: $configuration} {
            carapace check-completion pueue [add --sta] '--stashed'
            carapace check-completion task-queue [submit --ter] '--terminal'
        }

        assert (ls -l $executable | first | get mode | str contains x)
    }
}
