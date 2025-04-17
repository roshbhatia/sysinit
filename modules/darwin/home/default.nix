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
      cp -f "${srcPath}" "${destPath}"
      chmod 644 "${destPath}"
    '';
    
  # Generate installation script for all files
  installScript = lib.concatMapStrings installFile installFiles;
in {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./core/packages.nix
    ./environment/environment.nix
    ./wallpaper/wallpaper.nix

    ./npm/npm.nix
    ./pipx/pipx.nix

    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./nushell/nushell.nix

    ./git/git.nix
    ./neovim/neovim.nix
    ./vscode/vscode.nix
    
    ./colima/colima.nix
    ./k9s/k9s.nix

    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { 
      inherit inputs username homeDirectory; 
      userConfig = config; 
    };
    backupFileExtension = "backup";
    users.${username} = { 
      home = { inherit username homeDirectory; };
    };
  };

  system.activationScripts.postUserActivation.text = lib.mkIf (installFiles != []) ''
    echo "Installing configured files..."
    ${installScript}
  '';
}