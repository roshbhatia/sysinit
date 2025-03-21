{ pkgs, lib, ... }: {
  # Personal packages that should only be installed on personal machines
  homebrew.casks = [
    # Personal productivity
    "obsidian"
    "notion"
    
    # Personal utilities
    "tailscale"
    "the-unarchiver"
    "transmission"
    
    # Entertainment
    "soulseek"
  ];
}