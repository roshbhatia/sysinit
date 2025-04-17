{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? packages && userConfig.packages ? additional
                      then userConfig.packages.additional
                      else [];

  basePackages = with pkgs; [
    atuin
    awscli
    bat
    coreutils
    docker
    fzf
    gettext
    gh
    git
    gnugrep
    gnupg
    go
    gopls
    htop
    jq
    jqp
    keycastr
    kind
    kustomize
    nodejs
    nodePackages.typescript
    openssh
    stern
    swift
    tree
    watch
    wget
    yq
  ];

  allPackages = basePackages ++ additionalPackages;
in
{
  home.packages = allPackages;
}
