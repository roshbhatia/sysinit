use std/assert
use ./lib/carapace.nu
use ./lib/process.nu with-fixture

def main [
    bridge: path
    pueue: path
    tq: path
    executable: path
] {
    with-fixture {|root|
        let configuration = $root | path join .config

        carapace install $configuration $bridge {'pueue.yaml': $pueue, 'tq.yaml': $tq}

        with-env {HOME: $root, XDG_CONFIG_HOME: $configuration} {
            carapace check-completion pueue [add --sta] '--stashed'
            carapace check-completion tq [submit --ter] '--terminal'
        }

        assert ((^$executable) | str starts-with 'Usage: tq ')
    }
}
