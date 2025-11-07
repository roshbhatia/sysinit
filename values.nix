{
  user = {
    username = "rbha18";
    hostname = "APKR2N5D495296";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  theme = {
    appearance = "dark";
    colorscheme = "catppuccin";
    font = {
      monospace = "TX-02";
      nerdfontFallback = "JetBrainsMono Nerd Font";
    };
  };

  darwin = {
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
          "orbstack"
          "steam"
        ];
      };
    };
  };
}
