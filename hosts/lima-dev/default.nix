{ pkgs, config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
    home.packages = with pkgs; [
      curl
      wget
      unzip
      zip
      htop
      nodejs
      python3
      rustc
      cargo
      go
      ripgrep
      fd
      bat
      eza
      delta
      jq
      yq
      gnumake
      cmake
      docker-compose
    ];

    programs.home-manager.enable = true;
  };
}
