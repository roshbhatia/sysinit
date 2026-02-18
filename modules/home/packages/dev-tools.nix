{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # 1Password CLI (socket mounted from macOS to NixOS VM)
    _1password-cli

    # AI/Copilot tools (available everywhere)
    amp-cli
    claude-code
    crush
    cursor-cli
    github-copilot-cli
    opencode
    openspec

    # Package/Build managers
    cachix

    # Security
    gnupg

    # Docker CLI (shares socket from macOS Colima)
    docker
    docker-buildx
    docker-color-output
    docker-compose
    docker-credential-helpers

    # Kubernetes
    k9s
    kind
    krew
    kube-linter
    kubecolor
    kubectl
    kubectx
    kubernetes-helm
    kubernetes-zeitgeist
    kustomize
    stern

    # Infrastructure as Code
    ansible
    ansible-lint
    argocd
    crossplane-cli
    cue
    devbox
    open-policy-agent
    terraform-ls
    tflint
    tflint-plugins.tflint-ruleset-aws
    tfsec
    upbound

    # Cloud tools
    awscli2

    # Build tools
    gnumake
    pkg-config

    # Code tools
    ast-grep
    checkmake
    codespell
    copilot-language-server
    diffnav
    go-task
    meld
    mermaid-cli
    nix-output-monitor
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-git
    nix-prefetch-github
    nix-tree
    proselint
    sad
    socat
    sshpass
    textlint
  ];
}
