{
  config,
  ...
}:
{
  xdg.configFile."sketchybar/init.lua".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar/init.lua";
  xdg.configFile."sketchybar/lua".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar/lua";
}
