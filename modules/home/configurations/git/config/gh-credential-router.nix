{
  values,
  pkgs,
  ...
}:

let
  personalGithubUser =
    if values.git.personalUsername != null then values.git.personalUsername else values.git.username;
  workGithubUser =
    if values.git.workUsername != null then values.git.workUsername else values.git.username;

  # Script to route credentials based on repository location
  ghCredentialRouter = pkgs.writeShellScriptBin "gh-credential-router" ''
    #!/usr/bin/env bash

    # Get the current directory
    CURRENT_DIR="$(pwd)"

    # Determine which gh config to use based on the path
    if [[ "$CURRENT_DIR" == "$HOME/github/work"* ]]; then
      GH_CONFIG_DIR="$HOME/.config/gh-work"
      EXPECTED_USER="${workGithubUser}"
    elif [[ "$CURRENT_DIR" == "$HOME/github/personal"* ]]; then
      GH_CONFIG_DIR="$HOME/.config/gh-personal"
      EXPECTED_USER="${personalGithubUser}"
    else
      # Default to personal for repositories outside these paths
      GH_CONFIG_DIR="$HOME/.config/gh-personal"
      EXPECTED_USER="${personalGithubUser}"
    fi

    # Export the config directory for gh to use
    export GH_CONFIG_DIR

    # Call gh auth git-credential with the appropriate config
    exec ${pkgs.gh}/bin/gh auth git-credential "$@"
  '';
in
{
  home.packages = [ ghCredentialRouter ];
}
