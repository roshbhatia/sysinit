{
  lib,
  values,
  ...
}:

let
  themes = import ../../../../shared/lib/theme { inherit lib; };
  theme = themes.getTheme values.theme.colorscheme;
  palette = theme.palettes.${values.theme.variant};
in

{
  # Wezterm retroism color scheme configuration
  # This extends the existing wezterm config with retroism colors
  
  home.file.".config/wezterm/retroism-colors.toml" = {
    text = ''
      [colors]
      foreground = "${palette.fg0}"
      background = "${palette.bg0}"
      
      ansi = [
        "${palette.bg3}",
        "${palette.red}",
        "${palette.green}",
        "${palette.yellow}",
        "${palette.blue}",
        "${palette.purple}",
        "${palette.cyan}",
        "${palette.fg3}",
      ]
      
      brights = [
        "${palette.gray}",
        "${palette.red}",
        "${palette.green}",
        "${palette.yellow}",
        "${palette.blue}",
        "${palette.purple}",
        "${palette.cyan}",
        "${palette.fg0}",
      ]
      
      [colors.cursor_bg]
      # bright phosphor color matching terminal
      [colors.cursor_fg]
      # inverse of background
    '';
  };

  # TODO: Integrate into wezterm config.lua via mkOutOfStoreSymlink
  # Add to wezterm config: include(wezterm.config_dir .. '/retroism-colors.toml')
}
