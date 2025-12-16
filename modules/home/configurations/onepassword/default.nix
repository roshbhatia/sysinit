{
  lib,
  osConfig ? { },
  pkgs,
  ...
}:
let
  hasNixOSSystem = osConfig ? system && osConfig.system ? stateVersion;
  isMacOS = !hasNixOSSystem;
  isLinux = hasNixOSSystem;
in
{
  home.packages =
    with pkgs;
    [
      _1password-cli
    ]
    ++ lib.optionals isMacOS [
      _1password
    ];

  # SSH configuration with 1Password agent on Linux
  programs.ssh = {
    enable = true;
    extraConfig = lib.mkIf isLinux ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };

  # Configure 1Password CLI for Linux
  home.shellAliases = lib.mkIf isLinux {
    op = "op";
  };

}
