{
  pkgs ? import <nixpkgs> { },
}:

let
  vmLib = import ./lib/vm-shell.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  baseShell = if builtins.pathExists ./shell.nix then import ./shell.nix { inherit pkgs; } else null;
in
vmLib.mkVmShell {
  inherit baseShell;
}
