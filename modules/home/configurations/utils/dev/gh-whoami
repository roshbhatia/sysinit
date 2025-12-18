#!/usr/bin/env nu

def main [] {
    if (which gh | is-empty) {
        print "✗ GitHub CLI not installed"
        exit 1
    }

    let current_dir = (pwd)

    let [gh_config_dir, account_type] = if ($current_dir | str contains "$($env.HOME)/github/work") {
        [($env.HOME + "/.config/gh-work"), "work"]
    } else if ($current_dir | str contains "$($env.HOME)/github/personal") {
        [($env.HOME + "/.config/gh-personal"), "personal"]
    } else {
        [($env.HOME + "/.config/gh-personal"), "personal (default)"]
    }

    let result = (
        with-env { GH_CONFIG_DIR: $gh_config_dir } {
            gh api user --jq '.login' 2> /dev/null | complete
        }
    )

    if $result.exit_code == 0 {
        let username = $result.stdout | str trim
        print $"($username) ($account_type)"
    } else {
        print $"⚠ GitHub user not logged in for ($account_type) account" | ignore
        exit 1
    }
}
