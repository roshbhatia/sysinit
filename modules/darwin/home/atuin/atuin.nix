{
  ...
}:

{
  programs.atuin = {
    enable = true;
    # We need to do this manually due to zsh-vi-mode
    enableZshIntegration = false;
    settings = {
      filter_mode = "host";
      update_check = false;
      style = "compact";
      inline_height = 15;
      scroll_exits = false;
      show_preview = true;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
      keymap_mode = "vim-normal";
      theme = {
        name = "catppuccin-frappe-sky";
      };
    };
  };

  xdg.configFile."atuin/themes/catppuccin-frappe-sky.toml" = {
    source = ./catppuccin-frappe-sky.toml;
    force = true;
  };
}
