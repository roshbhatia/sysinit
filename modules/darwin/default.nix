{ pkgs, config, ... }:

{
  imports = [
    # Packages first, then configurations
    ./packages
    ./configurations
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "olm-3.2.16"
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
