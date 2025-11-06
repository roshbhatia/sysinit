{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  # Theme configuration with appearance-to-variant auto-derivation
  # appearance="dark" + colorscheme="catppuccin" → variant="macchiato"
  theme = {
    appearance = "dark";
    colorscheme = "catppuccin";
    # variant is automatically derived from appearance
  };

  darwin = {
    docker = {
      enable = true;
      backend = "colima";
    };

    podman = {
      desktop = false;
    };

    tailscale = {
      enable = true;
    };

    borders = {
      enable = true;
    };

    homebrew = {
      additionalPackages = {
        taps = [
          "qmk/qmk"
        ];
        brews = [
          "qmk"
        ];
        casks = [
          "betterdiscord-installer"
          "calibre"
          "discord"
          "steam"
        ];
      };
    };
  };

  llm = {
    goose = {
      provider = "openrouter";
      model = "qwen/qwen3-coder:free";
    };
  };
}
