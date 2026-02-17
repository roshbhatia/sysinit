{ pkgs, config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
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
      jq
    ];

    programs.home-manager.enable = true;
  };
}
