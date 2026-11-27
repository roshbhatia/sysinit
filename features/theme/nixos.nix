{ pkgs, ... }:

{
  imports = [
    ./options.nix
    ./stylix.nix
  ];

  stylix.image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
}
