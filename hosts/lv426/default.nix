{ pkgs, config, ... }:

{
  imports = [
    ../../modules/darwin/configurations/aerospace.nix
    ../../modules/darwin/configurations/borders.nix
    ../../modules/darwin/configurations/sketchybar.nix
    ../../modules/darwin/configurations/stylix.nix
    ../../modules/darwin/configurations/desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../modules/desktop/home/ghostty
      ../../modules/home/configurations/zsh
      ../../modules/home/configurations/git
      ../../modules/darwin/home/firefox.nix
    ];

    home.packages = with pkgs; [
      curl
      wget
      unzip
      zip
      htop
      ripgrep
      fd
      bat
      eza
      gh
    ];

    programs.home-manager.enable = true;
  };
}
