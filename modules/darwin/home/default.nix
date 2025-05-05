{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  installFiles = userConfig.install or [];

  # Convert install entries to home.file and xdg.configFile attrs
  fileAttrs = lib.foldl (acc: entry:
    let
      srcPath = toString entry.source;
      relPath = lib.removePrefix "/Users/${username}/" entry.destination;
      isConfig = lib.hasPrefix ".config/" relPath;
      configPath = lib.removePrefix ".config/" relPath;
      homePath = relPath;
      isExecutable = lib.hasInfix "/bin/" entry.destination
                   || lib.hasSuffix ".sh" srcPath
                   || lib.hasSuffix ".expect" srcPath;
      attrs = {
        source = srcPath;
        executable = isExecutable;
        force = true;
        mkOutOfStoreSymlink = "true";
      };
    in
    if isConfig
    then acc // { xdg.configFiles.${configPath} = attrs; }
    else acc // { homeFiles.${homePath} = attrs; }
  ) { xdg.configFiles = {}; homeFiles = {}; } installFiles;
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

  xdg.configFile = fileAttrs.xdg.configFiles;
  home.file = fileAttrs.homeFiles;
}
