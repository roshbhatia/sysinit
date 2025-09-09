{
  config,
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    transparency = values.theme.transparency;
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };

  mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
  path = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/sketchybar";
in

{
  xdg.configFile."sketchybar/sketchybarrc" = {
    text = ''
      #! /opt/homebrew/bin/lua

      local current_path = os.getenv("PATH") or ""

      local username = os.getenv("USER")
      local home_dir = "/Users/" .. username

      package.cpath = package.cpath .. ";${pkgs.sbarlua}/lib/lua/5.4/?.so"
      package.cpath = package.cpath .. ";${pkgs.luajitPackages.cjson}/lib/lua/5.1/?.so"

      package.path = package.path
        .. ";"
        .. home_dir
        .. "/.config/sketchybar/lua/?.lua"
        .. ";"
        .. home_dir
        .. "/.config/sketchybar/lua/?/init.lua"

      require("sysinit")
    '';
    executable = true;
  };

  xdg.configFile."sketchybar/lua".source = mkOutOfStoreSymlink "${path}/lua";

  xdg.configFile."sketchybar/theme_config.json".text = builtins.toJSON (
    themes.generateAppJSON "sketchybar" themeConfig
  );
}
