# Darwin home desktop: hammerspoon, karabiner, sketchybar
{
  lib,
  pkgs,
  config,
  values,
  ...
}:

let
  themes = import ../../shared/lib/theme.nix { inherit lib; };
  themeConfig = values.theme // {
    presets = values.theme.presets or [ ];
    overrides = values.theme.overrides or { };
  };
in
{
  # === Hammerspoon ===
  home.file = {
    ".hammerspoon/init.lua".source = ./hammerspoon/init.lua;
    ".hammerspoon/lua".source = ./hammerspoon/lua;
    ".hammerspoon/Spoons/VimMode.spoon" = {
      source = pkgs.fetchFromGitHub {
        owner = "dbalatero";
        repo = "VimMode.spoon";
        rev = "dda997f79e240a2aebf1929ef7213a1e9db08e97";
        sha256 = "sha256-zpx2lh/QsmjP97CBsunYwJslFJOb0cr4ng8YemN5F0Y=";
      };
      recursive = true;
    };
  };

  # === Karabiner Elements ===
  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink ./karabiner/karabiner.json;

  # === Sketchybar ===
  xdg.configFile = {
    "sketchybar/sketchybarrc" = {
      text = ''
        #! /opt/homebrew/bin/lua

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
    "sketchybar/lua".source = ./sketchybar/lua;
    "sketchybar/config.json".text = builtins.toJSON (themes.generateAppJSON "sketchybar" themeConfig);
  };
}
