{
  lib,
  values,
  utils,
  ...
}:

let
  cfg = values.git;
  inherit (utils.themeHelper) mkThemedConfig;
  themeCfg = mkThemedConfig values "delta" { };
  deltaTheme = themeCfg.appTheme;

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

      [advice]
        addEmptyPathspec = false
        pushNonFastForward = false
        statusHints = false

      [diff]
          ignoreSpaceAtEol = true

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
          compression = 9
          preloadIndex = true
          hooksPath = .githooks

      [interactive]
          diffFilter = delta --color-only

      [delta]
          dark = true
          navigate = true
          side-by-side = true
          features = ${deltaTheme}

      [merge]
          conflictstyle = zdiff3

      [includeIf "gitdir:~/github/work/"]
          path = ~/.gitconfig.work

      [includeIf "gitdir:~/github/personal/"]
          path = ~/.gitconfig.personal


      [alias]
          p = pull
          P = push
          co = checkout
          cob = checkout -b
          br = branch
          st = status
          c = commit
          cai = !git-ai-commit
          ca = commit --amend
          cane = commit --amend --no-edit
          unstage = reset HEAD --
          lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
          last = log -1 HEAD
          short-log = log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short
          current-commit-sha = rev-parse --short HEAD
          current-branch = rev-parse --abbrev-ref HEAD
          branches = !git --no-pager branch -a
          root = rev-parse --show-toplevel

      [http "https://git.sr.ht"]
          sslVerify = false


      [include]
          path = ~/.config/delta/themes/${values.theme.colorscheme}.gitconfig

      [rebase]
          updateRefs = true
    '';
  };

  xdg.configFile =
    (utils.themeHelper.deployThemeFiles values {
      app = "delta";
      themeDir = ./themes;
      targetPath = "delta/themes";
      fileExtension = "gitconfig";
    })
    // {
      "lazygit/config.yml" = {
        source = ./configs/lazygit.yaml;
        force = true;
      };
    };

  home.file.".gitconfig.personal" = {
    text = ''
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
      [user]
          email = ${workEmail}

      [credential]
          username = ${workGithubUser}

      [github]
          user = ${workGithubUser}
    '';
  };

  home.file.".gitignore.global" = {
    source = ./configs/gitignore.global;
  };

}
