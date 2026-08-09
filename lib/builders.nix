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
  inherit (pkgBuilders) mkPkgs mkOverlays;

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
      overlays = mkOverlays hostConfig.system;
      pkgs = mkPkgs {
        inherit (hostConfig) system;
        inherit overlays;
      };
      values = (hostConfig.values or { }) // {
        inherit hostname;
        user.username = hostConfig.username;
        isDesktop = hostConfig.desktop or false;
      };

      # What the host is for, in one word. A specialArg rather than an option,
      # because `imports` lists read it and `imports` is resolved before
      # `config` exists. `modules/shared/options/profiles.nix` has the whole
      # reason.
      profile = hostConfig.profile or "workstation";

      # Whether stylix computes this host's palette. A specialArg for the same
      # reason `profile` is one: the stylix target overrides are a whole module
      # that is imported or not, and `imports` cannot read `config`.
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
