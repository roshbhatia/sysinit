{ lib }:
{

  mkHook =
    { pkgs, config }:
    lib.concatStringsSep " " [
      (lib.getExe pkgs.traces-tools.worklog)
      "--output"
      (lib.escapeShellArg config.sysinit.paths.resolved.agentWorklog)
      "--sessions-root"
      (lib.escapeShellArg config.sysinit.paths.resolved.seshySessions)
    ];
}
