{ pkgs, config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../profiles/base.nix
      ../../modules/home/configurations/neovim
      ../../modules/home/configurations/git
      ../../modules/home/configurations/zsh
      ../../modules/dev/home/shell/zellij
    ];

    home.packages = with pkgs; [
      ripgrep
      fd
      bat
      eza
      jq
    ];
  };
}
