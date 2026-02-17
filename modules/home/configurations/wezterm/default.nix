{
  config,
  lib,
  ...
}:

let
  themes = import ../../../shared/lib/theme.nix { inherit lib; };
  themeNames = import ../../../shared/lib/theme/adapters/theme-names.nix { inherit lib; };
  themeName = themeNames.getWeztermTheme config.sysinit.theme.colorscheme config.sysinit.theme.variant;

  # Create a values-like structure for the theme library functions
  # This is needed because theme.nix library functions expect values.theme structure
  themeValues = {
    theme = config.sysinit.theme;
  };
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
    "wezterm/colors/kanso-ink.lua".source = ./colors/kanso-ink.lua;
    "wezterm/colors/kanso-mist.lua".source = ./colors/kanso-mist.lua;
  };
}
