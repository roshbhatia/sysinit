{ pkgs, config, ... }:
{
  imports = [
    ./configurations
    ./packages
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
