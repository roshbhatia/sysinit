{
  lib,
  pkgs,
  values,
  ...
}:
let
  llmLib = import ../lib { inherit lib; };
  mcpServers = import ../mcp.nix { inherit lib values; };
  skillsLib = import ../skills.nix { inherit pkgs; };

  disabledMcpServers = [ "beads" ];

  defaultInstructions = llmLib.instructions.makeInstructions {
    inherit (skillsLib) localSkillDescriptions;
    skillsRoot = "~/.config/opencode/skills";
  };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    autoupdate = false;
    share = "disabled";
    theme = "system";

    tui = {
      scroll_acceleration = {
        enabled = true;
      };
    };

    mcp = llmLib.mcp.formatForOpencode disabledMcpServers mcpServers.servers;

    instructions = [
      "**/.cursorrules"
      "**/AGENTS.md"
      "**/CLAUDE.md"
      "**/CONSTITUTION.md"
      "**/CONTRIBUTING.md"
      "**/COPILOT.md"
      "**/docs/guidelines.md"
      ".cursor/rules"
      ".sysinit/lessons.md"
    ];

    keybinds = {
      leader = "ctrl+a";
    };

    permission = {
      webfetch = "allow";
      grep = "allow";
      read = "allow";
      bash = {
        # Navigation - always safe
        "cd*" = "allow";
        "pwd*" = "allow";
        "ls*" = "allow";
        "exa*" = "allow";
        "eza*" = "allow";
        "tree*" = "allow";
        "zoxide*" = "allow";

        # File reading - safe read-only
        "cat*" = "allow";
        "bat*" = "allow";
        "head*" = "allow";
        "tail*" = "allow";
        "less*" = "allow";
        "more*" = "allow";
        "file*" = "allow";
        "stat*" = "allow";

        # Search - read-only without modification flags
        "rg*" = "allow";
        "ripgrep*" = "allow";
        "grep*" = "allow";
        "egrep*" = "allow";
        "fgrep*" = "allow";
        "ag*" = "allow";
        "fd*" = "allow";
        "find*" = "allow";
        "locate*" = "allow";
        "which*" = "allow";
        "whereis*" = "allow";
        "type*" = "allow";
        "ast-grep*" = "allow";
        "sg*" = "allow";

        # Text processing - read-only
        "awk*" = "allow";
        "sed*" = "allow";
        "cut*" = "allow";
        "sort*" = "allow";
        "uniq*" = "allow";
        "tr*" = "allow";
        "wc*" = "allow";
        "column*" = "allow";
        "tac*" = "allow";
        "rev*" = "allow";
        "fold*" = "allow";
        "fmt*" = "allow";
        "join*" = "allow";
        "paste*" = "allow";

        # System info - always safe
        "echo*" = "allow";
        "whoami*" = "allow";
        "hostname*" = "allow";
        "uname*" = "allow";
        "date*" = "allow";
        "uptime*" = "allow";
        "env*" = "allow";
        "printenv*" = "allow";
        "df*" = "allow";
        "du*" = "allow";
        "ps*" = "allow";
        "pgrep*" = "allow";
        "id*" = "allow";
        "groups*" = "allow";
        "who*" = "allow";
        "w*" = "allow";
        "last*" = "allow";
        "history*" = "allow";

        # Git - read operations (safe)
        "git status*" = "allow";
        "git diff*" = "allow";
        "git log*" = "allow";
        "git show*" = "allow";
        "git branch*" = "allow";
        "git remote*" = "allow";
        "git tag*" = "allow";
        "git config --list*" = "allow";
        "git config --get*" = "allow";
        "git ls-files*" = "allow";
        "git ls-remote*" = "allow";
        "git describe*" = "allow";
        "git rev-parse*" = "allow";
        "git rev-list*" = "allow";
        "git blame*" = "allow";
        "git stash list*" = "allow";
        "git stash show*" = "allow";
        "git worktree list*" = "allow";
        "git submodule status*" = "allow";

        # Git - write operations (need confirmation)
        "git add*" = "ask";
        "git rm*" = "ask";
        "git mv*" = "ask";
        "git commit*" = "ask";
        "git push*" = "ask";
        "git fetch*" = "ask";
        "git pull*" = "ask";
        "git merge*" = "ask";
        "git rebase*" = "ask";
        "git cherry-pick*" = "ask";
        "git revert*" = "ask";
        "git reset*" = "ask";
        "git checkout*" = "ask";
        "git switch*" = "ask";
        "git restore*" = "ask";
        "git clean*" = "ask";
        "git stash*" = "ask";
        "git worktree*" = "ask";
        "git submodule*" = "ask";
        "git init*" = "ask";
        "git clone*" = "ask";

        # GitHub CLI - read operations
        "gh repo view*" = "allow";
        "gh pr list*" = "allow";
        "gh pr view*" = "allow";
        "gh pr diff*" = "allow";
        "gh pr checks*" = "allow";
        "gh issue list*" = "allow";
        "gh issue view*" = "allow";
        "gh run list*" = "allow";
        "gh run view*" = "allow";
        "gh workflow list*" = "allow";
        "gh release list*" = "allow";
        "gh release view*" = "allow";
        "gh gist list*" = "allow";
        "gh gist view*" = "allow";
        "gh auth status*" = "allow";
        "gh status*" = "allow";

        # GitHub CLI - write operations
        "gh pr create*" = "ask";
        "gh pr merge*" = "ask";
        "gh pr close*" = "ask";
        "gh pr update*" = "ask";
        "gh pr review*" = "ask";
        "gh issue create*" = "ask";
        "gh issue close*" = "ask";
        "gh issue edit*" = "ask";
        "gh run rerun*" = "ask";
        "gh run watch*" = "ask";
        "gh release create*" = "ask";
        "gh release edit*" = "ask";
        "gh release delete*" = "ask";
        "gh repo create*" = "ask";
        "gh repo fork*" = "ask";
        "gh repo delete*" = "ask";
        "gh gist create*" = "ask";
        "gh gist edit*" = "ask";
        "gh gist delete*" = "ask";
        "gh auth*" = "ask";

        # Nix - read operations
        "nix flake check*" = "allow";
        "nix flake show*" = "allow";
        "nix flake metadata*" = "allow";
        "nix flake info*" = "allow";
        "nix eval*" = "allow";
        "nix search*" = "allow";
        "nix store ping*" = "allow";
        "nix store info*" = "allow";
        "nix path-info*" = "allow";
        "nix show-config*" = "allow";
        "nix-instantiate*" = "allow";
        "nix-prefetch*" = "allow";

        # Nix - write operations
        "nix build*" = "ask";
        "nix run*" = "ask";
        "nix develop*" = "ask";
        "nix shell*" = "ask";
        "nix profile*" = "ask";
        "nix-env*" = "ask";
        "nix-store*" = "ask";
        "nix-collect-garbage*" = "ask";
        "nix copy*" = "ask";
        "nix edit*" = "ask";
        "nix fmt*" = "ask";
        "darwin-rebuild*" = "ask";
        "home-manager*" = "ask";
        "nh*" = "ask";

        # File operations - creation/modification (ask)
        "touch*" = "ask";
        "mkdir*" = "ask";
        "ln*" = "ask";
        "cp*" = "ask";
        "mv*" = "ask";
        "rename*" = "ask";
        "install*" = "ask";
        "dd*" = "ask";

        # File operations - deletion (ask - dangerous)
        "rm*" = "ask";
        "rmdir*" = "ask";
        "unlink*" = "ask";

        # Permissions (ask)
        "chmod*" = "ask";
        "chown*" = "ask";
        "chgrp*" = "ask";
        "umask*" = "ask";
        "getfacl*" = "allow";

        # Compression - reading (allow)
        "tar -tf*" = "allow";
        "tar --list*" = "allow";
        "unzip -l*" = "allow";
        "zipinfo*" = "allow";
        "zcat*" = "allow";
        "zless*" = "allow";

        # Compression - writing (ask)
        "tar*" = "ask";
        "zip*" = "ask";
        "unzip*" = "ask";
        "gzip*" = "ask";
        "gunzip*" = "ask";
        "bzip2*" = "ask";
        "bunzip2*" = "ask";
        "xz*" = "ask";
        "unxz*" = "ask";
        "7z*" = "ask";
        "7za*" = "ask";

        # Build tools (ask)
        "make*" = "ask";
        "gmake*" = "ask";
        "cmake*" = "ask";
        "meson*" = "ask";
        "ninja*" = "ask";
        "bazel*" = "ask";
        "buck*" = "ask";
        "gradle*" = "ask";
        "mvn*" = "ask";
        "maven*" = "ask";
        "ant*" = "ask";
        "sbt*" = "ask";
        "cargo*" = "ask";
        "rustup*" = "ask";
        "go build*" = "ask";
        "go install*" = "ask";
        "go get*" = "ask";
        "go mod*" = "ask";
        "go run*" = "ask";
        "tsc*" = "ask";
        "webpack*" = "ask";
        "vite*" = "ask";
        "rollup*" = "ask";
        "esbuild*" = "ask";
        "pnpm*" = "ask";
        "yarn*" = "ask";
        "npm*" = "ask";
        "bun*" = "ask";
        "node*" = "ask";
        "deno*" = "ask";
        "pip*" = "ask";
        "pip3*" = "ask";
        "poetry*" = "ask";
        "pipenv*" = "ask";
        "conda*" = "ask";
        "bundle*" = "ask";
        "gem*" = "ask";
        "rake*" = "ask";
        "composer*" = "ask";

        # Task runners (ask)
        "task*" = "ask";
        "go-task*" = "ask";
        "just*" = "ask";
        "invoke*" = "ask";
        "fab*" = "ask";
        "tox*" = "ask";
        "nox*" = "ask";
        "act*" = "ask";

        # Formatters (ask - they modify files)
        "shfmt*" = "ask";
        "prettier*" = "ask";
        "black*" = "ask";
        "isort*" = "ask";
        "autopep8*" = "ask";
        "rustfmt*" = "ask";
        "gofmt*" = "ask";
        "gofumpt*" = "ask";
        "goimports*" = "ask";
        "alejandra*" = "ask";
        "nixfmt*" = "ask";
        "nixpkgs-fmt*" = "ask";
        "terraform fmt*" = "ask";
        "packer fmt*" = "ask";

        # Linters/checkers (allow - read only)
        "shellcheck*" = "allow";
        "eslint*" = "allow";
        "flake8*" = "allow";
        "pylint*" = "allow";
        "mypy*" = "allow";
        "ruff*" = "allow";
        "clang-tidy*" = "allow";
        "protolint*" = "allow";
        "hadolint*" = "allow";
        "markdownlint*" = "allow";
        "vale*" = "allow";
        "htmlhint*" = "allow";
        "stylelint*" = "allow";
        "csslint*" = "allow";
        "jsonlint*" = "allow";
        "yamllint*" = "allow";
        "ansible-lint*" = "allow";
        "terraform validate*" = "allow";
        "tflint*" = "allow";
        "tfsec*" = "allow";
        "helm lint*" = "allow";
        "kubeconform*" = "allow";
        "conftest*" = "allow";
        "opa test*" = "allow";
        "regal*" = "allow";
        "deadnix*" = "allow";
        "statix*" = "allow";

        # Test runners (ask - execute code)
        "pytest*" = "ask";
        "py.test*" = "ask";
        "unittest*" = "ask";
        "nose*" = "ask";
        "nosetests*" = "ask";
        "jest*" = "ask";
        "vitest*" = "ask";
        "ava*" = "ask";
        "mocha*" = "ask";
        "jasmine*" = "ask";
        "karma*" = "ask";
        "cypress*" = "ask";
        "playwright*" = "ask";
        "testcafe*" = "ask";
        "cargo test*" = "ask";
        "cargo bench*" = "ask";
        "go test*" = "ask";
        "go vet*" = "allow";
        "gotestsum*" = "ask";
        "ginkgo*" = "ask";
        "rspec*" = "ask";
        "minitest*" = "ask";
        "bundle exec rake*" = "ask";
        "rake test*" = "ask";
        "rails test*" = "ask";
        "mix test*" = "ask";
        "exunit*" = "ask";
        "dart test*" = "ask";
        "flutter test*" = "ask";
        "dotnet test*" = "ask";
        "mstest*" = "ask";
        "nunit*" = "ask";
        "xunit*" = "ask";
        "phpunit*" = "ask";
        "codecept*" = "ask";
        "pest*" = "ask";

        # Security - ask for sudo/root
        "sudo*" = "ask";
        "su*" = "ask";
        "doas*" = "ask";
        "pkexec*" = "ask";
        "sudoedit*" = "ask";
        "visudo*" = "ask";

        # Network tools (ask)
        "curl*" = "ask";
        "wget*" = "ask";
        "http*" = "ask";
        "ht*" = "ask";
        "xh*" = "ask";
        "aria2c*" = "ask";

        # Database (ask)
        "psql*" = "ask";
        "mysql*" = "ask";
        "sqlite3*" = "ask";
        "redis-cli*" = "ask";
        "mongosh*" = "ask";
        "cqlsh*" = "ask";

        # Docker/podman (ask)
        "docker*" = "ask";
        "docker-compose*" = "ask";

        # Kubernetes (ask)
        "kubectl*" = "ask";
        "k*" = "ask";
        "helm*" = "ask";
        "kustomize*" = "ask";
        "skaffold*" = "ask";
        "tilt*" = "ask";

        # Editors - ask since they block terminal
        "vim*" = "ask";
        "nvim*" = "ask";
        "nano*" = "ask";
        "emacs*" = "ask";
        "pico*" = "ask";

        # Screen/tmux - ask since they block terminal
        "screen*" = "ask";
        "tmux*" = "ask";
        "byobu*" = "ask";

        # Beads (allow - task tracking)
        "bd*" = "allow";

        # OpenSpec (ask)
        "openspec*" = "ask";

        # Default fallback
        "*" = "ask";
      };
      skill = {
        "*" = "allow";
      };
    };

    formatter = {
      deadnix = {
        command = [
          "${pkgs.deadnix}/bin/deadnix"
          "--edit"
          "$FILE"
        ];
        extensions = [ ".nix" ];
      };
    };

    plugin = [
      "@bastiangx/opencode-unmoji"
      "opencode-agent-skills"
      "opencode-handoff"
      "opencode-plugin-openspec"
    ];
  };

  subagentFiles = lib.mapAttrs' (
    name: config:
    lib.nameValuePair "opencode/agent/${name}.md" {
      text = llmLib.instructions.formatSubagentAsMarkdown { inherit name config; };
    }
  ) (lib.filterAttrs (n: _: n != "formatSubagentAsMarkdown") llmLib.instructions.subagents);

  # Install SysinitSpec plugin for bidirectional beads sync
  sysinitSpecPlugin = pkgs.writeText "sysinit-spec.ts" (
    builtins.readFile ./opencode-plugins/sysinit-spec.ts
  );
in
{
  xdg.configFile = lib.mkMerge [
    {
      "opencode/opencode.json" = {
        text = builtins.toJSON opencodeConfig;
        force = true;
      };
    }
    {
      "opencode/AGENTS.md" = {
        text = defaultInstructions;
        force = true;
      };
    }
    {
      "opencode/plugins/sysinit-spec.ts" = {
        source = sysinitSpecPlugin;
        force = true;
      };
    }
    subagentFiles
  ];
}
