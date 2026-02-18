{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # 1Password CLI (socket mounted from macOS to NixOS VM)
    _1password-cli

    # AI/Copilot tools (available everywhere)
    amp-cli
    crush
    cursor-cli
    github-copilot-cli
    opencode

    # Package/Build managers
    cachix

    # Security
    gnupg

    # Communication (terminal-based)
    discordo
    iamb

    # Additional shells
    fish

    # Lua runtime & libraries (for neovim, wezterm, hammerspoon configs)
    luajit
    lua54Packages.cjson

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
    deadnix
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
    statix
    textlint

    # Go development tools (previously installed via go install)
    delve
    ginkgo
    go-enum
    gofumpt
    gojsonstruct
    gomvp
    gotools # includes goimports
    gotestsum
    govulncheck
    json-to-struct
    mockgen
    reftools # includes fillstruct, fillswitch, fixplurals
    richgo

    # LSP servers for neovim
    awk-language-server
    bash-language-server
    cuelsp
    docker-compose-language-service
    docker-language-server
    gopls
    helm-ls
    jq-lsp
    lsp-ai
    lua-language-server
    nil
    nixd
    pyright
    simple-completion-language-server
    taplo
    typescript-language-server
    vale-ls
    vscode-langservers-extracted
    yaml-language-server

    # Formatters & Linters
    eslint
    golangci-lint
    nixfmt
    shellcheck
    shfmt
    stylua
    yamllint
  ];
}
