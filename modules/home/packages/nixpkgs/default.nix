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
    builtins.readFile ../../../home/configurations/utils/dev/fzf-preview.nu
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
      lua54Packages.cjson
      socat
      watch
      wget
      which
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [ sbarlua ];

  # Terminal and shells
  terminalPkgs = with pkgs; [
    atuin
    bash
    bashInteractive
    direnv
    macchina
    oh-my-posh
    tmux
    wezterm
    zoxide
    zsh
  ];

  # Development tools
  devPkgs = with pkgs; [
    argc
    asciinema
    asciinema-agg
    ast-grep
    cachix
    caddy
    chafa
    crush
    delta
    devbox
    diffnav
    duf
    fd
    glow
    gnumake
    gum
    lazygit
    libgit2
    meld
    mods
    ripgrep
    sad
    tig
    tlrc
    vivid
    yazi
    yq
  ];

  # Git and version control
  gitPkgs = with pkgs; [
    gh
    gh-dash
    git
    git-crypt
    git-filter-repo
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

  # Kubernetes tools
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

  # Programming languages
  langPkgs = with pkgs; [
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
    vectorcode
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
    go-task
    pkg-config
    pipx
    uv
    yarn
  ];

  # Database
  databasePkgs = with pkgs; [
    postgresql17Packages.pgvector
    postgresql_17
  ];

  # Nix tools
  nixPkgs = with pkgs; [
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

  # Project management and collaboration
  projectPkgs = with pkgs; [
    # bv
    jira-cli-go
    mermaid-cli
  ];

  # Documentation and utilities
  docPkgs = with pkgs; [
    cursor-cli
    jqp
    jsonld-cli
  ];

  # Security and password management
  securityPkgs = with pkgs; [
    gnupg
    openssh
    sshpass
    _1password-cli
    _1password-gui
  ];

  # Fonts
  fontPkgs = with pkgs; [
    nerd-fonts.monaspace
    nerd-fonts.agave
  ];

  # Debug tools
  debugPkgs = with pkgs; [
    delve
    fzf-preview
  ];

  # CAD tools
  cadPkgs = with pkgs; [
    openscad
  ];

  allPackages =
    basePkgs
    ++ terminalPkgs
    ++ devPkgs
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
    ++ projectPkgs
    ++ docPkgs
    ++ securityPkgs
    ++ fontPkgs
    ++ debugPkgs
    ++ cadPkgs
    ++ additionalPackages
    ++ [ fzf-preview ];
in
{
  home.packages = allPackages;
}
