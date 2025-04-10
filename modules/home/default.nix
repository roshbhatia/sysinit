{ config, pkgs, lib, inputs, username, homeDirectory, userConfig ? {}, ... }: {
  imports = [
    # initial
    ./packages.nix
    ./npm/npm.nix
    ./pipx/pipx.nix
    ./zsh/zsh.nix
    ./config-extras.nix
    ./paths.nix
    ./git/git.nix

    ./atuin/atuin.nix
    ./colima/colima.nix

    ./aerospace/aerospace.nix
    ./k9s/k9s.nix
    ./macchina/macchina.nix
    # ./neovim/neovim.nix
    ./nushell/nushell.nix
    ./starship/starship.nix
    ./vscode/vscode.nix
    ./wezterm/wezterm.nix
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
    
    # Link sysinit-help command
    configFile = {
      "sysinit/sysinit-help.sh" = {
        source = ./sysinit-help.sh;
        executable = true;
      };
    };
  };
  
  # Handle brewing completions through standard home-manager
  programs.zsh.enableCompletion = true;
  programs.zsh.completionInit = ''
    # Add Homebrew completions to fpath
    if [ -d "/opt/homebrew/share/zsh/site-functions" ]; then
      fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
    fi
  '';
  
  # Fix for activation scripts - use mkForce to override any existing implementation
  home.activation.fixVariables = lib.hm.dag.entryBefore ["postInstall"] ''
    # Set variables to avoid unbound variable errors
    export TERM_PROGRAM=""
    export BASH_SILENCE_DEPRECATION_WARNING=1
  '';

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}