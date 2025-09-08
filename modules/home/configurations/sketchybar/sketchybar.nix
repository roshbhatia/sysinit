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
  xdg.configFile."sketchybar/sketchybarrc" = {
    text = ''
      #!${pkgs.lua}/bin/lua

      package.cpath = package.cpath .. ";${pkgs.sbarlua}/lib/lua/5.4/?.so"
      package.path = package.path .. ";${config.xdg.configHome}/sketchybar/lua/?.lua;${config.xdg.configHome}/sketchybar/lua/?/init.lua"

      require("init")
    '';
    executable = true;
  };

  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
  xdg.configFile."sketchybar/theme_config.json".source =
    mkOutOfStoreSymlink "${path}/theme_config.json";
}
