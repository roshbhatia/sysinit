{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Core utilities
    coreutils
    curl
    findutils
    gettext
    gnugrep
    gnused
    httpie
    openssh
    tree
    unzip
    watch
    wget
    which
    zip

    # Text processing & search
    bat
    eza
    fd
    jq
    jqp
    ripgrep
    yq-go

    # System monitoring
    duf
    htop

    # Git tools
    delta
    gh
    git
    git-crypt
    git-filter-repo
    libgit2

    # Shell essentials
    gum
    nix-your-shell

    # Terminal utilities
    chafa
    glow
    imagemagick
    tokei

    # 1Password CLI (socket mounted from macOS to NixOS VM)
    _1password-cli

    # AI/Copilot tools
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
    terraform-ls
    tflint
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

    # Language version managers
    rustup # Rust toolchain manager
    uv # Python version/package manager
    pipx # Python app installer

    # Go
    go
    delve
    ginkgo
    go-enum
    gofumpt
    gomvp
    gotools # includes goimports
    gopls
    gotestsum
    govulncheck
    mockgen
    reftools # includes fillstruct, fillswitch, fixplurals
    richgo
    golangci-lint

    # JavaScript/TypeScript/Node
    bun
    nodejs_22
    typescript
    yarn
    eslint
    typescript-language-server

    # Python
    python311
    pyright

    # Lua (for neovim, wezterm, hammerspoon configs)
    hererocks
    luajit
    lua54Packages.cjson
    lua-language-server
    stylua

    # Rust
    cargo-watch

    # Nix
    nil
    nixd
    nixfmt
    statix
    deadnix

    # Shell/Bash
    bash-language-server
    shellcheck
    shfmt

    # Markup/Config languages
    taplo # TOML
    yaml-language-server
    yamllint

    # DevOps/Infrastructure languages
    cuelsp
    helm-ls

    # Docker
    docker-compose-language-service
    docker-language-server

    # General/Multi-language LSP servers
    awk-language-server
    jq-lsp
    lsp-ai
    simple-completion-language-server
    vale-ls
    vscode-langservers-extracted # HTML, CSS, JSON, ESLint
  ];
}
