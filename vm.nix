{
  pkgs ? import <nixpkgs> { },
}:

let
  # Import VM library from local repo
  vmLib = import ./lib/vm-shell.nix {
    inherit pkgs;
    inherit (pkgs) lib;
  };

  projectName = baseNameOf (toString ./.);
  vmName = "${projectName}-dev";

  # Import existing shell.nix if it exists
  baseShell =
    if builtins.pathExists ./shell.nix then import ./shell.nix { inherit pkgs; } else pkgs.mkShell { };

in
pkgs.mkShell {
  name = "${projectName}-vm-shell";

  # Merge buildInputs from existing shell.nix if present
  buildInputs =
    (baseShell.buildInputs or [ ])
    ++ (with pkgs; [
      # VM management dependencies
      lima
      jq
    ]);

  shellHook = vmLib.autoEnterShellHook {
    inherit vmName projectName;
    projectDir = "$(pwd)";
    image = "lima-dev";
    cpus = 4;
    memory = "8GiB";
    verbose = true;
  };
}
