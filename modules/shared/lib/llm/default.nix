{
  lib,
}:

with lib;

let
  flattenList = lists: flatten (map (x: if isList x then x else [ x ]) lists);

  permissions = {
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

  allPermissions = flattenList (attrValues permissions);

  capitalizeFirst =
    str:
    let
      firstChar = substring 0 1 str;
      rest = substring 1 (-1) str;
    in
    (toUpper firstChar) + rest;

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
        // (optionalAttrs (server.headers or null != null) { inherit (server) headers; })
        // (optionalAttrs (server.timeout or null != null) { inherit (server) timeout; })
      else
        {
          type = "local";
          enabled = server.enabled or true;
          command = [ server.command ] ++ server.args;
        }
        // (optionalAttrs (server.env or { } != { }) { environment = server.env; })
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

  formatMcpForCrush =
    mcpServers:
    builtins.mapAttrs (
      _name: server:
      if (server.type or "local") == "http" then
        {
          type = "http";
          inherit (server) url;
        }
      else
        {
          type = "stdio";
          inherit (server) command;
          args = server.args or [ ];
        }
    ) mcpServers;

  formatMcpForGoose =
    mcpServers:
    builtins.mapAttrs (_name: server: {
      inherit (server) args;
      bundled = null;
      cmd = server.command;
      description = server.description or "";
      enabled = server.enabled or true;
      env_keys = [ ];
      envs = server.env or { };
      name = capitalizeFirst (substring 0 1 name) + substring 1 (stringLength name) name;
      timeout = 300;
      type = "stdio";
    }) mcpServers;

  formatPermissionsForCursor = _perms: map (cmd: "Shell(${cmd})") allPermissions;

  formatPermissionsForCopilot = _perms: {
    allow = map (cmd: replaceStrings [ "*" ] [ "" ] cmd) allPermissions;
    deny = [ ];
  };

  formatPermissionsForGoose = _perms: {
    shell = {
      allow = map (cmd: replaceStrings [ "*" ] [ ".*" ] cmd) allPermissions;
      deny = [ ];
    };
  };

  formatPermissionsForAmp = _perms: [
    {
      tool = "Bash";
      matches = {
        cmd = "*git commit*";
      };
      action = "ask";
    }
    {
      tool = "Bash";
      matches = {
        cmd = [
          "*git status*"
          "*git diff*"
          "*git log*"
          "*git show*"
        ];
      };
      action = "allow";
    }
    {
      tool = "mcp__*";
      action = "allow";
    }
    {
      tool = "*";
      action = "ask";
    }
  ];

  formatLspForOpencode =
    lspCfg:
    builtins.mapAttrs (
      _name: lspCfg:
      let
        cmd =
          if lspCfg ? command then
            if builtins.isList lspCfg.command then lspCfg.command else [ lspCfg.command ]
          else
            [ ];
      in
      {
        command = cmd ++ (lspCfg.args or [ ]);
        extensions = lspCfg.extensions or [ ];
      }
    ) lspCfg;

  formatLspForCrush =
    lspCfg:
    builtins.mapAttrs (
      _name: lsp:
      if lsp ? command then
        {
          command = if builtins.isList lsp.command then head lsp.command else lsp.command;
          enabled = true;
        }
      else
        {
          enabled = false;
        }
    ) lspCfg;

in
{
  inherit
    permissions
    formatMcpForClaude
    formatMcpForOpencode
    formatMcpForAmp
    formatMcpForCrush
    formatMcpForGoose
    formatPermissionsForCursor
    formatPermissionsForCopilot
    formatPermissionsForGoose
    formatPermissionsForAmp
    formatLspForOpencode
    formatLspForCrush
    allPermissions
    ;
}
