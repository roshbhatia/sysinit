{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    historySubstringSearch.enable = true;
    autosuggestion.enable = true;

    # We instead use fast-syntax-highlighting
    syntaxHighlighting.enable = false;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
    
    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";
      
      code = "code-insiders";
      kubectl = "kubecolor";

      l = "eza --icons=always -1";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T";

      tf = "terraform";
      y = "yazi";

      vim = "nvim";
      vi = "nvim";
      
      # Help command
      "sysinit-help" = "$HOME/.config/sysinit/sysinit-help.sh";
    };
    
    plugins = [
      {
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "v1.0.2";
          sha256 = "sha256-qzpnGTrLnq5mNaLlsjSA6VESA88XBdN3Ku/YIgLCb28=";
        };
        file = "evalcache.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e0";
          sha256 = "sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4=";
        };
        file = "fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initExtra = ''
      source $HOME/.config/zsh/base.sh
    '';
  };
  
  xdg.configFile = {
    # Core files
    "zsh/base.sh".source = ./base.sh;

    "zsh/completions.sh".source = ./completions.sh;
    "zsh/fzf.sh".source = ./fzf.sh;
    "zsh/loglib.sh".source = ./loglib.sh;
    "zsh/notifications.sh".source = ./notifications.sh;
    "zsh/paths.sh".source = ./paths.sh;
    "zsh/shift-select.sh".source = ./shift-select.sh;
    "zsh/style.sh".source = ./style.sh;
    "zsh/zshutils.sh".source = ./zshutils.sh;


    "zsh/extras".source = ./extras;
  };
}