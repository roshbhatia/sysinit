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
          builtins.elem (lib.getName pkg) [
            "_1password-gui"
            "antigravity-cli"
            "meat"
          ];
        allowInsecurePredicate = pkg: lib.hasPrefix "electron" (lib.getName pkg);
      };
    };

  mkUtils = { system, pkgs }: import ../../modules/lib { inherit lib pkgs system; };

  mkOverlays = _system: import ../../overlays/default.nix { inherit inputs; };
}
