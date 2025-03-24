{ pkgs, lib, inputs, username, homeDirectory, config ? {}, ... }: {
  imports = [
    ./atuin/atuin.nix
    ./colima/colima.nix
    ./git/git.nix
    ./k9s/k9s.nix
    ./macchina/macchina.nix
    ./neovim/neovim.nix
    ./nushell/nushell.nix
    ./starship/starship.nix
    ./wezterm/wezterm.nix
    ./zsh/zsh.nix
    ./packages.nix
    ./config-extras.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    # Values passed from flake.nix will override these defaults
    username = username;
    homeDirectory = homeDirectory;
    
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "23.11";
    
    # Set PATH environment variables
    sessionVariables = {
      # Append all the required PATH directories
      PATH = "$HOME/.cargo/bin:$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:/usr/local/opt/cython/bin:$HOME/.local/bin:$HOME/.rvm/bin:$HOME/.govm/shim:$HOME/.krew/bin:$HOME/bin:$PATH";
    };
  };
  
  # Set XDG directories
  xdg = {
    enable = true;
    configHome = "${homeDirectory}/.config";
    dataHome = "${homeDirectory}/.local/share";
    cacheHome = "${homeDirectory}/.cache";
  };
  
  # Handle brewing completions through standard home-manager
  programs.zsh.enableCompletion = true;
  programs.zsh.completionInit = ''
    # Add Homebrew completions to fpath
    if [ -d "/opt/homebrew/share/zsh/site-functions" ]; then
      fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
    fi
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}