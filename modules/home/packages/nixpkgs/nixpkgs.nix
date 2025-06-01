{
  pkgs,
  userConfig ? { },
  ...
}:

let
  additionalPackages = (userConfig.packages or [ ]);

  baseNixPackages = with pkgs; [
    ansible
    argocd
    atuin
    awscli
    bat
    caddy
    colima
    coreutils
    delta
    docker
    duf
    fd
    findutils
    fira-code
    fzf
    gettext
    gh
    git
    git-filter-repo
    glow
    gnugrep
    gnupg
    go
    go-task
    gum
    helm-ls
    htop
    jq
    jqp
    k9s
    keycastr
    kind
    kubecolor
    kubectl
    kustomize
    lazygit
    libgit2
    lnav
    luajit
    lynx
    nerd-fonts."m+"
    nerd-fonts.noto
    nerd-fonts.hack
    nerd-fonts.tinos
    nerd-fonts.lilex
    nerd-fonts.arimo
    nerd-fonts.agave
    nerd-fonts._3270
    nil
    nixd
    nixfmt-rfc-style
    nodejs
    oh-my-posh
    openssh
    ollama
    prettierd
    ripgrep
    shellcheck
    socat
    stern
    swift
    taplo
    tree
    watch
    wget
    yq
    zoxide
    yazi
  ];

  allNixPackages = baseNixPackages ++ additionalPackages;
in
{
  home.packages = allNixPackages;
}

