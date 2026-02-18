{
  username = "rshnbhatia";

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  theme = {
    appearance = "dark";
    colorscheme = "everforest";
    variant = "dark-soft";
    font = {
      monospace = "TX-02";
    };
    transparency = {
      opacity = 0.8;
      blur = 70;
    };
  };

  darwin = {
    tailscale.enable = true;
    homebrew.additionalPackages = {
      taps = [ ];
      brews = [ ];
      casks = [ ];
    };
  };
}
