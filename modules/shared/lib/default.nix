{
  lib,
  pkgs,
  system,
  ...
}:

{

  modules = import ./modules { inherit lib; };
  packages = import ./packages.nix { inherit lib pkgs; };
  paths = import ./paths.nix { inherit lib; };
  platform = import ./platform.nix { inherit lib system; };
  lsp = import ./lsp-config.nix;
  shell = import ./shell.nix { inherit lib; };
  theme = import ./theme.nix { inherit lib; };
  schema = import ./schema.nix { inherit lib; };
}
