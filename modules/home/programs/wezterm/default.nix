{
  config,
  lib,
  ...
}:

let
  themes = import ../../../lib/theme.nix { inherit lib; };
  themeNames = import ../../../lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme config.sysinit.theme.colorscheme config.sysinit.theme.variant;

  # Create a values-like structure for the theme library functions
  # This is needed because theme.nix library functions expect values.theme structure
  themeValues = {
    inherit (config.sysinit) theme;
  };

  paths = import ../../../lib/paths.nix { inherit lib; };
in
{
  # Disable stylix for wezterm - using custom theme integration from shared/lib/theme.nix
  stylix.targets.wezterm.enable = false;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  xdg.configFile = {
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "wezterm/lua".source = ./lua;
    "wezterm/config.json".text = themes.toJsonFile (
      themes.makeThemeJsonConfig themeValues {
        color_scheme = themeName;
      }
    );
    "wezterm/env.json".text = builtins.toJSON {
      PATH = paths.getPathString config.home.username config.home.homeDirectory;
    };

    # Explicitly generate the classic-platinum scheme for Wezterm to find
    "wezterm/colors/classic-platinum-light.lua".text = ''
      return {
        foreground = "#000000",
        background = "#cccccc",
        cursor_bg = "#000000",
        cursor_fg = "#cccccc",
        cursor_border = "#000000",
        selection_fg = "#ffffff",
        selection_bg = "#000080",
        scrollbar_thumb = "#999999",
        split = "#666666",
        ansi = {
          "#000000", "#800000", "#008000", "#808000",
          "#000080", "#800080", "#008080", "#cccccc"
        },
        brights = {
          "#666666", "#ff0000", "#00ff00", "#ffff00",
          "#0000ff", "#ff00ff", "#00ffff", "#ffffff"
        },
        indexed = {
          [16] = "#ff8000",
          [17] = "#804000"
        }
      }
    '';
  };
}
