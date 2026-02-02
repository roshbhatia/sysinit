{ pkgs, config, ... }:

{
  imports = [
    # Packages first, then configurations
    ./packages
    ./configurations
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
