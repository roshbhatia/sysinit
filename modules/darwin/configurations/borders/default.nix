{
  lib,
  values,
  pkgs,
  ...
}:

let
  bordersEnabled = values.darwin.borders.enable or true;
in
lib.mkIf bordersEnabled {
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;
    style = "round";
    width = 2.0;
    hidpi = true;
  };
}
