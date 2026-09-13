{ pkgs, ... }:

{
  imports = [ ../../shared/stylix.nix ];

  stylix.image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
}
