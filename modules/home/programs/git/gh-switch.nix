{
  config,
  lib,
  ...
}:

let
  cfg = config.sysinit.git;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;
in
{
  # Zsh: Use chpwd hook to auto-switch on directory change
  programs.zsh.initExtra = lib.mkAfter ''
    # Auto-switch GitHub account based on directory
    _gh_auto_switch() {
      local pwd_path="$PWD"
      
      # Check if we're in a git repository first
      if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        return 0
      fi

      # Determine which account to use based on directory
      if [[ "$pwd_path" == "$HOME/github/work/"* ]]; then
        local current_user=$(gh auth status 2>&1 | grep "Logged in to github.com account" | grep "Active account: true" | awk '{print $6}')
        if [[ "$current_user" != "${workGithubUser}" ]]; then
          gh auth switch --user "${workGithubUser}" &>/dev/null && \
            echo "Switched to work GitHub account: ${workGithubUser}"
        fi
      elif [[ "$pwd_path" == "$HOME/github/personal/"* ]] || \
           [[ "$pwd_path" == "$HOME/orgfiles/"* ]] || \
           [[ "$pwd_path" == "$HOME/.local/share/"* ]]; then
        local current_user=$(gh auth status 2>&1 | grep "Logged in to github.com account" | grep "Active account: true" | awk '{print $6}')
        if [[ "$current_user" != "${personalGithubUser}" ]]; then
          gh auth switch --user "${personalGithubUser}" &>/dev/null && \
            echo "Switched to personal GitHub account: ${personalGithubUser}"
        fi
      fi
    }

    # Manual switch function
    gh-switch() {
      local account="''${1:-}"
      if [ -z "$account" ]; then
        echo "Usage: gh-switch {personal|work}"
        echo "  personal: ${personalGithubUser}"
        echo "  work: ${workGithubUser}"
        echo ""
        echo "Current active account:"
        gh auth status 2>&1 | grep "Active account: true" -B1 | head -1 || echo "  (none)"
        return 1
      fi

      if [ "$account" = "personal" ]; then
        gh auth switch --user "${personalGithubUser}" 2>/dev/null && \
          echo "Switched to personal account: ${personalGithubUser}" || \
          echo "Failed to switch. Ensure you're logged in: gh auth login"
      elif [ "$account" = "work" ]; then
        gh auth switch --user "${workGithubUser}" 2>/dev/null && \
          echo "Switched to work account: ${workGithubUser}" || \
          echo "Failed to switch. Ensure you're logged in: gh auth login"
      else
        echo "Unknown account: $account"
        echo "Usage: gh-switch {personal|work}"
        return 1
      fi
    }

    # Add to chpwd hook
    autoload -U add-zsh-hook
    add-zsh-hook chpwd _gh_auto_switch

    # Run on shell startup
    _gh_auto_switch
  '';

  # Fish: Use PWD variable watch to auto-switch on directory change
  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Auto-switch GitHub account based on directory
    function _gh_auto_switch --on-variable PWD
      # Check if we're in a git repository first
      if not git rev-parse --is-inside-work-tree &>/dev/null
        return 0
      end

      set -l pwd_path $PWD

      # Determine which account to use based on directory
      if string match -q "$HOME/github/work/*" $pwd_path
        set -l current_user (gh auth status 2>&1 | grep "Logged in to github.com account" | grep "Active account: true" | awk '{print $6}')
        if test "$current_user" != "${workGithubUser}"
          if gh auth switch --user "${workGithubUser}" &>/dev/null
            echo "Switched to work GitHub account: ${workGithubUser}"
          end
        end
      else if string match -q "$HOME/github/personal/*" $pwd_path; \
              or string match -q "$HOME/orgfiles/*" $pwd_path; \
              or string match -q "$HOME/.local/share/*" $pwd_path
        set -l current_user (gh auth status 2>&1 | grep "Logged in to github.com account" | grep "Active account: true" | awk '{print $6}')
        if test "$current_user" != "${personalGithubUser}"
          if gh auth switch --user "${personalGithubUser}" &>/dev/null
            echo "Switched to personal GitHub account: ${personalGithubUser}"
          end
        end
      end
    end

    # Manual switch function
    function gh-switch
      set -l account $argv[1]
      if test -z "$account"
        echo "Usage: gh-switch {personal|work}"
        echo "  personal: ${personalGithubUser}"
        echo "  work: ${workGithubUser}"
        echo ""
        echo "Current active account:"
        gh auth status 2>&1 | grep "Active account: true" -B1 | head -1; or echo "  (none)"
        return 1
      end

      if test "$account" = "personal"
        if gh auth switch --user "${personalGithubUser}" 2>/dev/null
          echo "Switched to personal account: ${personalGithubUser}"
        else
          echo "Failed to switch. Ensure you're logged in: gh auth login"
        end
      else if test "$account" = "work"
        if gh auth switch --user "${workGithubUser}" 2>/dev/null
          echo "Switched to work account: ${workGithubUser}"
        else
          echo "Failed to switch. Ensure you're logged in: gh auth login"
        end
      else
        echo "Unknown account: $account"
        echo "Usage: gh-switch {personal|work}"
        return 1
      end
    end

    # Run on shell startup
    _gh_auto_switch
  '';

  # Nushell: Use hooks.env_change.PWD to auto-switch on directory change
  programs.nushell.extraConfig = lib.mkAfter ''
    # Auto-switch GitHub account based on directory
    def _gh_auto_switch [] {
      # Check if we're in a git repository first
      let is_git = (do -i { git rev-parse --is-inside-work-tree } | complete | get exit_code) == 0
      if not $is_git {
        return
      }

      let pwd_path = $env.PWD

      # Determine which account to use based on directory
      if ($pwd_path | str starts-with $"($env.HOME)/github/work/") {
        let current_user = (gh auth status | complete | get stdout | lines | where { |line| $line =~ "Active account: true" } | get 0? | default "" | parse "{account} account {user}" | get user.0? | default "")
        if $current_user != "${workGithubUser}" {
          do -i { gh auth switch --user "${workGithubUser}" }
          if $env.LAST_EXIT_CODE == 0 {
            print $"Switched to work GitHub account: ${workGithubUser}"
          }
        }
      } else if (
        ($pwd_path | str starts-with $"($env.HOME)/github/personal/") or
        ($pwd_path | str starts-with $"($env.HOME)/orgfiles/") or
        ($pwd_path | str starts-with $"($env.HOME)/.local/share/")
      ) {
        let current_user = (gh auth status | complete | get stdout | lines | where { |line| $line =~ "Active account: true" } | get 0? | default "" | parse "{account} account {user}" | get user.0? | default "")
        if $current_user != "${personalGithubUser}" {
          do -i { gh auth switch --user "${personalGithubUser}" }
          if $env.LAST_EXIT_CODE == 0 {
            print $"Switched to personal GitHub account: ${personalGithubUser}"
          }
        }
      }
    }

    # Manual switch function
    def "gh-switch" [account?: string] {
      if ($account == null) {
        print "Usage: gh-switch {personal|work}"
        print $"  personal: ${personalGithubUser}"
        print $"  work: ${workGithubUser}"
        print ""
        print "Current active account:"
        let current = (gh auth status | complete | get stdout | lines | where { |line| $line =~ "Active account: true" } | get 0? | default "  (none)")
        print $current
        return
      }

      if ($account == "personal") {
        do -i { gh auth switch --user "${personalGithubUser}" }
        if $env.LAST_EXIT_CODE == 0 {
          print $"Switched to personal account: ${personalGithubUser}"
        } else {
          print "Failed to switch. Ensure you're logged in: gh auth login"
        }
      } else if ($account == "work") {
        do -i { gh auth switch --user "${workGithubUser}" }
        if $env.LAST_EXIT_CODE == 0 {
          print $"Switched to work account: ${workGithubUser}"
        } else {
          print "Failed to switch. Ensure you're logged in: gh auth login"
        }
      } else {
        print $"Unknown account: ($account)"
        print "Usage: gh-switch {personal|work}"
      }
    }

    # Add to PWD change hook
    $env.config.hooks.env_change = ($env.config.hooks.env_change | default {})
    $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | default [])
    $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {|before, after| _gh_auto_switch })

    # Run on shell startup
    _gh_auto_switch
  '';
}
