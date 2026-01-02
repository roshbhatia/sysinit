{
  lib,
  values,
}:

let
  flattenList = lists: lib.lists.flatten (map (x: if builtins.isList x then x else [ x ]) lists);

  defaultServers = {
    astgrep = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/ast-grep/ast-grep-mcp"
        "ast-grep-server"
      ];
      description = "Structural code search and refactoring with ast-grep. Provides AST-based pattern matching for semantic code search across multiple languages.";
    };
    nu = {
      command = "nu";
      args = [
        "--mcp"
      ];
      description = "Nushell MCP server for enhanced shell scripting assistance and command suggestions. A preferable alternative to standard shell tools.";
    };
    serena = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/oraios/serena"
        "serena"
        "start-mcp-server"
        "--enable-web-dashboard"
        "false"
      ];
      description = "Serena IDE assistant with AGENTS.md integration for project-aware coding assistance";
    };
    playwright = {
      command = "npx";
      args = [
        "playwriter@latest"
      ];
      description = "A Model Context Protocol (MCP) server that provides browser automation capabilities using Playwright. This server enables LLMs to interact with web pages through structured accessibility snapshots, bypassing the need for screenshots or visually-tuned models.";
    };
  };

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

  allPermissions = flattenList (builtins.attrValues permissions);

  allServers = defaultServers // values.llm.mcp.additionalServers or { };
in
{
  servers = allServers;
  inherit permissions;
  inherit allPermissions;
}
