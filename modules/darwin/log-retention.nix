{ config, pkgs, ... }:
let
  userHome = config.users.users.${config.sysinit.user.username}.home;
  policy =
    paths:
    pkgs.writeText "sysinit-logrotate.conf" ''
      ${paths} {
        size 10M
        rotate 3
        compress
        missingok
        notifempty
        copytruncate
      }
    '';
  userPolicy = policy ''
    /tmp/ollama.log /tmp/ollama.error.log
    /tmp/colima.log /tmp/colima.error.log
    /tmp/otel-collector.log /tmp/otel-collector.error.log
    /tmp/clamshell-thunderbolt.log /tmp/clamshell-thunderbolt.error.log
    /tmp/sketchybar-reload.log /tmp/sketchybar-reload.error.log
  '';
in
{
  launchd.user.agents.sysinit-logrotate.serviceConfig = {
    ProgramArguments = [
      "${pkgs.logrotate}/bin/logrotate"
      "--state"
      "${userHome}/Library/Logs/sysinit-logrotate.state"
      (toString userPolicy)
    ];
    RunAtLoad = true;
    StartInterval = 300;
  };
}
