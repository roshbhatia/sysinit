{
  ...
}:

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
        name = "catppuccin-frappe";
      };
    };
  };

  xdg.configFile."atuin/themes/catppuccin-frappe.toml" = {
    source = ./catppuccin-frappe.toml;
    force = true;
  };
}
