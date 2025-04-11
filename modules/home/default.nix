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
    ./neovim/neovim.nix
    ./nushell/nushell.nix
    ./starship/starship.nix
    ./vscode/vscode.nix
    ./wezterm/wezterm.nix
  ];
  programs.home-manager.enable = true;

  home = {
    username = username;
    homeDirectory = homeDirectory;
    
    stateVersion = "23.11";
    sessionVariables = {
      PATH = builtins.concatStringsSep ":" [
        "/opt/homebrew/bin"
        "/opt/homebrew/sbin"
        "$HOME/.cargo/bin"
        "$HOME/go/bin"
        "$HOME/.local/bin"
        "$HOME/.yarn/bin"
        "$HOME/.config/yarn/global/node_modules/.bin"
        "/usr/local/opt/cython/bin"
        "$HOME/.rvm/bin"
        "$HOME/.govm/shim"
        "$HOME/.krew/bin"
        "$HOME/bin"
        "/usr/local/bin"
        "/usr/local/sbin"
        "/bin"
        "/usr/bin"
        "/sbin"
        "/usr/sbin"
        "$PATH"
      ];
    };
  };
  
  # Set XDG directories
  xdg = {
    enable = true;
    configHome = "${homeDirectory}/.config";
    dataHome = "${homeDirectory}/.local/share";
    cacheHome = "${homeDirectory}/.cache";
    
    configFile = {
      "sysinit/sysinit-help.sh" = {
        source = ./sysinit-help.sh;
        executable = true;
      };
    };
  };
  
  home.activation.fixVariables = lib.hm.dag.entryBefore ["postInstall"] ''
    # Set variables to avoid unbound variable errors
    export TERM_PROGRAM=""
    export BASH_SILENCE_DEPRECATION_WARNING=1
  '';
}