use std/assert

def main [script: path, fixture: path] {
    let root = mktemp --directory
    try {
        let command = $root | path join kubectl
        ($'#!($nu.current-exe) --no-config-file' + "\n" + (open --raw $fixture)) | save $command
        ^chmod 700 $command
        let manifest = $root | path join operator.yaml
        let log = $root | path join operations.jsonl
        '' | save $log
        let documents = [
            {
                kind: CustomResourceDefinition
                metadata: {name: existing.example}
            }
            {
                kind: CustomResourceDefinition
                metadata: {name: new.example}
            }
            {
                kind: Deployment
                metadata: {name: operator}
            }
        ]
        ($documents | each { to yaml } | str join "---\n") | save $manifest
        with-env {PATH: ($env.PATH | prepend $root), RUNNER_OPERATOR_LOG: $log} {
            let result = ^$nu.current-exe --no-config-file $script $manifest | complete
            assert equal $result.exit_code 0 $result.stderr
            let operations = open --raw $log | lines | each { from json }
            assert equal $operations.arguments [[create -f -] [apply --server-side -f -]]
            assert equal $operations.document ($documents | skip 1)
            {kind: Deployment, metadata: {name: failing}} | to yaml | save --force $manifest
            let failed = ^$nu.current-exe --no-config-file $script $manifest | complete
            assert equal $failed.exit_code 9
            let before = open --raw $log
            {kind: CustomResourceDefinition, metadata: {name: broken.example}} | to yaml | save --force $manifest
            let lookup = ^$nu.current-exe --no-config-file $script $manifest | complete
            assert ($lookup.exit_code != 0)
            assert equal (open --raw $log) $before
            '' | save --force $manifest
            let empty = ^$nu.current-exe --no-config-file $script $manifest | complete
            assert equal $empty.exit_code 0 $empty.stderr
            assert equal (open --raw $log) $before
        }
    } catch {|failure|
        rm --recursive --force $root
        error make $failure
    }
    rm --recursive --force $root
    print 'Runner operator checks passed'
}
