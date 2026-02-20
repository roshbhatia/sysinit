{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core Utilities
    coreutils
    curl
    wget
    findutils
    gettext
    gnugrep
    gnused
    gnumake
    pkg-config
    which
    tree
    unzip
    zip
    watch
    socat
    sshpass
    openssh
    gnupg
    bat
    eza
    fd
    ripgrep
    jq
    jqp
    yq-go
    duf
    htop
    glow
    tokei
    chafa
    imagemagick
    _1password-cli

    # Git
    git
    gh
    delta
    git-crypt
    git-filter-repo
    libgit2

    # Nix
    nixd
    nil
    nixfmt
    statix
    deadnix
    cachix
    nix-output-monitor
    nix-tree
    nix-your-shell
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-git
    nix-prefetch-github

    # Bash
    bash-language-server
    shellcheck
    shfmt
    gum
    grc

    # Go
    go
    gopls
    delve
    golangci-lint
    gofumpt
    gotestsum
    govulncheck
    ginkgo
    go-enum
    gomvp
    gotools
    mockgen
    reftools
    richgo

    # Python
    python311
    uv
    pipx
    pyright

    # Rust & Zig
    rustup
    cargo-watch
    zig

    # Node & Web
    nodejs_22
    bun
    typescript
    yarn
    eslint
    typescript-language-server
    vscode-langservers-extracted

    # Lua
    luajit
    hererocks
    lua-language-server
    stylua
    lua54Packages.cjson

    # Kubernetes
    kubectl
    kubecolor
    kubectx
    k9s
    stern
    kubernetes-helm
    helm-ls
    kustomize
    kind
    krew
    kube-linter
    kubernetes-zeitgeist

    # Docker
    docker
    docker-compose
    docker-buildx
    docker-color-output
    docker-compose-language-service
    docker-language-server

    # Infrastructure & IaC
    awscli2
    argocd
    crossplane-cli
    upbound
    terraform-ls
    tflint
    tfsec
    ansible
    ansible-lint
    cue
    cuelsp

    # AI & Editors
    claude-code
    github-copilot-cli
    copilot-language-server
    cursor-cli
    lsp-ai
    amp-cli
    crush
    opencode
    openspec

    # Config & Misc Dev
    taplo
    yaml-language-server
    yamllint
    awk-language-server
    jq-lsp
    simple-completion-language-server
    ast-grep
    codespell
    proselint
    textlint
    devbox
    go-task
    meld
    sad
  ];
}
