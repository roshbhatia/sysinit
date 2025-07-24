{
  lib,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  atuinTheme = themes.getAppTheme "atuin" values.theme.colorscheme values.theme.variant;
in

{
  programs.atuin = {
    enable = true;
    # We need to do this manually due to zsh-vi-mode
    enableZshIntegration = false;
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
    };
  };

  # Conditionally include theme files based on current colorscheme
  xdg.configFile = lib.mkMerge [
    (lib.mkIf (values.theme.colorscheme == "catppuccin") {
      "atuin/themes/catppuccin-macchiato.toml" = {
        source = ./catppuccin-macchiato.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "rose-pine") {
      "atuin/themes/rose-pine-moon.toml" = {
        source = ./rose-pine-moon.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "gruvbox") {
      "atuin/themes/gruvbox-dark.toml" = {
        source = ./gruvbox-dark.toml;
        force = true;
      };
    })

    (lib.mkIf (values.theme.colorscheme == "solarized") {
      "atuin/themes/solarized-dark.toml" = {
        source = ./solarized-dark.toml;
        force = true;
      };
    })
  ];
}
