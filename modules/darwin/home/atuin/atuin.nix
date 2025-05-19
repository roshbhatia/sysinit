{ ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      update_check = false;
      style = "full";
      inline_height = 15;
      show_preview = true;
      show_help = false;
      show_tabs = false;
      enter_accept = true;
    };
  };
}

