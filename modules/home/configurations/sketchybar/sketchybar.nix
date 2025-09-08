{ config, ... }:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink or builtins.mkOutOfStoreSymlink;
  path = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar";
in
{
  xdg.configFile."sketchybar/sketchybarrc".source = mkOutOfStoreSymlink "${path}/sketchybarrc";
  xdg.configFile."sketchybar/init.lua".source = mkOutOfStoreSymlink "${path}/init.lua";
  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
}
