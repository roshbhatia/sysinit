{
  lib,
  system,
  ...
}:

{

  paths = import ./paths.nix { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  shell = import ./shell.nix { inherit lib; };
  theme = import ./theme.nix { inherit lib; };
}
