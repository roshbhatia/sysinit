{ config, lib, pkgs, userConfig, ... }:

let
  # Get git configuration from userConfig passed from flake.nix
  cfg = userConfig.git or {
    userName = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    credentialUsername = "roshbhatia";
    githubUser = "roshbhatia";
  };
in
{
  # We're disabling the built-in git module and managing our own config
  programs.git = {
    enable = false; # Disable home-manager's git management
  };
  
  # Add our own managed gitconfig file - this gives us full control over its content
  home.file.".gitconfig" = {
    # Use a text content that we generate instead of a static file
    text = ''
[user]
    name = ${cfg.userName}
    email = ${cfg.userEmail}

[credential]
    helper = store
    username = ${cfg.credentialUsername}

[github]
    user = ${cfg.githubUser}

[pull]
    rebase = true

[init]
    defaultBranch = main

[push]
    autoSetupRemote = true

[fetch]
    prune = true

[core]
    editor = code --wait
    excludesFile = ~/.gitignore.global

[includeIf "gitdir:~/github/work/"]
    path = ~/.gitconfig.work

[includeIf "gitdir:~/github/personal/"]
    path = ~/.gitconfig.personal

[alias]
    co = checkout
    br = branch
    st = status
    c = commit
    ca = commit --amend
    cane = commit --amend --no-edit
    unstage = reset HEAD --
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    last = log -1 HEAD
    short-log = log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short
    current-commit-sha = rev-parse --short HEAD
    current-branch = rev-parse --abbrev-ref HEAD
    branches = !git --no-pager branch -a
'';
  };

  home.file.".gitconfig.personal" = {
    source = ./gitconfig.personal;
  };
  
  home.file.".gitignore.global" = {
    source = ./gitignore.global;
  };
}