{
  lib,
  values,
  ...
}:

let
  bordersEnabled = values.darwin.borders.enable;
in
lib.mkIf bordersEnabled {
  services.jankyborders = {
    enable = true;
    width = 4.0;
  };
}
