use ./lib/carapace.nu
use ./lib/process.nu [checked-command with-fixture]

const schema_check = path self opencode-schema.nu

def main [manifest: path] {
    let fixture = open $manifest

    checked-command $nu.current-exe --no-config-file $schema_check $fixture.schemas $fixture.main $fixture.tui | ignore

    with-fixture {|root|
        let plugins = $root | path join opencode
        let configuration = $root | path join .config

        mkdir ($plugins | path join plugins)
        cp $fixture.notify ($plugins | path join sysinit-notify.ts)
        cp $fixture.process ($plugins | path join sysinit-process.ts)
        cp $fixture.edits ($plugins | path join plugins sysinit-edits.ts)
        cp $fixture.probe ($root | path join opencode-plugins.test.js)

        checked-command ln -s ../sysinit-process.ts ($plugins | path join plugins sysinit-process.ts) | ignore
        carapace install $configuration $fixture.bridge {
            'opencode.yaml': $fixture.specification
            'opencode2.yaml': $fixture.alias
        }

        with-env {HOME: $root, XDG_CONFIG_HOME: $configuration, OPENCODE_PLUGIN_DIR: $plugins} {
            do {
                cd $root
                checked-command bun test ./opencode-plugins.test.js | print
            }

            for command in [opencode opencode2] {
                carapace check-completion $command [run --sta] '--standalone'
            }
        }
    }
}
