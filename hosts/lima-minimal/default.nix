{ pkgs, config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../modules/home/configurations/neovim
      ../../modules/home/configurations/git
      ../../modules/home/configurations/zsh
      ../../modules/dev/home/shell/zellij
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
      jq
    ];

    programs.home-manager.enable = true;
  };
}
