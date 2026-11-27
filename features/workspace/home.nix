{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = lib.mkIf config.sysinit.llm.workspace.enable [ pkgs.agent-workspace ];
}
