{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  install = userConfig.install or {
    installToXdgConfigHome = [];
    installToHome = [];
  };

  xdgConfigAttrs = lib.listToAttrs (map (entry: {
    name = entry.name;
    value = {
      source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
      force = true;
    };
  }) install.installToXdgConfigHome);

  homeFileAttrs = lib.listToAttrs (map (entry: {
    name = entry.name;
    value = {
      source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
      force = true;
    };
  }) install.installToHome);
in {
  imports = [
    ./git/git.nix
    ./core/packages.nix
    ./cargo/cargo.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./go/go.nix  
    ./neovim/neovim.nix
    ./macchina/macchina.nix
    ./atuin/atuin.nix
    ./omp/omp.nix
    ./zsh/zsh.nix
    ./wezterm/wezterm.nix
    ./aider/aider.nix
    ./k9s/k9s.nix
    ./colima/colima.nix
    ./wallpaper/wallpaper.nix
  ];

  xdg.configFile = xdgConfigAttrs;
  home.file = homeFileAttrs;
}
