{ pkgs, config, ... }:

{
  # Minimal development environment for Lima VMs (NixOS)
  # Basic dev tools only - for lightweight projects

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ./base.nix
      ../modules/home/configurations/neovim
      ../modules/home/configurations/git
      ../modules/home/configurations/zsh
      ../modules/dev/home/shell/zellij
    ];

    home.packages = with pkgs; [
      # Essential CLI tools
      ripgrep
      fd
      bat
      eza
      jq
    ];
  };
}
