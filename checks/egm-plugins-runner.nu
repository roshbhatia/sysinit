use lib/process.nu checked-command

def main [
    output: path
    bundle: path
    skill: path
    config: path
    probe: path
] {
    mkdir $output

    for entry in [
        {source: $bundle, name: bundle}
        {source: $skill, name: claude}
        {source: $config, name: config.toml}
    ] {
        ^ln -s $entry.source ($output | path join $entry.name)
    }

    checked-command $nu.current-exe --no-config-file $probe $output | print
}
