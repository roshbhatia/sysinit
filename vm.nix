{
  pkgs ? import <nixpkgs> { },
}:

let
  # Import VM library from local repo
  vmLib = import ./lib/vm-shell.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  # Import existing shell.nix if it exists for merging buildInputs
  baseShell = if builtins.pathExists ./shell.nix then import ./shell.nix { inherit pkgs; } else null;

in
vmLib.mkVmShell {
  inherit baseShell;
  # projectName and vmName auto-derived from directory
  # All other params use sensible defaults (4 CPUs, 8GiB memory/disk, port range)
}
