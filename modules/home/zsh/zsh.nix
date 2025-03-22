{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    historySubstringSearch.enable = true;
    
    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };
    
    shellAliases = {
      l = "eza --icons=always -1";
      ll = "eza --icons=always -1 -a";
      lt = "eza --icons=always -1 -a -T";
      ".." = "cd ..";
      "..." = "cd ../..";
      "~" = "cd ~";
      
      tf = "terraform";
      y = "yazi";
      
      kubectl = "kubecolor";
      k = "kubectl";
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
    
    initExtraFirst = ''
      # Ensure config directories exist
      mkdir -p $HOME/.config/zsh/extras
    '';
    
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
    
    # Make loglib available in extras directory too
    "zsh/extras/loglib.sh".source = ./loglib.sh;
    
    # Other extras
    "zsh/extras/kfzf.sh".source = ./kfzf.sh;
    "zsh/extras/kfwd.sh".source = ./kfwd.sh;
    "zsh/extras/kellog.sh".source = ./kellog.sh;
    "zsh/extras/crepo.sh".source = ./crepo.sh;
    "zsh/extras/github.sh".source = ./github.sh;
    "zsh/extras/devenv.sh".source = ./devenv.sh;
    "zsh/extras/zshutils.zsh".source = ./zshutils.zsh;
  };
}