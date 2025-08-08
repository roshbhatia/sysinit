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

  darwin = {
    tailscale = {
      enable = true;
    };

    borders = {
      enable = false;
    };

    homebrew = {
      additionalPackages = {
        taps = [ "hashicorp/tap" ];
        brews = [
          "blueutil"
          "hashicorp/tap/packer"
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
  };

  yarn = {
    additionalPackages = [
      "@anthropic-ai/claude-code"
      "@dice-roller/cli"
    ];
  };

  theme = {
    colorscheme = "kanagawa";
    variant = "dragon";
    transparency = {
      enable = true;
      opacity = 0.85;
      blur = 80;
    };
  };

  wezterm = {
    shell = "nu";
  };
}

