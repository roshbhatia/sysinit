{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  installFiles = userConfig.install or [];
  
  installFile = { source, destination }:
    let
      srcPath = if lib.strings.hasPrefix "/" source
               then source
               else toString (inputs.self + "/${source}");
      destPath = toString destination;
    in ''
      echo "Installing file: ${destPath}"
      mkdir -p -m 755 "$(dirname "${destPath}")"
      rm -f "${destPath}"
      install -v "${srcPath}" "${destPath}"
      chmod 644 "${destPath}"
    '';
    
  installScript = lib.concatMapStrings installFile installFiles;
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

  home.activation.installFiles = lib.mkIf (installFiles != []) (
    lib.hm.dag.entryAfter ["writeBoundary" "makeBinExecutable" "neovimSetup" "aerospaceSetup" "pipxPackages" "npmPackages" "installExtensions"] ''
      echo "Installing config.nix specific files..."
      ${installScript}
    ''
  );
}