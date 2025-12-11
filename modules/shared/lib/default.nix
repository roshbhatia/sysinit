{
  lib,
  pkgs,
  system,
  ...
}:

{
  packages = import ./packages { inherit lib pkgs system; };
  paths = import ./paths { inherit lib; };
  platform = import ./platform { inherit lib system; };
  shell = import ./shell { inherit lib; };
  theme = import ./theme { inherit lib; };
  values = import ./values { inherit lib; };
  xdg = import ./xdg { inherit lib pkgs; };
}
