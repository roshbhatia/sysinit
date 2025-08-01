{
  pkgs,
  values,
  ...
}:
let
  additionalPackages = (values.nix.packages or [ ]);

  baseNixPackages = with pkgs; [
    _1password-cli
    actionlint
    alt-tab-macos
    ansible
    ansible-lint
    argc
    argocd
    asdf
    atuin
    awscli2
    bash-language-server
    bat
    caddy
    carapace
    carapace-bridge
    cargo-watch
    chafa
    checkmake
    colima
    coreutils
    deadnix
    delta
    delve
    discordo
    docker
    docker-compose-language-service
    docker-language-server
    duf
    fd
    figlet
    findutils
    fira-code
    fish
    fzf
    gettext
    gh
    gh-dash
    git
    git-filter-repo
    glow
    gnugrep
    gnupg
    go
    gopls
    go-task
    gum
    helm-ls
    htop
    imagemagick
    inshellisense
    jetbrains-mono
    jq
    jqp
    jq-lsp
    jsonld-cli
    k9s
    krew
    kubecolor
    kubectl
    kubernetes-helm
    kube-linter
    kustomize
    lazygit
    libgit2
    lnav
    lolcat
    luajit
    lua-language-server
    lynx
    markdownlint-cli
    markdownlint-cli2
    mermaid-cli
    mods
    nerd-fonts.hack
    nil
    nix-prefetch
    nix-prefetch-git
    nix-prefetch-github
    nix-prefetch-docker
    nix-search-cli
    nixd
    nixfmt-rfc-style
    nodePackages_latest.fkill-cli
    nodePackages_latest.jsonlint
    nodejs
    oh-my-posh
    ollama
    openssh
    pipx
    pkg-config
    proselint
    python311Full
    ripgrep
    rustup
    sad
    shellcheck
    socat
    sshpass
    statix
    stern
    stylua
    swift
    taplo
    terraform-ls
    terraform-lsp
    textlint
    tfsec
    tflint
    tflint-plugins.tflint-ruleset-aws
    tlrc
    tree
    typescript
    typescript-language-server
    uv
    vale
    vivid
    vscode-langservers-extracted
    watch
    weechat
    weechatScripts.wee-slack
    wget
    yamllint
    yaml-language-server
    yazi
    yarn
    yq
    zoxide
  ];

  allNixPackages = baseNixPackages ++ additionalPackages;
in
{
  home.packages = allNixPackages;
}
