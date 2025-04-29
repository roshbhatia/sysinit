{ config, lib, pkgs, userConfig, ... }:

let
  # Get git configuration from userConfig passed from flake.nix
  # Since validation happens in flake.nix, we can be confident these values exist
  cfg = userConfig.git;
  
  # For additional safety, log warning if any properties are missing
  # This shouldn't happen due to flake.nix validation, but provides a helpful error
  missingProps = lib.filter
    (prop: !(cfg ? ${prop}))
    ["userName" "userEmail" "githubUser"];
  
  # Show warning if any props are missing (shouldn't happen due to flake.nix validation)
  _ = lib.warnIf (missingProps != [])
    "Git configuration in module is missing properties: ${toString missingProps}";
    
  # Get specific email addresses (defaulting to the global one if not specified)
  personalEmail = if (cfg ? personalEmail) then cfg.personalEmail else cfg.userEmail;
  workEmail = if (cfg ? workEmail) then cfg.workEmail else cfg.userEmail;
  
  # Assume credentialUsername is same as githubUser if not specified separately
  personalGithubUser = if (cfg ? personalGithubUser) then cfg.personalGithubUser else cfg.githubUser;
  workGithubUser = if (cfg ? workGithubUser) then cfg.workGithubUser else cfg.githubUser;
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
    username = ${cfg.githubUser}

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
    ghcs-commit = !ghcs-commitmessage | jq -r .message | git commit -F -
'';
  };

  # Generate the personal gitconfig dynamically
  home.file.".gitconfig.personal" = {
    text = ''
# Personal-specific Git configuration
# This file is included when in ~/github/personal/ directories

[user]
    email = ${personalEmail}

[credential]
    username = ${personalGithubUser}

[github]
    user = ${personalGithubUser}
'';
  };
  
  # Add work-specific Git configuration
  home.file.".gitconfig.work" = {
    # Use a text content that we generate instead of a static file
    text = ''
# Work-specific Git configuration
# This file is included when in ~/github/work/ directories

[user]
    email = ${workEmail}

[credential]
    username = ${workGithubUser}

[github]
    user = ${workGithubUser}
'';
  };
  
  home.file.".gitignore.global" = {
    source = ./gitignore.global;
  };
}
