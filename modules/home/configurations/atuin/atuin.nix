{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/theme { inherit lib; };
  atuinTheme = themes.getAppTheme "atuin" values.theme.colorscheme values.theme.variant;
in

{
  programs.atuin = {
    enable = true;

    enableZshIntegration = false;

    enableNushellIntegration = false;

    settings = {
      update_check = false;
      inline_height = 15;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      invert = true;
      keymap_mode = "vim-normal";
      show_preview = false;
      style = "compact";
      theme = {
        name = atuinTheme;
      };

      history_filter = [
        "with-env .*atuin search.*"
      ];
    };
  };

  xdg.configFile = lib.mkMerge [
    (lib.mkIf (values.theme.colorscheme == "catppuccin") {
      "atuin/themes/catppuccin-macchiato.toml" = {
        source = ./themes/catppuccin-macchiato.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "rose-pine") {
      "atuin/themes/rose-pine-moon.toml" = {
        source = ./themes/rose-pine-moon.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "gruvbox") {
      "atuin/themes/gruvbox-dark.toml" = {
        source = ./themes/gruvbox-dark.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "solarized") {
      "atuin/themes/solarized-dark.toml" = {
        source = ./themes/solarized-dark.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "nord") {
      "atuin/themes/nord-dark.toml" = {
        source = ./themes/nord-dark.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "kanagawa") {
      "atuin/themes/kanagawa-wave.toml" = {
        source = ./themes/kanagawa-wave.toml;
        force = true;
      };
      "atuin/themes/kanagawa-dragon.toml" = {
        source = ./themes/kanagawa-dragon.toml;
        force = true;
      };
    })
  ];
}
