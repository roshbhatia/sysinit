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
      style = "full";
      inline_height = 15;
      show_preview = true;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      keymap_mode = "vim-normal";
      theme = "catppuccin-frappe-sky";
    };
  };

  xdg.configFile."atuin/themes/catppuccin-frappe-sky.toml" = {
    source = ./catppuccin-frappe-sky.toml;
    force = true;
  };
}
