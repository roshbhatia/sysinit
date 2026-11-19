use std/assert

def --wrapped main [...arguments: string] {
    assert equal $arguments.0 '--profile'

    assert equal $arguments.2 '--delete-generations'

    let profile = $arguments.1

    let profiles = $profile | path dirname

    ^ln -s $env.RACE_NEW_TARGET ($profiles | path join system-4-link)

    ^ln -sfn system-4-link $profile

    for generation in ($arguments | skip 3) {
        rm ($profiles | path join $'system-($generation)-link')
    }
}
