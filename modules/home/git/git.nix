{ config, lib, pkgs, ... }:

let
  cfg = config.sysinit.git or {
    userName = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    credentialUsername = "roshbhatia";
    githubUser = "roshbhatia";
  };
in
{
  programs.git = {
    enable = true;
    userName = lib.mkDefault cfg.userName;
    userEmail = lib.mkDefault cfg.userEmail;
    
    extraConfig = {
      pull.rebase = true;
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      fetch.prune = true;
      core.editor = "code --wait";
      core.excludesFile = "~/.gitignore.global";
      credential.helper = "store";
      credential.username = cfg.credentialUsername;
      github.user = cfg.githubUser;
    };
    
    includes = [
      {
        condition = "gitdir:~/github/work/";
        path = "~/.gitconfig.work";
      }
      {
        condition = "gitdir:~/github/personal/";
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