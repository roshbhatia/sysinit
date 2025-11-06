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

  # T020: Testing light mode with Gruvbox (Catppuccin latte not yet implemented)
  # Testing auto-derivation: variant should derive to "light" from appearance
  theme = {
    appearance = "light";
    colorscheme = "gruvbox";
    # variant omitted to test appearance-to-variant derivation
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
