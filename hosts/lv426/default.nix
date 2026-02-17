{ pkgs, config, ... }:

{
  imports = [
    ../../profiles/desktop.nix
  ];

  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../profiles/base.nix
      ../../modules/desktop/home/ghostty
      ../../modules/home/configurations/zsh
      ../../modules/home/configurations/git
      ../../modules/darwin/home/firefox.nix
    ];

    home.packages = with pkgs; [
      ripgrep
      fd
      bat
      eza
      gh
    ];
  };
}
