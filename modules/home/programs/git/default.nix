{
  config,
  pkgs,
  ...
}:

let
  cfg = config.sysinit.git;
in
{
  imports = [
    ./options.nix
  ];

  programs.git = {
    enable = true;

    ignores = [
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
      ".Trash-*"
      ".directory"
      ".fuse_hidden*"
      ".nfs*"
      "nohup.out"
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
      "*.backup"
      "*.backup*"
      "*.bak"
      "*.bak*"
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
      ".sysinit/"
      ".direnv/"
      ".env"
      ".env.*.local"
      ".env.local"
      ".envrc"
      ".sysinit.nix"
      ".neoconf.json"
      ".pnp.*"
      ".yarn-integrity"
      ".yarn/"
      "node_modules/"
      "npm-debug.log*"
      "pnpm-debug.log*"
      "yarn-debug.log*"
      "yarn-error.log*"
      ".nyc_output"
      "coverage/"
      "*.lcov"
      ".pytest_cache/"
      ".coverage"
      "htmlcov/"
      ".playwright-mcp/"
      "playwright-report/"
      "playwright/.cache/"
      "blob-report/"
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
      "*.gem"
      ".bundle/"
      "vendor/bundle/"
      "*.class"
      "*.jar"
      "*.war"
      "*.ear"
      "go.work"
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

      pull = {
        rebase = true;
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

      rebase = {
        updateRefs = true;
      };

      user = {
        inherit (cfg) name email username;
      };
    };
  };

  home.packages = [ pkgs.mergiraf ];

  programs.git.attributes = [ "* merge=mergiraf" ];
}
