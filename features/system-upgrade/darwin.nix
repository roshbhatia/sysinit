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

  system.activationScripts.postActivation.text = lib.mkIf config.services.comin.enable (
    lib.mkAfter ''
      # nix-darwin's startup service reads the system profile; Comin switches its own profile.
      cominProfile=/nix/var/nix/profiles/system-profiles/comin
      systemProfile=${lib.escapeShellArg config.system.profile}
      if [ -L "$cominProfile" ] && [ "$(readlink -f "$cominProfile")" = "$systemConfig" ] &&
        [ "$(readlink -f "$systemProfile")" != "$systemConfig" ]; then
        nix-env --profile "$systemProfile" --set "$systemConfig"
      fi
    ''
  );

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
