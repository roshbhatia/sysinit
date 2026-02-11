{
  values,
  pkgs,
  ...
}:

let
  cfg = values.git;

  personalEmail = if cfg.personalEmail != null then cfg.personalEmail else cfg.email;
  workEmail = if cfg.workEmail != null then cfg.workEmail else cfg.email;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;
in
{
  imports = [
    ./config/gh-dash.nix
    ./config/lazygit.nix
    ./config/gitexcludes.nix
  ];

  programs.git.enable = false;
  home = {
    file = {
      ".gitconfig" = {
        text = ''
          [advice]
          addEmptyPathspec = false
          pushNonFastForward = false
          statusHints = false

          [diff]
            ignoreSpaceAtEol = true

          [init]
            defaultBranch = main

          [push]
            autoSetupRemote = true
            followTags = true

          [fetch]
            prune = true

          [core]
            editor = nvim
            excludesFile = ~/.gitexcludes
            compression = 9
            preloadIndex = true
            hooksPath = .githooks

          [merge]
            conflictstyle = zdiff3
            tool = nvim

          [mergetool]
            keepBackup = false
            prompt = false

          [mergetool "nvim"]
            cmd = nvim "MERGED" -c "CodeDiff merge ''$MERGED'"

          [diff]
            tool = nvim

          [difftool]
            prompt = false

          [difftool "nvim"]
            cmd = nvim "$LOCAL" "$REMOTE" +"CodeDiff file $LOCAL $REMOTE"

          [includeIf "gitdir:~/github/work/"]
            path = ~/.gitconfig.work

          [includeIf "gitdir:~/github/personal/"]
            path = ~/.gitconfig.personal

          [includeIf "gitdir:~/orgfiles/"]
            path = ~/.gitconfig.personal

          [includeIf "gitdir:~/.local/share/"]
            path = ~/.gitconfig.personal

          [rerere]
            enabled = true

          [alias]
            short-log = log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) %C(dim white)[%p]%C(reset) - %C(dim white)%ae%C(reset) - %C(bold green)%ad%C(reset) %C(white)%s%C(reset)%C(auto)%d%C(reset)' --date=short
            branches = !git --no-pager branch -vv
            all-branches = !git --no-pager branch -a -vv
            current-branch = rev-parse --abbrev-ref HEAD
            current-commit-sha = rev-parse --short HEAD
            last = log -1 HEAD --stat
            root = rev-parse --show-toplevel
            unstage = reset HEAD --

          [http "https://git.sr.ht"]
            sslVerify = false

          [rebase]
            updateRefs = true
        '';
        force = true;
      };

      ".gitconfig.personal" = {
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
        force = true;
      };

      ".gitconfig.work" = {
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
        force = true;
      };
    };
  };

}
