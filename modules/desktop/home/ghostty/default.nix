{ config, ... }:

{
  # Ghostty: Minimal terminal emulator for macOS host
  # All multiplexing, scrollback, and search handled by Zellij inside VMs

  stylix.targets.ghostty = {
    enable = true;
  };

  programs.ghostty = {
    enable = true;
    # Minimal config - Ghostty acts as dumb terminal
    # Zellij handles all advanced features (multiplexing, scrollback, search)
    settings = {
      # Use hidden titlebar to preserve native macOS borders and rounded corners
      macos-titlebar-style = "hidden";

      # Transparency settings from sysinit.theme
      background-opacity = config.sysinit.theme.transparency.opacity;
      # Apply opacity to cells with explicit background colors
      background-opacity-cells = true;
      # Enable background blur
      background-blur = true;

      # Window padding (can use comma-separated values for different sides)
      window-padding-x = 8;
      window-padding-y = 8;
      # Auto-balance extra padding
      window-padding-balance = true;
    };
  };
}
