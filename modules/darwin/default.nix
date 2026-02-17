{ pkgs, config, ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../shared/lib/modules/user.nix
    ../shared/lib/modules/darwin.nix
    ../shared/lib/modules/theme.nix
    ../home/configurations/git/options.nix
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
