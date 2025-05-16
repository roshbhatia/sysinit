{
  pkgs,
  lib,
  config,
  userConfig ? { },
  ...
}:

let
  additionalPackages =
    if userConfig ? packages && userConfig.packages ? additional then
      userConfig.packages.additional
    else
      [ ];

  baseHomePackages = with pkgs; [
    ansible
    argocd
    atuin
    awscli
    bat
    caddy
    colima
    coreutils
    docker
    eza
    fd
    findutils
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
    nil
    nixfmt-rfc-style
    nodejs
    nushell
    oh-my-posh
    openssh
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

  allHomePackages = baseHomePackages ++ additionalPackages;
in
{
  home.packages = allHomePackages;
}
