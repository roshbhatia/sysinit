{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    userName = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    githubUser = "roshbhatia";
    credentialUsername = "roshbhatia";
  };

  homebrew = {
    additionalPackages = {
      taps = [ "hashicorp/tap" ];
      brews = [
        "blueutil"
        "hashicorp/tap/packer"
        "tailscale"
        "qemu"
      ];
      casks = [
        "betterdiscord-installer"
        "calibre"
        "discord"
        "notion"
        "steam"
        "supercollider"
        "vnc-viewer"
      ];
    };
  };

  yarn = {
    additionalPackages = [
      "@anthropic-ai/claude-code"
      "@dice-roller/cli"
    ];
  };

  theme = {
    colorscheme = "catppuccin";
    variant = "macchiato";
    # transparency is optional - defaults to disabled
    # transparency = {
    #   enable = true;
    #   opacity = 0.70;
    # };
  };

  # Optional Wezterm-specific settings
  wezterm = {
    # Optional: override transparency when Neovim is running
    # nvim_transparency_override = {
    #   enable = true;
    #   opacity = 0.85;
    # };
  };
}
