{
  lib,
  values,
  pkgs,
  ...
}:
{
  imports = [
    (import ./sketchybar.nix {
      inherit lib values pkgs;
    })
  ];
}

