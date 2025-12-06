{ pkgs, config, ... }:
{
  imports = [
    ./configurations
    ./packages
    ../shared/lib/nixos-modules/validation.nix
  ];

  # macOS applications directory - platform-specific
  # /Applications is the standard macOS applications directory
  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
