{
  pkgs,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  systems = [
    darwinConfigurations.lv426.config
    nixosConfigurations.arrakis.config
  ];
  followsProfile =
    system:
    let
      home = system.home-manager.users.${system.sysinit.user.username};
      command = builtins.head home.programs.sysinit-wezterm.settings.shell;
    in
    lib.hasPrefix "${home.home.profileDirectory}/bin/" command;
in
assert lib.assertMsg (builtins.all followsProfile systems)
  "Persistent WezTerm muxes must resolve the current shell through the user profile";
pkgs.runCommand "wezterm-shell" { } ''touch "$out"''
