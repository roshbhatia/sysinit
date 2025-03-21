{ config, lib, pkgs, ... }:

{
  # Zsh configuration
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    enableAutosuggestions = true;
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
      ls = "ls --color=auto";
      ll = "ls -la";
      l = "ls -l";
      grep = "grep --color=auto";
      cp = "cp -i";
      mv = "mv -i";
      rm = "rm -i";
      c = "clear";
      k = "kubectl";
      dc = "docker-compose";
      tf = "terraform";
      reload = "source ~/.zshrc";
      cat = "bat";
      du = "dust";
      # Git aliases
      g = "git";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gpl = "git pull";
      gco = "git checkout";
      # Directory navigation
      ... = "cd ../..";
      .... = "cd ../../..";
      ..... = "cd ../../../..";
    };
    
    initExtra = ''
      # FZF integration
      export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
      
      # Disable ctrl+s to freeze terminal
      stty stop undef
      
      # Custom functions
      function mkcd() {
        mkdir -p "$1" && cd "$1";
      }
      
      # For atuin integration
      eval "$(atuin init zsh --disable-up-arrow)"
    '';
  };
}
