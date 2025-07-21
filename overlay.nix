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
    ];
  };

  theme = {
    colorscheme = "rose-pine"; # "catppuccin", "rose-pine", "gruvbox", "solarized"
    variant = "moon"; # catppuccin: "macchiato"; rose-pine: "moon"; gruvbox: "dark"; solarized: "dark"
    transparency = {
      enable = true;
      opacity = 0.9;
    };
  };
}
