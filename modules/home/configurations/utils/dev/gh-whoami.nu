#!/usr/bin/env nu

def main [] {
    if (which gh | is-empty) {
        print "✗ GitHub CLI not installed"
        exit 1
    }

    let current_dir = (pwd)

    let config = if ($current_dir | str contains ($env.HOME | path join "github" "work")) {
        {gh_config_dir: ($env.HOME | path join ".config" "gh-work"), account_type: "work"}
    } else if ($current_dir | str contains ($env.HOME | path join "github" "personal")) {
        {gh_config_dir: ($env.HOME | path join ".config" "gh-personal"), account_type: "personal"}
    } else {
        {gh_config_dir: ($env.HOME | path join ".config" "gh-personal"), account_type: "personal (default)"}
    }

    let result = (
        with-env { GH_CONFIG_DIR: $config.gh_config_dir } {
            gh api user --jq '.login' err> /dev/null | complete
        }
    )

    if $result.exit_code == 0 {
        let username = $result.stdout | str trim
        print $"($username) ($config.account_type)"
    } else {
        print $"⚠ GitHub user not logged in for ($config.account_type) account" | ignore
        exit 1
    }
}
