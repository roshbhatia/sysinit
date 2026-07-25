{
  lib,
  ...
}:

{

  paths = import ./paths.nix { inherit lib; };
  shell = import ./shell.nix { inherit lib; };
}
