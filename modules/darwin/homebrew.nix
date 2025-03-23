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
    
    # Skip declarative tap management for now
    # to avoid GitHub API rate limits
    
    # Keep taps fully mutable
    mutableTaps = true;
  };
}