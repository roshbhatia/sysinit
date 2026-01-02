{
  lib,
  values,
  pkgs,
  ...
}:

let
  bordersEnabled = values.darwin.borders.enable;
in
lib.mkIf bordersEnabled {
  services.jankyborders = {
    enable = true;
    package = pkgs.jankyborders;
    width = 4.0;
  };
}
