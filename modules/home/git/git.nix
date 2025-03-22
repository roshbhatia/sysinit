{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = lib.mkDefault "Roshan Bhatia";
    userEmail = lib.mkDefault "rshnbhatia@gmail.com";
    
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "code --wait";
      core.excludesFile = "~/.gitignore.global";
      credential.helper = "store";
      credential.username = "roshbhatia";
      github.user = "roshbhatia";
    };
    
    includes = [
      {
        condition = "gitdir:~/github/";
        path = "~/.gitconfig.work";
      }
      {
        condition = "gitdir:~/github/roshbhatia/";
        path = "~/.gitconfig.personal";
      }
    ];
    
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
      "short-log" = "log --pretty=format:\"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]\" --decorate --date=short";
      "current-commit-sha" = "rev-parse --short HEAD";
      "current-branch" = "rev-parse --abbrev-ref HEAD";
      "branches" = "!git --no-pager branch -a";
    };
  };
  
  home.file.".gitconfig.personal" = {
    source = ./gitconfig.personal;
  };
  
  home.file.".gitignore.global" = {
    source = ./gitignore.global;
  };
}