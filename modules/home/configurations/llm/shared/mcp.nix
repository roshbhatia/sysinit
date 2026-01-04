{
  lib,
  values,
}:
let
  flattenPermissions =
    perms: lib.lists.flatten (map (x: if builtins.isList x then x else [ x ]) perms);

  serenaConfig = import ./serena.nix { inherit lib; };

  defaultServers = {
    serena = serenaConfig.server;
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
    serena = serenaConfig.serenaAllowedTools;
  };

  allPermissions = flattenPermissions (builtins.attrValues permissions);
  allServers = defaultServers // values.llm.mcp.additionalServers or { };
in
{
  servers = allServers;
  inherit permissions;
  inherit allPermissions;
}
