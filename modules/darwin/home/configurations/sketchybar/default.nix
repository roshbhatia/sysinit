{
  lib,
  values,
  pkgs,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };

  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };
in

{
  xdg.configFile = {
    "sketchybar/sketchybarrc".text = ''
      #! /opt/homebrew/bin/lua

      local current_path = os.getenv("PATH") or ""

      -- Use HOME environment variable for platform-agnostic home directory
      local home_dir = os.getenv("HOME")
      if not home_dir then
        -- Fallback for systems without HOME set
        local username = os.getenv("USER")
        home_dir = "/Users/" .. username
      end

      package.cpath = package.cpath .. ";${pkgs.sbarlua}/lib/lua/5.4/?.so"
      package.cpath = package.cpath .. ";${pkgs.lua54Packages.cjson}/lib/lua/5.4/?.so"

      package.path = package.path
        .. ";"
        .. home_dir
        .. "/.config/sketchybar/lua/?.lua"
        .. ";"
        .. home_dir
        .. "/.config/sketchybar/lua/?/init.lua"

      require("sysinit")
    '';

    "sketchybar/sketchybarrc".executable = true;

    "sketchybar/lua".source = ./lua;

    "sketchybar/theme_config.json".text = builtins.toJSON (
      themes.generateAppJSON "sketchybar" themeConfig
    );
  };
}
