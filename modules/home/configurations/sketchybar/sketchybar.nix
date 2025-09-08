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
  xdg.configFile."sketchybar/init.lua".text =
    let
      lua = pkgs.lua54Packages.lua.withPackages (_ps: [ pkgs.sbarLua ]);
      realConfig = "${path}/init.lua";
    in
    ''
      #!${lua}/bin/lua
      package.path = package.path .. ";${lua}/share/lua/5.4/?.lua"
      package.cpath = package.cpath .. ";${lua}/lib/lua/5.4/?.so"
      dofile("${realConfig}")
    '';
  xdg.configFile."sketchybar/main.lua".source = mkOutOfStoreSymlink "${path}/init.lua";
  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";
}
