{
  lib,
  values,
}:

let
  flattenPermissions =
    perms: lib.lists.flatten (map (x: if builtins.isList x then x else [ x ]) perms);

  defaultServers = {
    serena = {
      command = "uvx";
      args = [
        "--from"
        "git+https://github.com/oraios/serena"
        "serena"
        "start-mcp-server"
        "--enable-web-dashboard"
        "false"
        "--context"
        "claude-code"
      ];
      description = "Serena IDE assistant with AGENTS.md integration for project-aware coding assistance";
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

    # For reading/exploring project structure and code
    filesystem = [
      "ls*"
      "cat*"
      "find*"
      "grep*"
      "fd*"
      "rg*"
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
      "bd*"
    ];

    crossplane = [
      "crossplane --version"
      "crossplane xpkg*"
      "crossplane beta trace*"
      "crossplane beta validate*"
    ];

    # MCP servers for code understanding
    serena = [
      "serena_get_symbols_overview"
      "serena_find_symbol"
      "serena_find_referencing_symbols"
      "serena_find_file"
      "serena_search_for_pattern"
      "serena_list_dir"
    ];
  };

  allPermissions = flattenPermissions (builtins.attrValues permissions);

  allServers = defaultServers // values.llm.mcp.additionalServers or { };
in
{
  servers = allServers;
  inherit permissions;
  inherit allPermissions;
}
