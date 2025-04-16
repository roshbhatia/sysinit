{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: {
  imports = [
    # Core system configuration
    ./core/packages.nix
    ./environment/environment.nix
    ./wallpaper/wallpaper.nix

    # Package managers and tools
    ./npm/npm.nix
    ./pipx/pipx.nix

    # Shell and environment
    ./zsh/zsh.nix
    ./atuin/atuin.nix
    ./nushell/nushell.nix

    # Development tools
    ./git/git.nix
    ./neovim/neovim.nix
    ./vscode/vscode.nix
    
    # Container and cloud tools
    ./colima/colima.nix
    ./k9s/k9s.nix

    # System tools and UI
    ./aerospace/aerospace.nix
    ./macchina/macchina.nix
    ./wezterm/wezterm.nix
    
    # Help and documentation
    ./help/help.nix
  ];

  # Enable home-manager
  programs.home-manager.enable = true;

  # Basic home configuration
  home = {
    username = username;
    homeDirectory = homeDirectory;
    stateVersion = "23.11";
  };
}