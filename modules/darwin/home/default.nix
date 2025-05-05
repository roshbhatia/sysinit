{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  install = userConfig.install or {
    installToXdgConfigHome = [];
    installToHome = [];
  };

  extractDirectories = paths: lib.unique (map (entry: builtins.dirname entry.destination) paths);

  xdgConfigDirs = extractDirectories install.installToXdgConfigHome;
  homeFileDirs = extractDirectories install.installToHome;

  createEmptyDirs = dirs: lib.listToAttrs (map (dir: {
    name = dir;
    value = lib.mkForce {
      source = pkgs.runCommand "empty-dir-${lib.replaceStrings ["/"] ["-"] dir}" {} ''
        mkdir -p $out
      '';
    };
  }) dirs);

  emptyDirs = lib.recursiveUpdate
    (createEmptyDirs xdgConfigDirs)
    (createEmptyDirs homeFileDirs);

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
