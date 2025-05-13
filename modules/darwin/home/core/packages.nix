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
    atuin
    awscli
    bat
    coreutils
    docker
    findutils
    fzf
    gettext
    gh
    git
    gnugrep
    gnupg
    go
    htop
    jq
    jqp
    k9s
    keycastr
    kind
    kustomize
    nil
    nixfmt-rfc-style
    nixfmt-rfc-style
    nodejs
    nushell
    oh-my-posh
    openssh
    stern
    swift
    tree
    watch
    wget
    yq
    zoxide
  ];

  allHomePackages = baseHomePackages ++ additionalPackages;
in
{
  home.packages = allHomePackages;
}
