{ pkgs, config, ... }:
{
  imports = [
    ./configurations
    ./packages
    ../lib/nixos-modules/validation.nix
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
