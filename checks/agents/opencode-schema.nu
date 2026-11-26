use std/assert

def main [schemas: path, main_config: path, cli_config: path] {
    for case in [
        {name: config, path: $main_config}
        {name: cli, path: $cli_config}
    ] {
        let schema = $schemas | path join ($case.name + '.json')

        let valid = ^jsonschema-cli validate --offline --no-assert-format $schema --instance $case.path | complete

        assert equal $valid.exit_code 0 ($valid.stdout + $valid.stderr)

        let invalid = $env.TMPDIR | path join ($case.name + '-unknown-key.json')

        open $case.path | upsert sysinit_unknown_key true | to json | save --force $invalid

        let rejected = ^jsonschema-cli validate --offline --no-assert-format $schema --instance $invalid | complete

        assert ($rejected.exit_code != 0) $'($case.name) schema accepted an unknown root key'
    }

    print 'OpenCode configuration schemas accept managed settings and reject unknown root keys'
}
