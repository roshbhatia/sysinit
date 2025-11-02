{
  values,
  utils,
  ...
}:

let
  cfg = values.git;
  inherit (utils.themes) mkThemedConfig;
  themeCfg = mkThemedConfig values "delta" { };
  deltaTheme = themeCfg.appTheme;

  personalEmail = if cfg.personalEmail != null then cfg.personalEmail else cfg.email;
  workEmail = if cfg.workEmail != null then cfg.workEmail else cfg.email;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;
in
{
  programs.git = {
    enable = false;
  };

  home.file.".gitconfig" = {
    text = ''
      [user]
        name = ${cfg.name}
        email = ${personalEmail}

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
        dark = true
        navigate = true
        side-by-side = true
        features = ${deltaTheme}

      [merge]
        conflictstyle = zdiff3
        tool = diffview

      [mergetool]
        prompt = false
        keepBackup = false

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

      [rerere]
        enabled = true

      [alias]
        P = push
        br = branch
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
        diff-all = diff HEAD
        diff-cached = diff --cached
        diff-staged = diff --cached
        diff-unstaged = diff
        fixup = "!git log -n50 --oneline | fzf | cut -d' ' -f1 | xargs -I{} git commit --fixup={}"
        last = log -1 HEAD
        lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
        p = pull
        root = rev-parse --show-toplevel
        short-log = log --pretty=format:"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]" --decorate --date=short
        show-diff = diff --no-color
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

  xdg.configFile =
    (utils.themes.deployThemeFiles values {
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
        name = ${cfg.name}
        email = ${personalEmail}

      [credential]
        helper = store
        username = ${personalGithubUser}

      [github]
        user = ${personalGithubUser}
    '';
  };

  home.file.".gitconfig.work" = {
    text = ''
      [user]
        name = ${cfg.name}
        email = ${workEmail}

      [credential]
        helper = store
        username = ${workGithubUser}

      [github]
        user = ${workGithubUser}
    '';
  };

  home.file.".gitignore.global" = {
    source = ./configs/gitignore.global;
  };
}
