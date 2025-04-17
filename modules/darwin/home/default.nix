{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: {
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
}