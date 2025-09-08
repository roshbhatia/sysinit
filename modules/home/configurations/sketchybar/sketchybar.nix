{
  config,
  pkgs,
  ...
}:
let
  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
  path = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar";
in
{
  xdg.configFile."sketchybar/init.lua".text = ''
    #!${pkgs.lua}/bin/lua
    package.path = package.path .. ";${pkgs.lua}/share/lua/5.4/?.lua"
    package.cpath = package.cpath .. ";${pkgs.lua}/lib/lua/5.4/?.so"
    require("init")
  '';
  xdg.configFile."sketchybar/main.lua".source = mkOutOfStoreSymlink "${path}/init.lua";
  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
}
