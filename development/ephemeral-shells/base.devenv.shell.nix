# Base devenv.shell.nix template - Automatically used by devenv.init
#
# This provides:
# - Shell detection (ZSH, Nushell, Bash)
# - Automatic alias configuration
# - Script loading from zsh/extras directory
# - Consistent development environment

{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    # Add your project's build inputs and dependencies here
    nativeBuildInputs = with pkgs.buildPackages; [ 
      # Core tools
      macchina
      
      # Development tooling
      nixpkgs-fmt
      jq
      ripgrep
      fd
      fzf
      yazi
      eza
      atuin
    ];
    
    # The shell hook runs when the environment is entered
    shellHook = ''
    '';
}