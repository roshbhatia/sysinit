{
  inputs,
  config,
  hostname,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    inputs.comin.darwinModules.comin
    ./common.nix
  ];

  services.comin.hostname = lib.mkDefault hostname;

  launchd.daemons.comin.serviceConfig.EnvironmentVariables =
    lib.mkIf (config.services.comin.enable && !config.nix.enable)
      (
        lib.mkForce {
          PATH = "/nix/var/nix/profiles/default/bin:${
            lib.makeBinPath [
              pkgs.git
              pkgs.openssh
            ]
          }:/usr/bin:/bin:/usr/sbin:/sbin";
        }
      );
}
