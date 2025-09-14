{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    bash
    bat
    coreutils
    curl
    fd
    findutils
    gawk
    git
    gnugrep
    gnused
    htop
    nix-output-monitor
    ripgrep
    tree
    wget
    which
    zsh
  ];

  environment.variables.PATH = [
    "${pkgs.coreutils}/bin"
    "${pkgs.findutils}/bin"
    "$PATH"
  ];
}
