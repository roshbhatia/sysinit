{
  lib,
  values,
}:
let
  flattenPermissions =
    perms: lib.lists.flatten (map (x: if builtins.isList x then x else [ x ]) perms);

  serenaExcludedTools = [
    "serena_jet_brains_find_referencing_symbols"
    "serena_jet_brains_find_symbol"
    "serena_jet_brains_get_symbols_overview"
    "serena_delete_memory"
    "serena_read_memory"
    "serena_write_memory"
    "serena_list_memories"
    "serena_edit_memory"
    "serena_insert_after_symbol"
    "serena_insert_at_line"
    "serena_insert_before_symbol"
    "serena_replace_lines"
    "serena_replace_content"
    "serena_replace_symbol_body"
    "serena_delete_lines"
    "serena_create_text_file"
    "serena_remove_project"
  ];

  serenaAllowedTools = [
    "serena_get_symbols_overview"
    "serena_find_symbol"
    "serena_find_referencing_symbols"
    "serena_find_file"
    "serena_search_for_pattern"
    "serena_list_dir"
  ];

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
        "--excluded-tools"
        (lib.strings.concatStringsSep "," serenaExcludedTools)
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
    filesystem = [
      "ls*"
      "cat*"
      "find*"
      "grep*"
      "fd*"
      "rg*"
    ];
    nix = [
      "nh*"
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
      "bd*"
    ];
    crossplane = [
      "crossplane*"
      "up*"
    ];
    serena = serenaAllowedTools;
  };

  allPermissions = flattenPermissions (builtins.attrValues permissions);
  allServers = defaultServers // values.llm.mcp.additionalServers or { };
in
{
  servers = allServers;
  inherit permissions;
  inherit allPermissions;
}
