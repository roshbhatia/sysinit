{ pkgs, config, ... }:

{
  # Complete development environment for Lima VMs (NixOS)
  # Includes all dev tools, editors, and CLI utilities

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ./base.nix
      ../modules/home/configurations/neovim
      ../modules/home/configurations/helix.nix
      ../modules/home/configurations/git
      ../modules/home/configurations/fzf.nix
      ../modules/home/configurations/direnv.nix
      ../modules/home/configurations/zoxide.nix
      ../modules/home/configurations/bat.nix
      ../modules/home/configurations/eza.nix
      ../modules/home/configurations/fd.nix
      ../modules/home/configurations/ast-grep.nix
      ../modules/home/configurations/yazi
      ../modules/home/configurations/zsh
      ../modules/dev/home/shell/zellij
    ];

    home.packages = with pkgs; [
      # Dev toolchains
      nodejs
      python3
      rustc
      cargo
      go

      # CLI tools
      ripgrep
      fd
      bat
      eza
      delta
      jq
      yq

      # Build tools
      gnumake
      cmake

      # Container tools
      docker-compose
    ];
  };
}
