{
  values,
  utils,
  pkgs,
  ...
}:

let
  cfg = values.git;
  inherit (utils.theme) mkThemedConfig;
  themeCfg = mkThemedConfig values "delta" { };
  deltaTheme = themeCfg.appTheme;

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
        diffFilter = nvim-diff

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
        tool = meld

      [mergetool]
        keepBackup = false
        prompt = false

      [diff]
        tool = nvim-diff

      [difftool]
        prompt = false

      [difftool "nvim-diff"]
        cmd = nvim -c "CodeDiff file $LOCAL $REMOTE"

      [includeIf "gitdir:~/github/work/"]
        path = ~/.gitconfig.work

      [includeIf "gitdir:~/github/personal/"]
        path = ~/.gitconfig.personal

      [includeIf "gitdir:~/org/"]
        path = ~/.gitconfig.personal

      [rerere]
        enabled = true

      [alias]
        log = -c core.pager="bat --style=plain" log
        branches = !git --no-pager branch -a
        c = commit
        ca = commit --amend
        cai = !git-ai-commit
        cane = commit --amend --no-edit
        co = checkout
        cob = checkout -b
        commit-chore = "!f() { git commit -m \"chore: $@\"; }; f"
        commit-docs  = "!f() { git commit -m \"docs: $@\"; }; f"
        commit-feat  = "!f() { git commit -m \"feat: $@\"; }; f"
        commit-fix   = "!f() { git commit -m \"fix: $@\"; }; f"
        current-branch = rev-parse --abbrev-ref HEAD
        current-commit-sha = rev-parse --short HEAD
        fixup = "!git log -n50 --oneline | fzf | cut -d' ' -f1 | xargs -I{} git commit --fixup={}"
        last = log -1 HEAD
        root = rev-parse --show-toplevel
        short-log = log --graph --pretty=format:'%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]' --decorate --date=short
        squash = "!git rebase -i --autosquash HEAD~$(git rev-list --count HEAD ^$(git merge-base HEAD @{u}))"
        st = status
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
