{
  config,
  ...
}:
{
  home.file.".sketchybar/init.lua".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar/init.lua";
  home.file.".sketchybar/lua".source =
    "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar/lua";
}
