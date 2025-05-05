{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  install = userConfig.install or {
    installToXdgConfigHome = [];
    installToHome = [];
  };

  xdgConfigAttrs = lib.listToAttrs (map (entry: {
    name = "${homeDirectory}/.config/${entry.destination}";
    value = {
      source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
      force = true;
      executable = entry.executable or false;
    };
  }) install.installToXdgConfigHome);

  homeFileAttrs = lib.listToAttrs (map (entry: {
    name = entry.destination;
    value = {
      source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
      force = true;
      executable = entry.executable or false;
    };
  }) install.installToHome);

  emptyDirs = {
    "${homeDirectory}/.config" = {
      source = pkgs.runCommand "empty-config-dir" {} ''
        mkdir -p $out
      '';
    };
    "${homeDirectory}/.config/zsh" = {
      source = pkgs.runCommand "empty-zsh-dir" {} ''
        mkdir -p $out
      '';
    };
    "${homeDirectory}/.config/zsh/bin" = {
      source = pkgs.runCommand "empty-zsh-bin-dir" {} ''
        mkdir -p $out
      '';
    };
    "${homeDirectory}/.config/zsh/extras" = {
      source = pkgs.runCommand "empty-zsh-extras-dir" {} ''
        mkdir -p $out
      '';
    };
  };
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
  home.file = lib.recursiveUpdate homeFileAttrs emptyDirs;
}
