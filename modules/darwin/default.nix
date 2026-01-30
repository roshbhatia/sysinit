# Darwin configuration entry point
{ pkgs, config, ... }:

{
  imports = [
    ./configurations
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
