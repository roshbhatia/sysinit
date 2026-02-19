{
  config,
  pkgs,
  ...
}:

let
  cfg = config.sysinit.git;

  personalEmail = if cfg.personalEmail != null then cfg.personalEmail else cfg.email;
  workEmail = if cfg.workEmail != null then cfg.workEmail else cfg.email;
  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;

  # Global gitignore patterns
  macosPatterns = [
    ".AppleDouble"
    ".DS_Store"
    ".DocumentRevisions-V100"
    ".LSOverride"
    ".Spotlight-V100"
    ".TemporaryItems"
    ".Trashes"
    ".VolumeIcon.icns"
    "._*"
    ".com.apple.timemachine.donotpresent"
    ".fseventsd"
  ];

  editorPatterns = [
    "*.swo"
    "*.swp"
    "*~"
    ".cursor/"
    ".idea/"
    ".vscode/"
    "tags"
  ];

  backupPatterns = [
    "*.backup"
    "*.backup*"
    "*.bak"
    "*.bak*"
  ];

  aiAssistantPatterns = [
    "**/.agents/"
    "**/.amp/"
    "**/.beads/"
    "**/.claude/"
    "**/.codex/"
    "**/.crush/"
    "**/.cursor/"
    "**/.cursorrules/"
    "**/.gemini/"
    "**/.goose/"
    "**/.goosehints"
    "**/.opencode/"
    "**/AGENTS.md"
    "**/CLAUDE.md"
    "**/CRUSH.md"
    "**/GEMINI.md"
    "**/openspec/"
    ".sysinit/"
  ];

  devEnvPatterns = [
    ".direnv/"
    ".envrc"
    ".gitattributes"
    "shell.nix"
  ];

  nodePatterns = [
    "node_modules/"
    "npm-debug.log"
    "yarn-debug.log"
    "yarn-error.log"
  ];

  miscPatterns = [
    "**/*.glossary.yml"
    "**/sgconfig.yaml"
    "**/sgconfig.yml"
    "*.log"
    "ast-grep/"
  ];

  allIgnorePatterns =
    macosPatterns
    ++ editorPatterns
    ++ backupPatterns
    ++ aiAssistantPatterns
    ++ devEnvPatterns
    ++ nodePatterns
    ++ miscPatterns;
in
{
  imports = [
    ./options.nix
  ];

  programs.git = {
    enable = true;
    package = pkgs.git;

    ignores = allIgnorePatterns;

    settings = {
      advice = {
        addEmptyPathspec = false;
        pushNonFastForward = false;
        statusHints = false;
      };

      diff = {
        ignoreSpaceAtEol = true;
        tool = "nvim";
      };

      init = {
        defaultBranch = "main";
      };

      push = {
        autoSetupRemote = true;
        followTags = true;
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

      credential = {
        "https://github.com" = {
          helper = "!${pkgs.gh}/bin/gh auth git-credential";
        };
      };

      merge = {
        conflictstyle = "zdiff3";
        tool = "nvim";
      };

      mergetool = {
        keepBackup = false;
        prompt = false;
        nvim = {
          cmd = ''nvim "MERGED" -c "CodeDiff merge $MERGED"'';
        };
      };

      difftool = {
        prompt = false;
        nvim = {
          cmd = ''nvim "$LOCAL" "$REMOTE" +"CodeDiff file $LOCAL $REMOTE"'';
        };
      };

      rerere = {
        enabled = true;
      };

      alias = {
        short-log = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) %C(dim white)[%p]%C(reset) - %C(dim white)%ae%C(reset) - %C(bold green)%ad%C(reset) %C(white)%s%C(reset)%C(auto)%d%C(reset)' --date=short";
        branches = "!git --no-pager branch -vv";
        all-branches = "!git --no-pager branch -a -vv";
        current-branch = "rev-parse --abbrev-ref HEAD";
        current-commit-sha = "rev-parse --short HEAD";
        last = "log -1 HEAD --stat";
        root = "rev-parse --show-toplevel";
        unstage = "reset HEAD --";
      };

      http."https://git.sr.ht" = {
        sslVerify = false;
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
          github = {
            user = workGithubUser;
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
          github = {
            user = personalGithubUser;
          };
        };
      }
      {
        condition = "gitdir:~/orgfiles/";
        contents = {
          user = {
            name = cfg.name;
            email = personalEmail;
          };
          github = {
            user = personalGithubUser;
          };
        };
      }
      {
        condition = "gitdir:~/.local/share/";
        contents = {
          user = {
            name = cfg.name;
            email = personalEmail;
          };
          github = {
            user = personalGithubUser;
          };
        };
      }
    ];
  };
}
