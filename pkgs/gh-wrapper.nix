{
  pkgs,
  lib,
  personalGithubUser,
  workGithubUser,
}:

# Wrapper for gh that auto-switches GitHub accounts based on current directory
# before executing any gh command. This ensures all gh operations (including
# those from scripts/tools) use the correct account based on git config rules.

let
  gh-unwrapped = pkgs.gh;
  gh-path = lib.getExe gh-unwrapped;
in
pkgs.writeShellScriptBin "gh" ''
  # Determine which account to use based on current directory
  if [[ "$PWD" == "$HOME/github/work/"* ]]; then
    target_user="${workGithubUser}"
  elif [[ "$PWD" == "$HOME/github/personal/"* ]] || \
       [[ "$PWD" == "$HOME/orgfiles/"* ]] || \
       [[ "$PWD" == "$HOME/.local/share/"* ]]; then
    target_user="${personalGithubUser}"
  else
    # Not in a managed directory, skip switching
    exec ${gh-path} "$@"
  fi

  # Only switch if we're in a git repository and need a different account
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    current_user=$(${gh-path} auth status 2>&1 | grep "Logged in to github.com account" | grep "Active account: true" | awk '{print $6}')
    if [[ -n "$target_user" ]] && [[ "$current_user" != "$target_user" ]]; then
      ${gh-path} auth switch --user "$target_user" &>/dev/null
    fi
  fi

  # Execute the actual gh command with all arguments
  exec ${gh-path} "$@"
''
