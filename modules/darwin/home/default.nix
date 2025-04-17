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
    ./environment/environment.nix
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

  home.activation.installFiles = lib.mkIf (installFiles != []) (
    lib.hm.dag.entryAfter ["writeBoundary"] ''
      echo "Installing config.nix specific files..."
      ${installScript}
    ''
  );
}