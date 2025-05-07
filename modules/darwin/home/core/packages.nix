{ pkgs, lib, config, userConfig ? {}, ... }:

let
  # User-defined additional packages
  additionalPackages = if userConfig ? packages && userConfig.packages ? additional
                      then userConfig.packages.additional
                      else [];

  # Base packages for home-manager
  baseHomePackages = with pkgs; [
    atuin
    awscli
    bat
    coreutils
    docker
    fzf
    gettext
    gh
    git
    go
    gnugrep
    gnupg
    htop
    jq
    jqp
    keycastr
    kind
    kustomize
    nixfmt-rfc-style
    nodejs
    openssh
    stern
    swift
    tree
    watch
    wget
    yq
  ];

  # Combine all packages for home-manager
  allHomePackages = baseHomePackages ++ additionalPackages;
in
{
  # Define the home packages
  home.packages = allHomePackages;
}
