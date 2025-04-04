{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    autosuggestion.enable = true;

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
      
      # Help command
      "sysinit-help" = "$HOME/.config/sysinit/sysinit-help.sh";
    };
    
    plugins = [
      {
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "v1.0.2"; # Use the latest stable release
          sha256 = "sha256-qzpnGTrLnq5mNaLlsjSA6VESA88XBdN3Ku/YIgLCb28=";
        };
        file = "evalcache.plugin.zsh";
      }
    ];

    # This is akin to our normal .zshrc
    initExtra = ''
      source $HOME/.config/zsh/base.sh
    '';
  };
  
  xdg.configFile = {
    # Core files
    "zsh/base.sh".source = ./base.sh;
    "zsh/paths.sh".source = ./paths.sh;
    "zsh/loglib.sh".source = ./loglib.sh;
    "zsh/completions.sh".source = ./completions.sh;
    "zsh/fzf.sh".source = ./fzf.sh;
    "zsh/notifications.sh".source = ./notifications.sh;
    "zsh/homebrew.sh".source = ./homebrew.sh;
    "zsh/style.sh".source = ./style.sh;
    "zsh/shift-select.sh".source = ./shift-select.sh;

    # Make loglib available in extras directory too
    "zsh/extras/loglib.sh".source = ./loglib.sh;
    "zsh/extras/kubectl-aliases.sh".source = ./kubectl-aliases.sh;

    # Custom kubectl commands
    "zsh/extras/bin/kubectl-kdesc".source = ./kubectl-kdesc.sh;
    "zsh/extras/bin/kubectl-kexec".source = ./kubectl-kexec.sh;
    "zsh/extras/bin/kubectl-klog".source = ./kubectl-klog.sh;
    "zsh/extras/bin/kubectl-kproxy".source = ./kubectl-kproxy.sh;

    # Other extras
    "zsh/extras/crepo.sh".source = ./crepo.sh;
    "zsh/extras/github.sh".source = ./github.sh;
    "zsh/extras/devenv.sh".source = ./devenv.sh;
    "zsh/extras/zshutils.zsh".source = ./zshutils.zsh;
    "zsh/extras/bin/crdbrowse".source = ./crdbrowse.sh;
  };
}