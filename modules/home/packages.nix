{
  lib,
  pkgs,
  values,
  ...
}:

let
  additionalPackages = values.nix.additionalPackages or [ ];

  # Custom scripts
  fzf-preview = pkgs.writeScriptBin "fzf-preview" (
    builtins.readFile ./configurations/utils/dev/fzf-preview.nu
  );

  # Core system utilities
  basePkgs =
    with pkgs;
    [
      coreutils
      curl
      findutils
      gettext
      gnugrep
      gnused
      jq
      socat
      watch
      wget
      which
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ sbarlua ];

  # Terminal and shell environments
  terminalPkgs = with pkgs; [
    atuin
    bash
    bashInteractive
    direnv
    fish
    macchina
    oh-my-posh
    tmux
    wezterm
    zoxide
    zsh
  ];

  # File management and navigation
  filePkgs = with pkgs; [
    duf
    fd
    fzf-preview
    ripgrep
    yazi
  ];

  # Git and version control
  gitPkgs = with pkgs; [
    delta
    diffnav
    gh
    gh-dash
    git
    git-crypt
    git-filter-repo
    lazygit
    libgit2
    meld
    sad
    tig
  ];

  # Container and Docker
  containerPkgs = with pkgs; [
    docker
    docker-buildx
    docker-color-output
    docker-compose
    docker-compose-language-service
    docker-credential-helpers
    docker-language-server
  ];

  # Kubernetes
  k8sPkgs = with pkgs; [
    argocd
    crossplane-cli
    helm-ls
    k9s
    krew
    kube-linter
    kubecolor
    kubectl
    kubernetes-helm
    kubernetes-zeitgeist
    kustomize
    stern
    upbound
  ];

  # Cloud and infrastructure
  cloudPkgs = with pkgs; [
    ansible
    ansible-lint
    awscli2
    copilot-cli
    terraform-ls
    tflint
    tflint-plugins.tflint-ruleset-aws
    tfsec
  ];

  # Programming languages and runtimes
  langPkgs = with pkgs; [
    cue
    go
    luajit
    nodejs_22
    python311
    rustc
    rustup
    typescript
    zig
  ];

  # Language servers
  lspPkgs = with pkgs; [
    awk-language-server
    bash-language-server
    copilot-language-server
    cuelsp
    eslint
    gopls
    jq-lsp
    lsp-ai
    lua-language-server
    nil
    openscad-lsp
    pyright
    shellcheck
    simple-completion-language-server
    typescript-language-server
    vale-ls
    vscode-langservers-extracted
    yaml-language-server
    zls
  ];

  # Linters and formatters
  linterPkgs = with pkgs; [
    checkmake
    codespell
    deadnix
    golangci-lint
    nixfmt-rfc-style
    proselint
    shfmt
    statix
    stylua
    taplo
    textlint
    yamllint
  ];

  # Build tools and package managers
  buildPkgs = with pkgs; [
    cargo-watch
    gnumake
    go-task
    pipx
    pkg-config
    uv
    yarn
  ];

  # Database
  databasePkgs = with pkgs; [
    postgresql17Packages.pgvector
    postgresql_17
  ];

  # Nix ecosystem
  nixPkgs = with pkgs; [
    cachix
    nh
    nix-output-monitor
    nix-prefetch
    nix-prefetch-docker
    nix-prefetch-git
    nix-prefetch-github
    nix-tree
    nix-your-shell
    nixd
  ];

  # CLI utilities and tools
  cliPkgs = with pkgs; [
    argc
    asciinema
    asciinema-agg
    ast-grep
    bv
    chafa
    crush
    cursor-cli
    devbox
    glow
    gum
    jqp
    jsonld-cli
    lua54Packages.cjson
    mods
    tlrc
    vivid
    yq
  ];

  # Project management
  projectPkgs = with pkgs; [
    jira-cli-go
    mermaid-cli
  ];

  # Security and credentials
  securityPkgs = with pkgs; [
    _1password-cli
    _1password-gui
    gnupg
    openssh
    sshpass
  ];

  # Fonts
  fontPkgs = with pkgs; [
    nerd-fonts.agave
    nerd-fonts.monaspace
  ];

  # Debugging
  debugPkgs = with pkgs; [
    delve
  ];

  # CAD and 3D modeling
  cadPkgs = with pkgs; [
    openscad
  ];

  allPackages =
    basePkgs
    ++ terminalPkgs
    ++ filePkgs
    ++ gitPkgs
    ++ containerPkgs
    ++ k8sPkgs
    ++ cloudPkgs
    ++ langPkgs
    ++ lspPkgs
    ++ linterPkgs
    ++ buildPkgs
    ++ databasePkgs
    ++ nixPkgs
    ++ cliPkgs
    ++ projectPkgs
    ++ securityPkgs
    ++ fontPkgs
    ++ debugPkgs
    ++ cadPkgs
    ++ additionalPackages;
in
{
  home.packages = allPackages;
}
