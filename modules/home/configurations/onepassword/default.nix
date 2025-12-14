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

  # Initialize 1Password shell plugins
  programs.bash.initExtra = ''
    # 1Password shell integration
    if command -v op &> /dev/null; then
      eval "$(op shell-plugins init --shell bash 2>/dev/null)" || true
    fi
  '';

  programs.zsh.initExtra = ''
    # 1Password shell integration
    if command -v op &> /dev/null; then
      eval "$(op shell-plugins init --shell zsh 2>/dev/null)" || true
    fi
  '';

  # SSH agent configuration for 1Password
  # On macOS, 1Password Desktop handles SSH agent
  # On Linux, we need to configure SSH to use 1Password agent socket
  programs.ssh.extraConfig = lib.mkIf isLinux ''
    # 1Password SSH agent socket (if using 1Password for Linux)
    # IdentityAgent ~/.1password/agent.sock
  '';
}
