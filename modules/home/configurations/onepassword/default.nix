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

  programs.ssh = {
    enable = true;
    extraConfig = lib.mkIf isLinux ''
      IdentityAgent ~/.1password/agent.sock
    '';
  };

}
