# lv426 - Primary personal macOS workstation
{ ... }:

{
  imports = [
    ./base/darwin.nix
  ];

  # Host-specific homebrew casks
  homebrew.casks = [
    "betterdiscord-installer"
    "discord"
    "ghostty"
    "steam"
  ];
}
