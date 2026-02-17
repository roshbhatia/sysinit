{ pkgs, config, ... }:

{
  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      ../../profiles/base.nix
      ../../modules/home/configurations/neovim
      ../../modules/home/configurations/helix.nix
      ../../modules/home/configurations/git
      ../../modules/home/configurations/fzf.nix
      ../../modules/home/configurations/direnv.nix
      ../../modules/home/configurations/zoxide.nix
      ../../modules/home/configurations/bat.nix
      ../../modules/home/configurations/eza.nix
      ../../modules/home/configurations/fd.nix
      ../../modules/home/configurations/ast-grep.nix
      ../../modules/home/configurations/yazi
      ../../modules/home/configurations/zsh
      ../../modules/dev/home/shell/zellij
    ];

    home.packages = with pkgs; [
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
  };
}
