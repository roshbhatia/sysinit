{ pkgs, lib, config, enableHomebrew ? true, username, inputs, ... }:

{
  # nix-homebrew configuration to manage the Homebrew installation itself
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
    };
    
    # Keep taps fully mutable
    mutableTaps = true;
  };
}