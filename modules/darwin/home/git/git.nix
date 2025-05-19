{
  userConfig,
  ...
}:

let
  cfg = userConfig.git;

  personalEmail = if (cfg ? personalEmail) then cfg.personalEmail else cfg.userEmail;
  workEmail = if (cfg ? workEmail) then cfg.workEmail else cfg.userEmail;

  personalGithubUser = if (cfg ? personalGithubUser) then cfg.personalGithubUser else cfg.githubUser;
  workGithubUser = if (cfg ? workGithubUser) then cfg.workGithubUser else cfg.githubUser;
in
{
  programs.git = {
    enable = false;
  };

  home.file.".gitconfig" = {
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
          editor = nvim
          excludesFile = ~/.gitignore.global
          pager = delta

      [interactive]
          diffFilter = delta --color-only

      [delta]
          dark = true
          navigate = true
          side-by-side = true

      [merge]
          conflictstyle = zdiff3

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
          root = rev-parse --show-toplevel
    '';
  };

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

  home.file.".gitconfig.work" = {
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

