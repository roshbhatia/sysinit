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
    transparency = {
      enable = true;
      opacity = 0.85;
    };
  };

  # Theme Configuration Options:
  #
  # Available colorschemes:
  # - "catppuccin" (variants: "macchiato")
  # - "rose-pine" (variants: "moon")
  # - "gruvbox" (variants: "dark")
  # - "solarized" (variants: "dark")
  # - "nord" (variants: "dark")
  # - "kanagawa" (variants: "wave", "dragon")
  #
  # Transparency settings:
  # - enable: true/false
  # - opacity: 0.0 to 1.0 (when transparency is enabled)
  #
  # Example configurations:
  # theme = {
  #   colorscheme = "kanagawa";
  #   variant = "dragon";
  #   transparency = {
  #     enable = false;
  #     opacity = 0.90;
  #   };
  # };
  #
  # theme = {
  #   colorscheme = "nord";
  #   variant = "dark";
  #   transparency = {
  #     enable = true;
  #     opacity = 0.80;
  #   };
  # };
}
