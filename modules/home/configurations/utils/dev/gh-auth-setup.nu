!/usr/bin/env nu

def main [command?: string] {
    if (which gh | is-empty) {
        print "✗ GitHub CLI not installed"
        exit 1
    }

    def setup_account [account_type: string] {
        let gh_config_dir = $env.HOME + "/.config/gh-" + $account_type

        print $"Setting up ($account_type) GitHub account..."
        print $"Authenticating with config directory: ($gh_config_dir)"

        mkdir -p $gh_config_dir

        let result = (
            with-env { GH_CONFIG_DIR: $gh_config_dir } {
                gh auth login | complete
            }
        )

        if $result.exit_code == 0 {
            print $"✓ ($account_type) GitHub account authenticated successfully"

            let user_result = (
                with-env { GH_CONFIG_DIR: $gh_config_dir } {
                    gh api user --jq '.login' 2> /dev/null | complete
                }
            )

            if $user_result.exit_code == 0 {
                let username = ($user_result.stdout | str trim)
                print $"Authenticated as: ($username)"
            }
        } else {
            print $"✗ Failed to authenticate ($account_type) GitHub account"
            return 1
        }
    }

    def show_status [] {
        print "Checking authentication status..."

        for account_type in ["personal" "work"] {
            let gh_config_dir = $env.HOME + "/.config/gh-" + $account_type

            if ($gh_config_dir | path exists) {
                let user_result = (
                    with-env { GH_CONFIG_DIR: $gh_config_dir } {
                        gh api user --jq '.login' 2> /dev/null | complete
                    }
                )

                if $user_result.exit_code == 0 {
                    let username = ($user_result.stdout | str trim)
                    print $"✓ ($account_type): ($username)"
                } else {
                    print $"⚠ ($account_type): Not authenticated"
                }
            } else {
                print $"⚠ ($account_type): Config directory not found"
            }
        }
    }

    def print_usage [] {
        print "Usage: gh-auth-setup [command]

Commands:
  personal    Set up personal GitHub account authentication
  work        Set up work GitHub account authentication
  both        Set up both personal and work accounts
  status      Show authentication status for both accounts
  help        Show this help message

Examples:
  gh-auth-setup personal
  gh-auth-setup work
  gh-auth-setup both
  gh-auth-setup status"
    }

    match ($command | default "help") {
        "personal" => { setup_account "personal" }
        "work" => { setup_account "work" }
        "both" => {
            setup_account "personal"
            print ""
            setup_account "work"
        }
        "status" => { show_status }
        "help" | "--help" | "-h" => { print_usage }
        _ => {
            print $"✗ Unknown command: ($command)"
            print ""
            print_usage
            exit 1
        }
    }
}
