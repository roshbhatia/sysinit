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
  xdg.configFile."sketchybar/sketchybarrc".text = ''
    #!${pkgs.lua}/bin/lua

    local home_dir = "${config.home.homeDirectory}"

    package.path = package.path .. ";${pkgs.lua}/share/lua/5.4/?.lua"
    package.cpath = package.cpath .. ";${pkgs.lua}/lib/lua/5.4/?.so"

    package.path = package.path
      .. ";"
      .. home_dir
      .. "/.config/sketchybar/lua/?.lua"
      .. ";"
      .. home_dir
      .. "/.config/sketchybar/lua/?/init.lua"

    require("sysinit.pkg.theme")
    require("sysinit.pkg.core").setup()
    require("sysinit.pkg.items.workspaces").setup()
    require("sysinit.pkg.items.front_app").setup()
    require("sysinit.pkg.items.system").setup()
  '';

  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
}
