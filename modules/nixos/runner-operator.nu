def main [manifest: path] {
    let parsed = open --raw $manifest | from yaml
    if $parsed == null { return }
    let documents = if ($parsed | describe | str starts-with record) { [$parsed] } else { $parsed }
    for document in (
        $documents
        | where {|document| $document != null and not ($document | is-empty)}
    ) {
        let arguments = if $document.kind == CustomResourceDefinition {
            let existing = ^kubectl get crd $document.metadata.name --ignore-not-found -o name | complete
            if $existing.exit_code != 0 { error make {msg: $existing.stderr} }
            if ($existing.stdout | str trim) != '' { continue }
            [create -f -]
        } else {
            [apply --server-side -f -]
        }
        let applied = $document | to json | ^kubectl ...$arguments | complete
        print --no-newline $applied.stdout
        print --stderr --no-newline $applied.stderr
        if $applied.exit_code != 0 { exit $applied.exit_code }
    }
}
