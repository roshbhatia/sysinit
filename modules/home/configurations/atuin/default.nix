{
  config,
  lib,
  values,
  ...
}:
with lib;
let
  cfg = config.programs.atuin;
  themes = import ../../../shared/lib/theme { inherit lib; };

  validatedTheme = themes.validateThemeConfig values.theme;
  theme = themes.getTheme validatedTheme.colorscheme;

  atuinAdapter = themes.adapters.atuin;
  atuinThemeConfig = atuinAdapter.createAtuinTheme theme validatedTheme;

  # Theme name for atuin
  themeName = atuinThemeConfig.atuinThemeName;
in
{
  config = mkIf cfg.enable {
    programs.atuin = {
      # These are enabled manually for zsh, but we let home-manager handle nushell
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

    # Generate atuin theme TOML from semantic colors
    xdg.configFile."atuin/themes/${themeName}.toml" = {
      text = atuinThemeConfig.atuinToml;
      force = true;
    };
  };
}
