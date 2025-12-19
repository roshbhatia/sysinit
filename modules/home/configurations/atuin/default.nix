{
  lib,
  values,
  ...
}:

let
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  atuinAdapter = themes.adapters.atuin;
  atuinThemeConfig = atuinAdapter.createAtuinTheme theme validatedTheme;

  themeName = atuinThemeConfig.atuinThemeName;
in
{
  programs.atuin = {
    enable = true;
    enableZshIntegration = false;
    enableNushellIntegration = true;

    settings = {
      update_check = false;
      inline_height = 15;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      invert = true;
      keymap_mode = "vim-normal";
      show_preview = true;
      style = "compact";
      theme = {
        name = themeName;
      };

      history_filter = [
        "with-env .*atuin search.*"
      ];
    };
  };

  xdg.configFile."atuin/themes/${themeName}.toml" = {
    text = atuinThemeConfig.atuinToml;
    force = true;
  };
}
