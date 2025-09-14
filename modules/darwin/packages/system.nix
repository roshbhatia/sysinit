{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Essential utilities that need to be available system-wide
    coreutils        # Provides readlink -m and other GNU utilities
    findutils        # find, xargs, etc.
    gnugrep          # GNU grep
    gnused           # GNU sed
    gawk             # GNU awk
    which            # which command

    # Development essentials
    git
    curl
    wget

    # Nix tools
    nix-output-monitor

    # System tools
    htop
    tree

    # Terminal essentials
    bat
    fd
    ripgrep

    # Shell
    zsh
    bash
  ];
}
