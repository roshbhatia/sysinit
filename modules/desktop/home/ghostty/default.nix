_:

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
    settings = { };
  };
}
