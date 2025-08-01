{ lib, config, pkgs, values, ... }:

let
  inherit (config.sysinit) theme;
in
{
  programs.helix = {
    enable = true;
    settings = {
      theme = if theme.colorscheme == "catppuccin" then "catppuccin_macchiato"
        else if theme.colorscheme == "rose-pine" then "rose_pine"
        else if theme.colorscheme == "gruvbox" then "gruvbox"
        else if theme.colorscheme == "solarized" then "solarized_dark"
        else "catppuccin_macchiato";

      editor = {
        bufferline = "always";
        color-modes = true;
        completion-replace = true;
        cursor-word = true;
        cursorline = true;
        gutters = ["diagnostics" "line-numbers" "spacer" "diff"];
        idle-timeout = 1;
        line-number = "relative";
        popup-border = "all";
        rainbow-brackets = true;
        rulers = [100];
        scrolloff = 5;
        true-color = true;
        lsp.display-messages = true;
      };

      editor.file-picker = {
        git-global = true;
        git-ignore = true;
      };

      editor.statusline = {
        center = [];
        left = ["mode" "selections" "spinner" "file-name"];
        mode-separator = "";
        right = ["version-control" "workspace-diagnostics" "diagnostics" "file-encoding" "file-line-ending" "file-type" "position-percentage" "position" "spacer" "total-line-numbers"];
        separator = "";
      };

      editor.soft-wrap = {
        enable = true;
      };

      icons = "nerdfonts";
    };
  };
}

