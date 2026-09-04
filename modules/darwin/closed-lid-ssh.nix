{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.sysinit.darwin.closedLidSsh;
  marker = "/var/db/sysinit/closed-lid-ssh-enabled";
  monitor = pkgs.writeShellScript "sysinit-closed-lid-ssh" (builtins.readFile ./closed-lid-ssh.sh);
in
{
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      launchd.daemons.sysinit-closed-lid-ssh = {
        serviceConfig = {
          ProgramArguments = [
            "${monitor}"
            "/usr/bin/pmset"
            "/usr/bin/logger"
            "/bin/sleep"
            "5"
            marker
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Background";
          EnvironmentVariables.PATH = "/usr/bin:/bin:/usr/sbin:/sbin";
          StandardOutPath = "/var/log/sysinit-closed-lid-ssh.log";
          StandardErrorPath = "/var/log/sysinit-closed-lid-ssh.error.log";
        };
      };
    })

    {
      assertions = lib.optional cfg.enable {
        assertion = config.sysinit.darwin.openssh.enable;
        message = "sysinit.darwin.closedLidSsh requires sysinit.darwin.openssh";
      };

      system.activationScripts.postActivation.text = lib.optionalString (!cfg.enable) ''
        if [ -e ${lib.escapeShellArg marker} ]; then
          /usr/bin/pmset -a disablesleep 0
          /bin/rm -f ${lib.escapeShellArg marker}
          /usr/bin/logger -t sysinit-closed-lid-ssh "system sleep enabled after configuration change"
        fi
      '';
    }
  ];
}
