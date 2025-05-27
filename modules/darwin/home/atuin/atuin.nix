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

    themes = {
      "catppuccin-frappe-sky" = {
        theme = {
          name = "catppuccin-frappe-sky";
        };
        colors = {
          AlertInfo = "#a6d189";
          AlertWarn = "#ef9f76";
          AlertError = "#e78284";
          Annotation = "#99d1db";
          Base = "#c6d0f5";
          Guidance = "#949cbb";
          Important = "#e78284";
          Title = "#99d1db";
        };
      };
    };
  };
}
