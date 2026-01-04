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
      "gh*"
    ];

    docker = [
      "docker*"
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
      "darwin-rebuild*"
      "nh*"
      "nix*"
      "nix-instantiate*"
      "nix-prefetch*"
      "nix-shell*"
    ];

    utilities = [
      "bat*"
      "bd*"
      "cat*"
      "cd*"
      "date"
      "df*"
      "du*"
      "echo*"
      "env"
      "exa*"
      "eza*"
      "fd*"
      "find*"
      "grep*"
      "head*"
      "hostname"
      "less*"
      "ls*"
      "mkdir*"
      "more*"
      "pwd"
      "rg*"
      "tail*"
      "tree*"
      "uname*"
      "wc*"
      "which*"
      "whoami"
      "zoxide*"
    ];

    crossplane = [
      "crossplane*"
      "up*"
    ];

    serena = [
      "serena_check_onboarding_performed"
      "serena_find_file"
      "serena_find_referencing_symbols"
      "serena_find_symbol"
      "serena_get_current_config"
      "serena_get_symbols_overview"
      "serena_initial_instructions"
      "serena_jet_brains_find_referencing_symbols"
      "serena_jet_brains_find_symbol"
      "serena_jet_brains_get_symbols_overview"
      "serena_list_dir"
      "serena_list_memories"
      "serena_read_file"
      "serena_read_memory"
      "serena_search_for_pattern"
      "serena_summarize_changes"
      "serena_think_about_collected_information"
      "serena_think_about_task_adherence"
      "serena_think_about_whether_you_are_done"
      "serena_write_memory"
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
