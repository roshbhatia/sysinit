{
  lib,
  osConfig ? { },
  pkgs,
  ...
}:

let
  # Detect platform based on osConfig presence
  # Darwin uses nix-darwin which doesn't set osConfig.system in the same way
  hasNixOSSystem = osConfig ? system && osConfig.system ? stateVersion;
  isMacOS = !hasNixOSSystem;
  isLinux = hasNixOSSystem;
in
{
  # 1Password CLI package
  home.packages =
    with pkgs;
    [
      _1password-cli
    ]
    ++ lib.optionals isMacOS [
      _1password
    ];

  # Configure 1Password shell plugins using the home-manager module
  # This automatically integrates 1Password shell plugins for bash, zsh, and fish
  programs._1password-shell-plugins = {
    enable = true;
    # Specify which tools should use 1Password shell plugins
    plugins = with pkgs; [
      gh
      awscli2
    ];
  };

  # SSH agent configuration for 1Password
  # On macOS, 1Password Desktop handles SSH agent
  # On Linux, we need to configure SSH to use 1Password agent socket
  programs.ssh.extraConfig = lib.mkIf isLinux ''
    # 1Password SSH agent socket (if using 1Password for Linux)
    # IdentityAgent ~/.1password/agent.sock
  '';
}
