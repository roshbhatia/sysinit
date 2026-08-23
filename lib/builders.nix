{
  lib,
  nixpkgs,
  inputs,
}:

let
  pkgBuilders = import ./builders/pkgs.nix { inherit lib nixpkgs inputs; };
  darwinBuilder = import ./builders/darwin.nix { inherit lib inputs; };
  nixosBuilder = import ./builders/nixos.nix { inherit lib inputs; };
  homeBuilder = import ./builders/home.nix { inherit lib inputs; };
in
{
  inherit (pkgBuilders) mkPkgs mkOverlays;
  inherit (homeBuilder) mkHome;

  buildConfiguration =
    {
      darwin,
      home-manager,
      stylix,
      onepassword-shell-plugins,
      nix-gaming ? null,
      mkPkgs,
      mkOverlays,
    }:
    {
      hostConfig,
      hostname,
    }:
    let
      pkgs = mkPkgs {
        inherit (hostConfig) system;
        overlays = mkOverlays;
      };
      values = (hostConfig.values or { }) // {
        inherit hostname;
        user.username = hostConfig.username;
        isDesktop = hostConfig.desktop or false;
      };

      profile = hostConfig.profile or "workstation";

      theme = hostConfig.theme or true;

      commonArgs = {
        inherit
          hostConfig
          hostname
          pkgs
          profile
          theme
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
          nix-gaming
          ;
      } commonArgs;
}
