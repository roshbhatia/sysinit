{ lib }:
{
  # The command a SessionEnd hook runs to append one worklog line. Both
  # harnesses that record one run this, so the file and the sessions root are
  # named here once, from the paths layout, and the tool stays neutral about
  # where this machine keeps either.
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
