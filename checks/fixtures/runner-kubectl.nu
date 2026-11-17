def --wrapped main [...arguments: string] {
    if $arguments.0 == get {
        if $arguments.2 == broken.example { exit 7 }
        if $arguments.2 == existing.example { print 'customresourcedefinition/existing.example' }
        return
    }
    let document = ^cat | from json
    (({arguments: $arguments, document: $document} | to json --raw) + "\n") | save --append $env.RUNNER_OPERATOR_LOG
    if $document.metadata.name == failing { exit 9 }
}
