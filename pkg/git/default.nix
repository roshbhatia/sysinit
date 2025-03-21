{ config, lib, pkgs, ... }:

{
  # Git configuration
  programs.git = {
    enable = true;
    userName = lib.mkDefault "Rosh Bhatia";
    userEmail = lib.mkDefault "roshbhatia@github.com";
    
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      fetch.prune = true;
    };
    
    aliases = {
      co = "checkout";
      br = "branch";
      st = "status";
      c = "commit";
      ca = "commit --amend";
      cane = "commit --amend --no-edit";
      unstage = "reset HEAD --";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      last = "log -1 HEAD";
    };
  };
}
