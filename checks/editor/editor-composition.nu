use std/assert
use ../lib/process.nu [checked-command with-fixture]

def main [languages: path, configuration: path] {
    with-fixture {|root|
        let config_home = $root | path join .config
        let helix = $config_home | path join helix

        mkdir $helix
        cp $languages ($helix | path join languages.toml)
        cp $configuration ($helix | path join config.toml)

        with-env {HOME: $root, XDG_CONFIG_HOME: $config_home} {
            for language in [nix python go dockerfile markdown hcl tfvars] {
                let health = checked-command hx --health $language

                print $health
                assert (not ($health | str contains 'not found in')) $'Helix is missing support for ($language)'
            }
        }
    }
}
