{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: 
let
  installFiles = userConfig.install or [];
  
  # Function to install a single file
  installFile = { source, destination }:
    let
      srcPath = if lib.strings.hasPrefix "/" source
               then source
               else toString (inputs.self + "/${source}");
      destPath = toString destination;
    in ''
      echo "Installing file: ${destPath}"
      mkdir -p "$(dirname "${destPath}")"
      ln -s "${srcPath}" "${destPath}"
    '';
    
  # Generate installation script for all files
  installScript = lib.concatMapStrings installFile installFiles;
in {
  imports = [
    ./core/packages.nix
    ./environment/environment.nix
    ./wallpaper/wallpaper.nix
    ./git/git.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./colima/colima.nix  # Added Colima module import

    ./neovim/neovim.nix
    ./vscode/vscode.nix
    
    ./k9s/k9s.nix

    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
  ];

  home.activation.installFiles = lib.mkIf (installFiles != []) (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Installing configured files..."
      ${installScript}
    ''
  );
}