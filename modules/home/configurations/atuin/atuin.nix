{
  lib,
  overlay,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  atuinTheme = themes.getAppTheme "atuin" overlay.theme.colorscheme overlay.theme.variant;
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
    (lib.mkIf (overlay.theme.colorscheme == "catppuccin") {
      "atuin/themes/catppuccin-frappe.toml" = {
        source = ./catppuccin-frappe.toml;
        force = true;
      };
      "atuin/themes/catppuccin-latte.toml" = {
        source = ./catppuccin-latte.toml;
        force = true;
      };
      "atuin/themes/catppuccin-macchiato.toml" = {
        source = ./catppuccin-macchiato.toml;
        force = true;
      };
      "atuin/themes/catppuccin-mocha.toml" = {
        source = ./catppuccin-mocha.toml;
        force = true;
      };
    })
    
    (lib.mkIf (overlay.theme.colorscheme == "rose-pine") {
      "atuin/themes/rose-pine.toml" = {
        source = ./rose-pine.toml;
        force = true;
      };
      "atuin/themes/rose-pine-moon.toml" = {
        source = ./rose-pine-moon.toml;
        force = true;
      };
      "atuin/themes/rose-pine-dawn.toml" = {
        source = ./rose-pine-dawn.toml;
        force = true;
      };
    })
    
    (lib.mkIf (overlay.theme.colorscheme == "gruvbox") {
      "atuin/themes/gruvbox-dark.toml" = {
        source = ./gruvbox-dark.toml;
        force = true;
      };
      "atuin/themes/gruvbox-light.toml" = {
        source = ./gruvbox-light.toml;
        force = true;
      };
    })
  ];
}
