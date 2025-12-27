{
  formatLspForOpencode =
    lspConfig:
    builtins.mapAttrs (
      _name: lsp:
      let
        cmd =
          if lsp ? command then if builtins.isList lsp.command then lsp.command else [ lsp.command ] else [ ];
      in
      {
        command = cmd ++ (lsp.args or [ ]);
        extensions = lsp.extensions or [ ];
      }
    ) lspConfig;

  formatMcpForOpencode =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "remote";
          enabled = server.enabled or true;
          inherit (server) url;
        }
        // (if (server.headers or null) != null then { inherit (server) headers; } else { })
        // (if (server.timeout or null) != null then { inherit (server) timeout; } else { })
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
        }
        // (if (server.env or { }) != { } then { environment = server.env; } else { })
    ) mcpServers;

  formatMcpForGoose =
    lib: mcpServers:
    lib.mapAttrs (name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name = lib.strings.toUpper (lib.substring 0 1 name) + lib.substring 1 (lib.stringLength name) name;
      timeout = 300;
      type = "stdio";
    }) mcpServers;

  formatMcpForClaude =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
          description = server.description or "";
          enabled = server.enabled or true;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
          description = server.description or "";
          enabled = server.enabled or true;
          env = server.env or { };
        }
    ) mcpServers;

  formatMcpForAmp =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          inherit (server) url;
        }
      else
        {
          inherit (server) command;
          inherit (server) args;
          env = server.env or { };
        }
    ) mcpServers;

  # Common shell permissions configuration
  commonShellPermissions = {
    git = [
      "git status"
      "git log*"
      "git diff*"
      "git show*"
      "git branch*"
      "git remote*"
      "git ls-files*"
      "git ls-remote*"
      "git describe*"
      "git rev-parse*"
    ];

    github = [
      "gh auth status"
      "gh repo view*"
      "gh repo list*"
      "gh pr list*"
      "gh pr view*"
      "gh pr checks*"
      "gh issue list*"
      "gh issue view*"
      "gh run list*"
      "gh run view*"
      "gh api*"
    ];

    docker = [
      "docker ps*"
      "docker images*"
      "docker inspect*"
      "docker logs*"
      "docker version"
      "docker info"
    ];

    kubernetes = [
      "kubectl get*"
      "kubectl describe*"
      "kubectl logs*"
      "kubectl version"
      "kubectl cluster-info"
      "kubectl config view"
      "kubectl config current-context"
      "kubectl config get-contexts"
      "kubectl api-resources"
      "kubectl api-versions"
      "kubectl explain*"
      "kubectl top*"
    ];

    nix = [
      "nix-shell --run*"
      "nix eval*"
      "nix show-config"
      "nix search*"
      "nix flake show*"
      "nix flake metadata*"
      "nix flake check*"
      "nix build --dry-run*"
      "nix-instantiate*"
      "nix-search*"
    ];

    darwin = [
      "darwin-rebuild switch*"
      "darwin-rebuild build*"
      "darwin-rebuild check*"
    ];

    navigation = [
      "zoxide query*"
      "z *"
      "zi*"
      "fd*"
      "rg*"
      "ripgrep*"
    ];

    utilities = [
      "pwd"
      "ls*"
      "cat*"
      "grep*"
      "find*"
      "which*"
      "env"
      "echo*"
      "tree*"
      "bat*"
      "eza*"
      "exa*"
      "head*"
      "tail*"
      "less*"
      "more*"
      "wc*"
      "du*"
      "df*"
      "uname*"
      "hostname"
      "date"
      "whoami"
      "cd*"
      "mkdir*"
      "make*"
    ];

    crossplane = [
      "crossplane --version"
      "crossplane xpkg*"
      "crossplane beta trace*"
      "crossplane beta validate*"
    ];
  };

  # Format permissions for OpenCode
  formatPermissionsForOpencode =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      # Convert list to attribute set for OpenCode format
      toAttrSet =
        list:
        builtins.listToAttrs (
          map (cmd: {
            name = cmd;
            value = "allow";
          }) list
        );
    in
    toAttrSet allPerms;

  # Format permissions for Cursor
  formatPermissionsForCursor =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      # Convert to Cursor's Shell() format, removing wildcards
      toCursorFormat =
        cmd:
        let
          cleanCmd = builtins.replaceStrings [ "*" ] [ "" ] cmd;
        in
        "Shell(${cleanCmd})";
    in
    map toCursorFormat allPerms;

  # Format permissions for GitHub Copilot CLI
  formatPermissionsForCopilotCli =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      # Copilot CLI uses patterns without wildcards for matching
      # Format: list of command patterns that will be allowed
      cleanCmd = cmd: builtins.replaceStrings [ "*" ] [ "" ] cmd;
    in
    {
      allow = map cleanCmd allPerms;
      deny = [ ];
    };

  # Format permissions for Goose
  # Goose uses a shell approval system with regex patterns
  formatPermissionsForGoose =
    perms:
    let
      allPerms =
        perms.git
        ++ perms.github
        ++ perms.docker
        ++ perms.kubernetes
        ++ perms.nix
        ++ perms.darwin
        ++ perms.navigation
        ++ perms.utilities
        ++ perms.crossplane;

      # Goose permissions format: { command = { allow = ["pattern"]; deny = []; }; }
      # Convert wildcards to regex patterns
      toRegexPattern = cmd: builtins.replaceStrings [ "*" ] [ ".*" ] cmd;
    in
    {
      shell = {
        allow = map toRegexPattern allPerms;
        deny = [ ];
      };
    };

  gooseBuiltinExtensions = {
    autovisualiser = {
      available_tools = [ ];
      bundled = true;
      description = null;
      display_name = "Auto Visualiser";
      enabled = true;
      name = "autovisualiser";
      timeout = 300;
      type = "builtin";
    };
    computercontroller = {
      available_tools = [
        "browser_action"
        "computer_use"
      ];
      bundled = true;
      display_name = "Computer Controller";
      enabled = true;
      name = "computercontroller";
      timeout = 300;
      type = "builtin";
    };
    developer = {
      available_tools = [
        "text_editor"
        "shell"
        "analyze"
        "screen_capture"
        "image_processor"
      ];
      bundled = true;
      display_name = "Developer";
      enabled = true;
      name = "developer";
      timeout = 300;
      type = "builtin";
    };
  };
}
