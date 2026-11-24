{
  pkgs,
  homeConfigurations,
  nuFunctions,
}:
let
  nativeCheck = import ../lib/native.nix { inherit pkgs; };
  shellConfig = pkgs.writeText "wezterm-check-config.nu" ''
    $env.config.shell_integration = ('${
      builtins.toJSON
        homeConfigurations.${
          "dev-" + pkgs.stdenv.hostPlatform.system
        }.config.programs.nushell.settings.shell_integration
    }' | from json)
    $env.config.show_banner = false
    use ${nuFunctions} *
  '';
in
nativeCheck {
  name = "nushell-wezterm";
  inputs = [ pkgs.python3 ];
  commands = [
    [
      "python3"
      ./nushell-wezterm.py
      shellConfig
    ]
  ];
}
