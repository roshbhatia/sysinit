{
  lib,
  values,
  utils,
  pkgs,
  ...
}:

let
  cfg = values.git;
  deltaAdapter = import ./delta-lib.nix { inherit lib; };
  deltaTheme = deltaAdapter.getDeltaTheme values.theme.colorscheme values.theme.variant;

  personalEmail = if cfg.personalEmail != null then cfg.personalEmail else cfg.email;
  workEmail = if cfg.workEmail != null then cfg.workEmail else cfg.email;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;
in
{
  imports = [
    ./config/gh-dash.nix
    ./config/lazygit.nix
    ./config/gitignore.nix
  ];

  programs.git.enable = false;

  home.file.".gitconfig" = {
    text = ''
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
        followTags = true

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
        features = ${deltaTheme}
        file-decoration-style = none
        file-style = omit
        hunk-header-decoration-style = omit
        line-numbers-left-format = "{nm:>4} "
        line-numbers-right-format = "│ {np:>4} "
        side-by-side = true
        tabs = 2

      [merge]
        conflictstyle = zdiff3
        tool = diffview

      [mergetool]
        keepBackup = false
        prompt = false

      [mergetool "diffview"]
        cmd = nvim -n -c "DiffviewOpen"

      [diff]
        tool = diffview

      [difftool]
        prompt = false

      [difftool "diffview"]
        cmd = nvim -n -c "DiffviewOpen" "$LOCAL" "$REMOTE"

      [includeIf "gitdir:~/github/work/"]
        path = ~/.gitconfig.work

      [includeIf "gitdir:~/github/personal/"]
        path = ~/.gitconfig.personal

      [includeIf "gitdir:~/org/"]
        path = ~/.gitconfig.personal

      [includeIf "gitdir:~/.local/share/"]
        path = ~/.gitconfig.personal

      [rerere]
        enabled = true

      [alias]
        log = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'
        branches = !git --no-pager branch -vv
        all-branches = !git --no-pager branch -a -vv
        current-branch = rev-parse --abbrev-ref HEAD
        current-commit-sha = rev-parse --short HEAD
        last = log -1 HEAD --stat
        root = rev-parse --show-toplevel
        short-log = log --oneline --decorate --graph -20
        unstage = reset HEAD --

      [http "https://git.sr.ht"]
        sslVerify = false

      [include]
        path = ~/.config/delta/themes/${values.theme.colorscheme}-${values.theme.variant}.gitconfig

      [rebase]
        updateRefs = true
    '';
  };

  xdg.configFile = utils.theme.deployThemeFiles values {
    themeDir = ./themes;
    targetPath = "delta/themes";
    fileExtension = "gitconfig";
  };

  home.file.".gitconfig.personal" = {
    text = ''
      [user]
        name = ${cfg.name}
        email = ${personalEmail}

      [github]
        user = ${personalGithubUser}

      [credential "https://github.com"]
        helper = !${pkgs.gh}/bin/gh auth git-credential
        username = ${personalGithubUser}
        useHttpPath = true

      [credential "https://gist.github.com"]
        helper = !${pkgs.gh}/bin/gh auth git-credential
        username = ${personalGithubUser}
    '';
  };

  home.file.".gitconfig.work" = {
    text = ''
      [user]
        name = ${cfg.name}
        email = ${workEmail}

      [github]
        user = ${workGithubUser}

      [credential "https://github.com"]
        helper = !${pkgs.gh}/bin/gh auth git-credential
        username = ${workGithubUser}
        useHttpPath = true

      [credential "https://gist.github.com"]
        helper = !${pkgs.gh}/bin/gh auth git-credential
        username = ${workGithubUser}
    '';
  };
}
