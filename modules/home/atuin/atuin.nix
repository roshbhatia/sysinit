{ config, lib, pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      update_check = false;
      style = "compact";
      inline_height = 13;
      show_preview = false;
      show_help = false;
      show_tabs = false;
      enter_accept = false;
    };
  };
}