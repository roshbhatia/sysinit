{
  config,
  pkgs,
  lib,
  inputs,
  username,
  homeDirectory,
  userConfig ? { },
  ...
}:
let
  install =
    userConfig.install or {
      installToXdgConfigHome = [ ];
      installToHome = [ ];
    };

  extractDirectories = paths: lib.unique (map (entry: builtins.dirOf entry.destination) paths);

  xdgConfigDirs = extractDirectories install.installToXdgConfigHome;
  homeFileDirs = extractDirectories install.installToHome;

  createEmptyDirs =
    dirs:
    lib.listToAttrs (
      map (dir: {
        name = dir;
        value = lib.mkForce {
          source = pkgs.runCommand "empty-dir-${lib.replaceStrings [ "/" ] [ "-" ] dir}" { } ''
            mkdir -p $out
          '';
        };
      }) dirs
    );

  emptyDirs = lib.recursiveUpdate (createEmptyDirs xdgConfigDirs) (createEmptyDirs homeFileDirs);

  xdgConfigAttrs = lib.listToAttrs (
    map (entry: {
      name = "${homeDirectory}/.config/${entry.destination}";
      value = {
        source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
        force = true;
        executable = entry.executable or false;
      };
    }) install.installToXdgConfigHome
  );

  homeFileAttrs = lib.listToAttrs (
    map (entry: {
      name = entry.destination;
      value = {
        source = config.lib.file.mkOutOfStoreSymlink (toString entry.source);
        force = true;
        executable = entry.executable or false;
      };
    }) install.installToHome
  );
in
{
  xdg.configFile = xdgConfigAttrs;
  home.file = lib.recursiveUpdate homeFileAttrs emptyDirs;

  imports = [
    ../../lib/activation-compat.nix
    ./aider/aider.nix
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./git/git.nix
    ./k9s/k9s.nix
    ./macchina/macchina.nix
    ./neovim/neovim.nix
    ./omp/omp.nix
    ./wezterm/wezterm.nix
    ./zsh/zsh.nix

    ./core/packages.nix
    ./cargo/cargo.nix
    ./node/npm.nix
    ./node/yarn.nix
    ./python/pipx.nix
    ./python/uvx.nix
    ./go/go.nix
  ];
}

