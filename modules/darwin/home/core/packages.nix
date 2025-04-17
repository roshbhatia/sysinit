{ pkgs, lib, config, userConfig ? {}, ... }:

let
  # Get additional packages from userConfig
  additionalPackages = if userConfig ? packages && userConfig.packages ? additional
                      then userConfig.packages.additional
                      else [];

  # Core packages that should be available in all installations
  basePackages = with pkgs; [
    # Development tools
    atuin
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
    nodejs
    nodePackages.typescript
    openssh
    tree
    watch
    wget
    yq

    # Cloud and infrastructure
    awscli
    kind
    kustomize
    stern

    # macOS specific
    keycastr
    swift
  ];

  # Combine base and additional packages
  allPackages = basePackages ++ additionalPackages;
in
{
  # Install all packages
  home.packages = allPackages;

  # Add helpful message about installed packages
  home.activation.packageInfo = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "📦 Core packages installed:"
    echo "  Base packages: ${toString (map (p: p.name) basePackages)}"
    if [ ${toString (lib.length additionalPackages)} -gt 0 ]; then
      echo "  Additional packages: ${toString (map (p: p.name) additionalPackages)}"
    fi
  '';
}
