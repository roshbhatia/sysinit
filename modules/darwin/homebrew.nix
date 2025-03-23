{ pkgs, lib, config, enableHomebrew ? true, username, inputs, ... }:

{
  # Disable the built-in nix-darwin homebrew module
  homebrew.enable = false;
  
  # nix-homebrew is imported via flake inputs in the main darwin.nix module
  
  nix-homebrew = {
    # Only enable if the main config has homebrew enabled
    enable = enableHomebrew;
    
    # Apple Silicon: Also install Homebrew under the default Intel prefix for Rosetta 2
    enableRosetta = true;
    
    # User owning the Homebrew prefix
    user = username;
    
    # Auto-migrate existing Homebrew installations
    autoMigrate = true;
    
    # Declarative tap management
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/bundle" = null;
      "homebrew/cask-fonts" = null;
      "homebrew/services" = null;
      "noahgorstein/tap" = null;
      "nikitabobko/tap" = null;
    };
    
    # Allow mutable taps for maximum flexibility
    mutableTaps = true;
  };
}