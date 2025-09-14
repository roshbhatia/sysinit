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

  personalEmail = cfg.personalEmail or cfg.userEmail;
  workEmail = cfg.workEmail or cfg.userEmail;
  personalUsername = cfg.personalUsername or cfg.username;
  workUsername = cfg.workUsername or cfg.username;
in
{
  programs.git = {
    enable = true;
    userName = cfg.name;
    userEmail = cfg.userEmail;

    aliases = {
      p = "pull";
      P = "push";
      co = "checkout";
      cob = "checkout -b";
      br = "branch";
      st = "status";
      c = "commit";
      cai = "!git-ai-commit";
      ca = "commit --amend";
      cane = "commit --amend --no-edit";
      unstage = "reset HEAD --";
      lg = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      last = "log -1 HEAD";
      short-log = "log --pretty=format:\"%C(yellow)%h %ad%Cred%d %Creset%s%Cblue [%cn]\" --decorate --date=short";
      current-commit-sha = "rev-parse --short HEAD";
      current-branch = "rev-parse --abbrev-ref HEAD";
      branches = "!git --no-pager branch -a";
      root = "rev-parse --show-toplevel";
    };

    ignores = [
      ".DS_Store"
      "*.swp"
      "*.swo"
      "*~"
      ".direnv/"
      ".devenv/"
      ".envrc"
      "node_modules/"
      ".env"
      ".env.local"
      "*.log"
    ];

    extraConfig = {
      credential = {
        helper = "store";
        username = cfg.username;
      };

      github = {
        user = cfg.username;
      };

      advice = {
        addEmptyPathspec = false;
        pushNonFastForward = false;
        statusHints = false;
      };

      diff = {
        ignoreSpaceAtEol = true;
      };

      pull = {
        rebase = true;
      };

      init = {
        defaultBranch = "main";
      };

      push = {
        autoSetupRemote = true;
      };

      fetch = {
        prune = true;
      };

      core = {
        editor = "nvim";
        compression = 9;
        preloadIndex = true;
        hooksPath = ".githooks";
      };

      merge = {
        conflictstyle = "zdiff3";
        tool = "diffview";
      };

      mergetool = {
        prompt = false;
        keepBackup = false;
        "diffview" = {
          cmd = "nvim -n -c \"DiffviewOpen\" \"$MERGE\"";
        };
      };

      "http \"https://git.sr.ht\"" = {
        sslVerify = false;
      };

      include = {
        path = "~/.config/delta/themes/${values.theme.colorscheme}-${values.theme.variant}.gitconfig";
      };

      rebase = {
        updateRefs = true;
      };
    };

    includes = [
      {
        condition = "gitdir:~/github/work/";
        contents = {
          user = {
            name = cfg.name;
            email = workEmail;
          };
          credential = {
            helper = "store";
            username = workUsername;
          };
          github = {
            user = workUsername;
          };
        };
      }
      {
        condition = "gitdir:~/github/personal/";
        contents = {
          user = {
            name = cfg.name;
            email = personalEmail;
          };
          credential = {
            helper = "store";
            username = personalUsername;
          };
          github = {
            user = personalUsername;
          };
        };
      }
    ];

    delta = {
      enable = true;
      options = {
        dark = true;
        navigate = true;
        side-by-side = true;
        features = deltaTheme;
      };
    };
  };

  xdg.configFile =
    utils.themes.deployThemeFiles values {
      themeDir = ./themes;
      targetPath = "delta/themes";
      fileExtension = "gitconfig";
    }
    // {
      "lazygit/config.yml" = {
        source = ./configs/lazygit.yaml;
        force = true;
      };
    };
}
