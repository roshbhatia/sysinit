{
  pkgs,
  config,
  values,
  ...
}:

let
  colors = config.lib.stylix.colors;

  semanticColors = {
    background = {
      primary = "#${colors.base00}";
      secondary = "#${colors.base01}";
      tertiary = "#${colors.base02}";
      overlay = "#${colors.base01}";
    };
    foreground = {
      primary = "#${colors.base05}";
      secondary = "#${colors.base04}";
      muted = "#${colors.base03}";
      subtle = "#${colors.base03}";
    };
    accent = {
      primary = "#${colors.base0D}";
      secondary = "#${colors.base0C}";
      tertiary = "#${colors.base0E}";
      dim = "#${colors.base02}";
    };
    semantic = {
      error = "#${colors.base08}";
      warning = "#${colors.base0A}";
      success = "#${colors.base0B}";
      info = "#${colors.base0D}";
    };
    syntax = {
      keyword = "#${colors.base0E}";
      string = "#${colors.base0B}";
      number = "#${colors.base09}";
      comment = "#${colors.base03}";
      function = "#${colors.base0D}";
      variable = "#${colors.base08}";
      type = "#${colors.base0A}";
      operator = "#${colors.base05}";
      constant = "#${colors.base09}";
      builtin = "#${colors.base0C}";
    };
  };

  themeConfig = {
    colorscheme = values.theme.colorscheme;
    variant = values.theme.variant;
    appearance = values.theme.appearance;
    transparency = values.theme.transparency;
    # Provide base16 palette directly for more direct access
    base16 = {
      base00 = "#${colors.base00}";
      base01 = "#${colors.base01}";
      base02 = "#${colors.base02}";
      base03 = "#${colors.base03}";
      base04 = "#${colors.base04}";
      base05 = "#${colors.base05}";
      base06 = "#${colors.base06}";
      base07 = "#${colors.base07}";
      base08 = "#${colors.base08}";
      base09 = "#${colors.base09}";
      base0A = "#${colors.base0A}";
      base0B = "#${colors.base0B}";
      base0C = "#${colors.base0C}";
      base0D = "#${colors.base0D}";
      base0E = "#${colors.base0E}";
      base0F = "#${colors.base0F}";
    };
    semanticColors = semanticColors;
    font = {
      monospace = values.theme.font.monospace;
      symbols = values.theme.font.symbols or "Symbols Nerd Font";
    };
  };
in
{
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

  xdg.configFile."karabiner/karabiner.json".source =
    config.lib.file.mkOutOfStoreSymlink ./karabiner/karabiner.json;

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
    "sketchybar/config.json".text = builtins.toJSON themeConfig;
  };
}
