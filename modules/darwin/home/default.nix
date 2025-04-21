{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  installFiles = userConfig.install or [];

  # Convert install entries to home.file and xdg.configFile attrs
  fileAttrs = lib.foldl (acc: entry:
    let
      srcPath = if lib.strings.hasPrefix "/" entry.source
                then entry.source
                else toString (inputs.self + "/${entry.source}");
      relPath = lib.removePrefix "/Users/${username}/" entry.destination;
      isConfig = lib.hasPrefix ".config/" relPath;
      configPath = lib.removePrefix ".config/" relPath;
      homePath = relPath;
      isExecutable = lib.strings.hasInfix "/bin/" entry.destination
                    || lib.strings.hasSuffix ".sh" entry.source 
                    || lib.strings.hasSuffix ".expect" entry.source
                    || !(lib.strings.hasInfix "." entry.source);
      fileAttrs = {
        source = srcPath;
        executable = isExecutable;
      };
    in
    if isConfig
    then acc // { xdg.configFiles.${configPath} = fileAttrs; }
    else acc // { homeFiles.${homePath} = fileAttrs; }
  ) { xdg.configFiles = {}; homeFiles = {}; } installFiles;
in {
  imports = [
    ./core/packages.nix
    ./wallpaper/wallpaper.nix
    ./git/git.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./go/go.nix
    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./neovim/neovim.nix
    ./k9s/k9s.nix
    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
  ];

  
  # Add config files to xdg.configFile
  xdg.configFile = fileAttrs.xdg.configFiles;

  # Add files to home.file
  home.file = fileAttrs.homeFiles;
}