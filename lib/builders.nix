{
  lib,
  nixpkgs,
  inputs,
}:

let
  pkgBuilders = import ./builders/pkgs.nix { inherit lib nixpkgs inputs; };
  darwinBuilder = import ./builders/darwin.nix { inherit lib inputs; };
  nixosBuilder = import ./builders/nixos.nix { inherit lib inputs; };
in
{
  inherit (pkgBuilders) mkPkgs mkUtils mkOverlays;

  buildConfiguration =
    {
      darwin,
      home-manager,
      stylix,
      onepassword-shell-plugins,
      mkPkgs,
      mkUtils,
      mkOverlays,
    }:
    {
      hostConfig,
      hostname,
    }:
    let
      overlays = mkOverlays hostConfig.system;
      pkgs = mkPkgs {
        inherit (hostConfig) system;
        inherit overlays;
      };
      utils = mkUtils {
        inherit (hostConfig) system;
        inherit pkgs;
      };
      # Merge username into values for backward compatibility with bridge code
      values = hostConfig.values // {
        user.username = hostConfig.username;
      };

      commonArgs = {
        inherit
          hostConfig
          hostname
          pkgs
          utils
          values
          ;
      };
    in
    if hostConfig.platform == "darwin" then
      darwinBuilder.buildDarwinSystem {
        inherit
          darwin
          home-manager
          stylix
          onepassword-shell-plugins
          ;
      } commonArgs
    else
      nixosBuilder.buildNixosSystem {
        inherit
          home-manager
          stylix
          ;
      } commonArgs;
}
