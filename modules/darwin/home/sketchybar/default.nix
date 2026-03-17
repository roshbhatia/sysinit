{
  pkgs,
  config,
  ...
}:

let
  c = config.lib.stylix.colors;
  themeConfig = config.sysinit.theme;

  # Pass base16 colors and theme metadata to sketchybar Lua config
  sketchybarConfig = {
    base16Scheme = themeConfig.base16Scheme;
    appearance = themeConfig.appearance;
    transparency = themeConfig.transparency;
    base16 = {
      base00 = "#${c.base00}";
      base01 = "#${c.base01}";
      base02 = "#${c.base02}";
      base03 = "#${c.base03}";
      base04 = "#${c.base04}";
      base05 = "#${c.base05}";
      base06 = "#${c.base06}";
      base07 = "#${c.base07}";
      base08 = "#${c.base08}";
      base09 = "#${c.base09}";
      base0A = "#${c.base0A}";
      base0B = "#${c.base0B}";
      base0C = "#${c.base0C}";
      base0D = "#${c.base0D}";
      base0E = "#${c.base0E}";
      base0F = "#${c.base0F}";
    };
    font = {
      monospace = themeConfig.font.monospace;
      symbols = themeConfig.font.symbols;
    };
  };
in
{
  xdg.configFile = {
    "sketchybar/sketchybarrc" = {
      text = ''
        #!${pkgs.lua5_4}/bin/lua

        local current_path = os.getenv("PATH") or ""
        local home_dir = os.getenv("HOME")
        if not home_dir then
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
      executable = true;
    };
    "sketchybar/lua".source = ./lua;
    "sketchybar/config.json".text = builtins.toJSON sketchybarConfig;
  };
}
