{ pkgs, config, ... }:

{
  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
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
