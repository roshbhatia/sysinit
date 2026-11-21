{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.sysinit.rex.enable = lib.mkEnableOption "Rex terminal and its local key bindings";

  config = lib.mkIf config.sysinit.rex.enable {
    home.packages = [ pkgs.rex ];
    sysinit.codesign.protectRunningApps = [ "Rex" ];
    xdg.configFile."rex/init.lua".source = ./init.lua;
  };
}
