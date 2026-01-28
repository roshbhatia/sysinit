{
  lib,
  values,
}:
let
  flattenPermissions =
    perms: lib.lists.flatten (map (x: if builtins.isList x then x else [ x ]) perms);

  defaultServers = { };

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
  };

  allPermissions = flattenPermissions (builtins.attrValues permissions);
  allServers = defaultServers // values.llm.mcp.additionalServers or { };
in
{
  servers = allServers;
  inherit permissions;
  inherit allPermissions;
}
