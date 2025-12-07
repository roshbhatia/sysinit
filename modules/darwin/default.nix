{ pkgs, config, ... }:
{
  imports = [
    ./configurations
    ./packages
    ../shared/lib/modules/validation.nix
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
