{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.sysinit.git;
  sshCfg = cfg.ssh;

  inherit (pkgs.stdenv) isDarwin;

  use1Password = sshCfg.use1PasswordAgent && isDarwin;

  personalEmail = if cfg.personalEmail != null then cfg.personalEmail else cfg.email;
  workEmail = if cfg.workEmail != null then cfg.workEmail else cfg.email;

  personalGithubUser = if cfg.personalUsername != null then cfg.personalUsername else cfg.username;
  workGithubUser = if cfg.workUsername != null then cfg.workUsername else cfg.username;

  personalKeyPath =
    if use1Password && sshCfg.personalPublicKey != null then
      "~/.ssh/1p_personal.pub"
    else if sshCfg.personalKeyFile != null then
      sshCfg.personalKeyFile
    else
      cfg.personalSshKeyFile;

  workKeyPath =
    if use1Password && sshCfg.workPublicKey != null then
      "~/.ssh/1p_work.pub"
    else if sshCfg.workKeyFile != null then
      sshCfg.workKeyFile
    else
      cfg.workSshKeyFile;

  hasPersonalKey = personalKeyPath != null;
  hasWorkKey = workKeyPath != null;

  sshCmd =
    keyFile:
    if use1Password then
      "ssh -o 'IdentityAgent=\"${sshCfg.agentSocket}\"'"
    else
      "ssh -i ${keyFile} -o IdentitiesOnly=yes";
in
{
  imports = [
    ./options.nix
  ];

  programs.git = {
    enable = true;

    ignores = [
      # macOS
      ".AppleDB"
      ".AppleDesktop"
      ".AppleDouble"
      ".DS_Store"
      ".DocumentRevisions-V100"
      ".LSOverride"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Trashes"
      ".VolumeIcon.icns"
      "._*"
      ".apdisk"
      ".com.apple.timemachine.donotpresent"
      ".fseventsd"
      "Icon\r"
      "Network Trash Folder"
      "Temporary Items"
      "__MACOSX/"
      # Linux
      ".Trash-*"
      ".directory"
      ".fuse_hidden*"
      ".nfs*"
      "nohup.out"
      # Windows
      "$RECYCLE.BIN/"
      "*:Zone.Identifier"
      "*.cab"
      "*.lnk"
      "*.msi"
      "*.msix"
      "*.msm"
      "*.msp"
      "*.stackdump"
      "[Dd]esktop.ini"
      "Thumbs.db"
      "Thumbs.db:encryptable"
      "ehthumbs.db"
      "ehthumbs_vista.db"
      # Editors
      "*.swo"
      "*.swp"
      "*.un~"
      "*~"
      ".idea/"
      ".netrwhist"
      ".vscode/"
      "Session.vim"
      "Sessionx.vim"
      "[._]*.s[a-v][a-z]"
      "[._]*.sw[a-p]"
      "[._]s[a-rt-v][a-z]"
      "[._]ss[a-gi-z]"
      "tags"
      "tags.lock"
      "tags.temp"
      # Backups
      "*.backup"
      "*.backup*"
      "*.bak"
      "*.bak*"
      # AI Assistants
      "**/.agents/"
      "**/.amp/"
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
      # Dev environment
      ".direnv/"
      ".env"
      ".env.*.local"
      ".env.local"
      ".envrc"
      ".gitattributes"
      ".sysinit.nix"
      # Package managers
      ".pnp.*"
      ".yarn-integrity"
      ".yarn/"
      "node_modules/"
      "npm-debug.log*"
      "pnpm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"
      # Testing & Coverage
      ".nyc_output"
      "coverage/"
      "*.lcov"
      ".pytest_cache/"
      ".coverage"
      "htmlcov/"
      # Build artifacts
      "*.o"
      "*.so"
      "*.dylib"
      "*.dll"
      "*.exe"
      "*.out"
      "*.app"
      "dist/"
      "build/"
      "*.egg-info/"
      "target/"
      # Python
      "*.py[cod]"
      "*$py.class"
      "*.pyo"
      "*.pyd"
      ".Python"
      "__pycache__/"
      "pip-log.txt"
      "pip-delete-this-directory.txt"
      ".venv"
      "venv/"
      "ENV/"
      "env.bak/"
      "venv.bak/"
      # Ruby
      "*.gem"
      ".bundle/"
      "vendor/bundle/"
      # Java/JVM
      "*.class"
      "*.jar"
      "*.war"
      "*.ear"
      # Rust
      "Cargo.lock"
      # Go
      "go.work"
      # Misc
      "**/*.glossary.yml"
      "**/sgconfig.yaml"
      "**/sgconfig.yml"
      "*.log"
      "ast-grep/"
      ".cache/"
      "*.tmp"
      "*.temp"
    ];

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

      merge = {
        conflictstyle = "diff3";
        tool = "nvim";
        mergiraf = {
          name = "mergiraf";
          driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
        };
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

      url."git@github.com:" = {
        insteadOf = "https://github.com/";
      };

      http."https://git.sr.ht" = {
        sslVerify = false;
      };

      rebase = {
        updateRefs = true;
      };

      # Disable macOS osxkeychain default; authentication is handled per-directory
      # via core.sshCommand in the gitdir-scoped includes below.
      credential.helper = "";

      user = {
        inherit (cfg) name;
      };
    };

    includes =
      let
        personalInclude = {
          user = {
            email = personalEmail;
            username = personalGithubUser;
          };
          url = {
            "git@github-personal:" = {
              insteadOf = "git@github.com:";
            };
            "ssh://git@github-personal/" = {
              insteadOf = "ssh://git@github.com/";
            };
          };
        }
        // lib.optionalAttrs (!use1Password && hasPersonalKey) {
          core.sshCommand = sshCmd personalKeyPath;
        };

        workInclude = {
          user = {
            email = workEmail;
            username = workGithubUser;
          };
          url = {
            "git@github-work:" = {
              insteadOf = "git@github.com:";
            };
            "ssh://git@github-work/" = {
              insteadOf = "ssh://git@github.com/";
            };
          };
        }
        // lib.optionalAttrs (!use1Password && hasWorkKey) {
          core.sshCommand = sshCmd workKeyPath;
        };
      in
      [
        {
          condition = "gitdir:~/github/work/";
          contents = workInclude;
        }
        {
          condition = "gitdir:~/github/personal/";
          contents = personalInclude;
        }
        {
          condition = "gitdir:~/orgfiles/";
          contents = personalInclude;
        }
        {
          condition = "gitdir:~/.local/share/nvim/";
          contents = personalInclude;
        }
        {
          condition = "gitdir:~/.config/nvim/";
          contents = personalInclude;
        }
      ];
  };

  home.packages = [ pkgs.mergiraf ];

  # Register mergiraf as the global git merge driver for all files.
  # Uses diff3 conflict style (not zdiff3) as required by mergiraf.
  home.file.".config/git/attributes".text = "* merge=mergiraf\n";
}
