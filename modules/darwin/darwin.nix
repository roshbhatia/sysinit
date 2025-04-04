{ pkgs, lib, inputs, ... }: {
  imports = [
    ./system.nix
    ./homebrew.nix
    ./colima.nix
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];
  
  # Make the bashrc-fix.sh file available to the system.nix module
  system.build.bashrcFix = ./bashrc-fix.sh;
}