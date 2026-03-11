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

  paths = import ../../../modules/lib/paths.nix { inherit lib; };
in
{
  # Disable stylix for wezterm - using custom theme integration from shared/lib/theme.nix
  stylix.targets.wezterm.enable = false;

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
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
  };
}
