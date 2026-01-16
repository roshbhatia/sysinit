# Darwin configuration entry point
{ pkgs, config, ... }:

{
  imports = [
    ./system.nix
    ./desktop.nix
    ./security.nix
    ./services.nix
    ./aerospace.nix
    ./sketchybar.nix
    ./stylix.nix
    ./packages.nix
    ./home-manager.nix
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
