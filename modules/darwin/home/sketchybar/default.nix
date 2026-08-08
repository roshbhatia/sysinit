{
  pkgs,
  config,
  lib,
  osConfig ? null,
  ...
}:

let
  c = config.lib.stylix.colors;
  themeConfig = config.sysinit.theme;

  # The workspace chips are declared, not discovered. aerospork materializes a
  # workspace only when it is first visited, so `list-workspaces --all` at bar
  # startup reports one name. Read the names back out of the bindings that create
  # them, so the bar and the window manager cannot disagree.
  mainBindings = lib.attrByPath [
    "services"
    "aerospork"
    "settings"
    "mode"
    "main"
    "binding"
  ] { } (if osConfig == null then { } else osConfig);
  workspaceNames = lib.sort (a: b: a < b) (
    lib.unique (
      lib.concatMap (
        v:
        lib.concatMap (
          cmd:
          let
            m = builtins.match "workspace ([^- ][^ ]*)" cmd;
          in
          if m == null then [ ] else m
        ) (lib.toList v)
      ) (lib.attrValues mainBindings)
    )
  );

  # Pass base16 colors and theme metadata to sketchybar Lua config
  sketchybarConfig = {
    inherit (themeConfig) base16Scheme;
    inherit (themeConfig) appearance;
    inherit (themeConfig) transparency;
    aerospork_bin = "${pkgs.aerospork}/bin/aerospork";
    workspaces = workspaceNames;
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
      inherit (themeConfig.font) monospace;
      inherit (themeConfig.font) symbols;
      inherit (themeConfig.font) size;
      inherit (themeConfig.font) icons;
      inherit (themeConfig.font) iconYOffset;
      inherit (themeConfig.font) labelYOffset;
      inherit (themeConfig.font) separatorYOffset;
      inherit (themeConfig.font) iconSize;
    };
  };
in
{
  xdg.configFile = {
    "sketchybar/sketchybarrc" = {
      text = ''
        #!${pkgs.lua5_5}/bin/lua

        local current_path = os.getenv("PATH") or ""
        local home_dir = os.getenv("HOME")
        if not home_dir then
          local username = os.getenv("USER")
          home_dir = "/Users/" .. username
        end

        package.cpath = package.cpath .. ";${pkgs.sbarlua}/lib/lua/5.5/?.so"
        package.cpath = package.cpath .. ";${pkgs.lua55Packages.cjson}/lib/lua/5.5/?.so"

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
