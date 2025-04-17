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
    in
    if isConfig
    then acc // { xdg.configFiles.${configPath} = { source = srcPath; }; }
    else acc // { homeFiles.${homePath} = { source = srcPath; }; }
  ) { xdg.configFiles = {}; homeFiles = {}; } installFiles;
in {
  imports = [
    ./core/packages.nix
    ./wallpaper/wallpaper.nix
    ./git/git.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./neovim/neovim.nix
    ./vscode/vscode.nix
    ./k9s/k9s.nix
    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
  ];

  home.sessionVariables = {    
    # XDG Base Directory
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
        
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
  
  home.sessionPath = [
    "/usr/bin"
    "/usr/sbin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "$HOME/.local/bin"
    "$HOME/bin"
  ];

  # Add config files to xdg.configFile
  xdg.configFile = fileAttrs.xdg.configFiles;

  # Add files to home.file
  home.file = fileAttrs.homeFiles;
}