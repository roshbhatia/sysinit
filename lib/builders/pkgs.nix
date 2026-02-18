{
  lib,
  nixpkgs,
  inputs,
}:

{
  mkPkgs =
    {
      system,
      overlays ? [ ],
    }:
    import nixpkgs {
      inherit system overlays;
      config = {
        allowUnfree = true;
        allowUnsupportedSystem = true;
        allowUnfreePredicate =
          pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "_1password-gui"
          ];
      };
    };

  mkUtils = { system, pkgs }: import ../../modules/lib { inherit lib pkgs system; };

  mkOverlays = _system: import ../../overlays/default.nix { inherit inputs; };
}
